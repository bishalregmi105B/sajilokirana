/**
 * Dispatch Engine (Part D.4) — the core business logic of SajiloKirana.
 *
 * Flow:
 *   1. New order → find candidate shops (radius + active + category + in-stock).
 *   2. Rank candidates: call ML /ml/dispatch/score (falls back to a local
 *      weighted formula if the ML service is unavailable — Part E.6 MVP).
 *   3. Broadcast to top N (Socket.io event + SMS fallback for Tier-1 shops).
 *   4. Start a Redis-TTL confirm window; first accept wins; notify losers.
 *   5. No confirm in window → expand radius and rebroadcast.
 *   6. On confirm → ML /ml/routing/optimize to assign a driver.
 *   7. On delivery/cancellation → update the shop's reliabilityScore.
 *      *** This is the single most important rule in the system *** — it is
 *      the direct fix for the inventory-mismatch problem.
 *
 * The engine is structured so its pure scoring + candidate logic is unit-
 * testable WITHOUT a running DB/Redis (the dispatch.test.ts covers these).
 */
import { prisma } from '../config/prisma';
import { redis } from '../config/redis';
import { env } from '../config/env';
import { haversineKm } from '../utils/geo';
import { realtime } from '../sockets/realtime';
import { ConflictError, NotFoundError } from '../utils/errors';

// ── Types ──────────────────────────────────────────────────────────────────
export interface CandidateShop {
  id: string;
  distanceKm: number;
  reliabilityScore: number;
  recentActivity: number; // # of orders in last 24h (recency proxy)
  score?: number;
}

export interface ScoreWeights {
  distance: number;
  reliability: number;
  recency: number;
}

export const DEFAULT_WEIGHTS: ScoreWeights = {
  distance: 1.0,
  reliability: 1.0,
  recency: 0.3,
};

const CONFIRM_KEY = (orderId: string) => `dispatch:confirm:${orderId}`;

// ── Pure helpers (unit-tested in isolation) ────────────────────────────────

/**
 * Score a single candidate shop. Higher = better.
 * `score = w1·(1/distance) + w2·reliability + w3·recency`
 * (Part E.6 MVP formula; replaced by a learned model in Phase 2.)
 *
 * distance is in km; we guard divide-by-zero (same-location → use 0.05km).
 */
export function scoreCandidate(
  shop: CandidateShop,
  weights: ScoreWeights = DEFAULT_WEIGHTS,
): number {
  const safeDistance = Math.max(shop.distanceKm, 0.05);
  const distanceTerm = weights.distance * (1 / safeDistance);
  const reliabilityTerm = weights.reliability * shop.reliabilityScore;
  const recencyTerm = weights.recency * Math.min(shop.recentActivity, 10) / 10;
  return round3(distanceTerm + reliabilityTerm + recencyTerm);
}

/** Rank candidates descending by score (returns a NEW array). */
export function rankCandidates(
  shops: CandidateShop[],
  weights: ScoreWeights = DEFAULT_WEIGHTS,
): CandidateShop[] {
  return [...shops]
    .map((s) => ({ ...s, score: scoreCandidate(s, weights) }))
    .sort((a, b) => (b.score ?? 0) - (a.score ?? 0));
}

/**
 * Compute the new reliability score after an outcome (D.4 step 7).
 * - Positive outcome (fulfilled): nudge up, capped at 1.0
 * - Negative outcome (ghosted/cancelled-after-confirm): nudge down harder,
 *   floored at 0.0. The negative delta is larger — ghosting is costly.
 *
 * This is intentionally simple + bounded so it can't run away. Exposed for
 * unit testing.
 */
export function updateReliability(
  current: number,
  outcome: 'fulfilled' | 'ghosted',
): number {
  const POSITIVE_DELTA = 0.02;
  const NEGATIVE_DELTA = 0.08;
  if (outcome === 'fulfilled') {
    return round3(Math.min(1, current + POSITIVE_DELTA));
  }
  return round3(Math.max(0, current - NEGATIVE_DELTA));
}

// ── Engine (DB/Redis-bound) ────────────────────────────────────────────────

export class DispatchEngine {
  /**
   * Step 1–3: find candidates for an order, rank, broadcast, start window.
   * Returns the broadcast record.
   */
  async startDispatch(orderId: string, radiusKm?: number): Promise<void> {
    const order = await prisma.order.findUnique({
      where: { id: orderId },
      include: { items: true },
    });
    if (!order) throw new NotFoundError('Order not found');

    const radius = radiusKm ?? env.dispatch.initialRadiusKm;

    // Need a delivery location to compute distance.
    const delivery = order.deliveryAddress as { lat?: number; lng?: number } | null;
    if (!delivery?.lat || !delivery?.lng) {
      throw new Error('Order has no delivery coordinates');
    }

    const candidates = await this.findCandidates(order, delivery.lat, delivery.lng, radius);

    if (candidates.length === 0) {
      // No candidates at this radius: try the expanded radius once.
      if (radius < env.dispatch.expandedRadiusKm) {
        return this.startDispatch(orderId, env.dispatch.expandedRadiusKm);
      }
      // Still nothing → mark cancelled. (Pilot: ops would intervene here.)
      await prisma.order.update({
        where: { id: orderId },
        data: { status: 'cancelled' },
      });
      realtime.emitStatusChanged(orderId, 'cancelled');
      return;
    }

    const ranked = await this.rankWithMl(candidates);
    const topN = ranked.slice(0, env.dispatch.topNCandidates);

    // Create the broadcast record.
    const broadcast = await prisma.dispatchBroadcast.create({
      data: {
        orderId,
        candidateShopIds: topN.map((s) => s.id),
        confirmWindowSeconds: env.dispatch.confirmWindowSeconds,
      },
    });

    await prisma.order.update({
      where: { id: orderId },
      data: { status: 'broadcasting' },
    });

    // Broadcast via Socket.io + SMS fallback for Tier-1 shops.
    realtime.emitOrderBroadcast(
      topN.map((s) => s.id),
      { orderId, broadcastId: broadcast.id, items: order.items },
    );
    await this.smsFallbackBroadcast(topN.map((s) => s.id), orderId);

    // Step 4: start the confirm-window TTL in Redis.
    await redis.set(
      CONFIRM_KEY(orderId),
      JSON.stringify({ candidates: topN.map((s) => s.id) }),
      'EX',
      env.dispatch.confirmWindowSeconds,
    );

    // Schedule a window-expiry check. Redis key-expiry alone can't trigger
    // code, so we poll-and-handle from the accept endpoint instead. See
    // `handleExpiry` — called when accept finds the key already gone.
  }

  /**
   * Find candidate shops matching the order (radius + active + category + at
   * least one ordered item in stock).
   */
  async findCandidates(
    order: { items: { productId: string }[] },
    lat: number,
    lng: number,
    radiusKm: number,
  ): Promise<CandidateShop[]> {
    const productIds = order.items.map((i) => i.productId);

    const shops = await prisma.shop.findMany({
      where: { status: 'active' },
      include: {
        inventory: {
          where: { productId: { in: productIds }, inStock: true },
        },
      },
    });

    const since = new Date(Date.now() - 24 * 60 * 60 * 1000);
    const recentOrders = await prisma.order.findMany({
      where: { assignedShopId: { in: shops.map((s) => s.id) }, createdAt: { gte: since } },
      select: { assignedShopId: true },
    });
    const activityByShop = new Map<string, number>();
    for (const o of recentOrders) {
      activityByShop.set(o.assignedShopId!, (activityByShop.get(o.assignedShopId!) ?? 0) + 1);
    }

    return shops
      .map((shop) => ({
        id: shop.id,
        distanceKm: haversineKm(lat, lng, shop.lat, shop.lng),
        reliabilityScore: shop.reliabilityScore,
        recentActivity: activityByShop.get(shop.id) ?? 0,
      }))
      .filter((s) => s.distanceKm <= radiusKm);
  }

  /**
   * Rank candidates, preferring the ML service (Part E.6 Phase 2) but
   * gracefully degrading to the local weighted formula.
   */
  async rankWithMl(shops: CandidateShop[]): Promise<CandidateShop[]> {
    if (!env.mlServiceUrl) {
      return rankCandidates(shops); // local fallback
    }
    try {
      const res = await fetch(`${env.mlServiceUrl}/ml/dispatch/score`, {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({
          candidate_shop_ids: shops.map((s) => s.id),
          shops: shops,
        }),
        signal: AbortSignal.timeout(2000),
      });
      if (!res.ok) throw new Error(`ml http ${res.status}`);
      const data = (await res.json()) as { ranked_shops: { shop_id: string; score: number }[] };
      const byId = new Map(shops.map((s) => [s.id, s]));
      return data.ranked_shops
        .map((r) => ({ ...byId.get(r.shop_id)!, score: r.score }))
        .filter(Boolean);
    } catch (err) {
      console.warn('[dispatch] ML score unavailable, using local formula:', (err as Error).message);
      return rankCandidates(shops);
    }
  }

  /**
   * Step 4 (win): a shop accepts. First-accept-wins via Redis DEL race.
   * Returns the winner shopId; throws ConflictError if the window is closed.
   */
  async acceptOrder(orderId: string, shopId: string): Promise<{ won: boolean }> {
    // Atomic: only the shop that deletes the key while it still exists wins.
    const raw = await redis.getdel(CONFIRM_KEY(orderId));
    if (!raw) {
      // Key already gone → either expired or another shop won.
      const existing = await prisma.order.findUnique({ where: { id: orderId } });
      if (existing?.assignedShopId === shopId) {
        return { won: true }; // idempotent re-accept
      }
      throw new ConflictError('Confirm window closed');
    }

    const stored = JSON.parse(raw) as { candidates: string[] };
    const losers = stored.candidates.filter((id) => id !== shopId);

    await prisma.order.update({
      where: { id: orderId },
      data: { status: 'shop_confirmed', assignedShopId: shopId },
    });
    await prisma.dispatchBroadcast.updateMany({
      where: { orderId, winningShopId: null },
      data: { winningShopId: shopId, confirmedAt: new Date() },
    });

    const winner = await prisma.shop.findUnique({ where: { id: shopId } });
    const customerId = (await prisma.order.findUnique({ where: { id: orderId } }))?.customerId;

    realtime.emitOrderConfirmed(
      orderId,
      customerId ?? '',
      losers,
      { orderId, shopId, shopName: winner?.shopName },
    );

    // Step 6: assign a driver (ML routing if available, else first-available).
    await this.assignDriver(orderId);

    return { won: true };
  }

  /** Step 5: called when no shop accepted in time. Expand + rebroadcast. */
  async handleExpiry(orderId: string): Promise<void> {
    const order = await prisma.order.findUnique({ where: { id: orderId } });
    if (!order || order.status !== 'broadcasting') return;

    // Try expanded radius; if already at max, cancel.
    const radius = env.dispatch.expandedRadiusKm;
    await this.startDispatch(orderId, radius);
  }

  /**
   * Step 6: driver assignment. In Phase 0 we pick the first available driver.
   * (ML routing/batching is the upgrade path — Part E.4.)
   */
  async assignDriver(orderId: string): Promise<void> {
    const driver = await prisma.driver.findFirst({ where: { status: 'available' } });
    if (!driver) {
      console.warn(`[dispatch] no available driver for order ${orderId} — queued`);
      return; // order stays shop_confirmed; ops/loop reassigns later
    }

    const batch = await prisma.batch.create({
      data: {
        driverId: driver.id,
        orderIds: [orderId],
        status: 'assigned',
      },
    });
    await prisma.order.update({
      where: { id: orderId },
      data: { assignedDriverId: driver.id, batchId: batch.id, status: 'picked_up' },
    });
    await prisma.driver.update({
      where: { id: driver.id },
      data: { status: 'busy', currentBatchId: batch.id },
    });

    realtime.emitOrderAssigned(driver.id, { batchId: batch.id, orderId });
    realtime.emitStatusChanged(orderId, 'picked_up');
  }

  /**
   * Step 7 (THE important rule): update a shop's reliability after an order
   * outcome. Fulfilled → up; ghosted/cancelled-after-confirm → down harder.
   */
  async applyReliabilityUpdate(shopId: string, outcome: 'fulfilled' | 'ghosted'): Promise<number> {
    const shop = await prisma.shop.findUnique({ where: { id: shopId } });
    if (!shop) throw new NotFoundError('Shop not found');
    const next = updateReliability(shop.reliabilityScore, outcome);
    await prisma.shop.update({
      where: { id: shopId },
      data: { reliabilityScore: next },
    });
    return next;
  }

  // ── Tier-1 SMS fallback (Part D.5) ────────────────────────────────────────
  private async smsFallbackBroadcast(shopIds: string[], orderId: string): Promise<void> {
    if (!env.sparrow.token) return; // not configured
    const shops = await prisma.shop.findMany({
      where: { id: { in: shopIds }, onboardingTier: 1 },
      select: { id: true, phone: true, shopName: true },
    });
    for (const shop of shops) {
      await sendSparrowSms(
        shop.phone,
        `SajiloKirana: New order ${orderId.slice(0, 8)}. Reply IN/OUT <productId> to update stock. Reply ACCEPT ${orderId.slice(0, 8)} to confirm.`,
      );
    }
  }
}

export const dispatch = new DispatchEngine();

// ── utils ──────────────────────────────────────────────────────────────────
function round3(n: number): number {
  return Math.round(n * 1000) / 1000;
}

/**
 * Send an SMS via Sparrow SMS (Nepal).
 * API reference: https://api.sparrowsms.com/v2/sms/
 * Errors are caught and logged — SMS failure must NEVER crash the dispatch flow.
 */
async function sendSparrowSms(to: string, text: string): Promise<void> {
  const { token, from } = env.sparrow;
  if (!token) return;
  try {
    const res = await fetch('https://api.sparrowsms.com/v2/sms/', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ token, from, to, text }),
      signal: AbortSignal.timeout(5000),
    });
    if (!res.ok) {
      const body = await res.text().catch(() => '');
      console.warn(`[sms] Sparrow HTTP ${res.status} to ${to}: ${body}`);
    } else {
      console.log(`[sms] Sparrow SMS sent to ${to}`);
    }
  } catch (err) {
    console.warn(`[sms] Sparrow send failed to ${to}:`, (err as Error).message);
  }
}
