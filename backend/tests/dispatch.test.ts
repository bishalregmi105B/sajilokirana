/**
 * Dispatch engine unit tests (Part D.4).
 *
 * Only the PURE, DB/Redis-free helpers are tested here:
 *   - scoreCandidate
 *   - rankCandidates
 *   - updateReliability
 *
 * These are the functions called by the engine; testing them in isolation
 * catches the scoring math bugs that would directly cause the ghosting/
 * inventory-mismatch problem the system exists to solve.
 *
 * The haversineKm utility is tested in geo.test.ts (see below).
 */

import {
  scoreCandidate,
  rankCandidates,
  updateReliability,
  DEFAULT_WEIGHTS,
  type CandidateShop,
  type ScoreWeights,
} from '../src/services/dispatch';
import { haversineKm } from '../src/utils/geo';

// ── Fixtures ─────────────────────────────────────────────────────────────

function makeShop(overrides: Partial<CandidateShop> = {}): CandidateShop {
  return {
    id: 'shop-a',
    distanceKm: 1.0,
    reliabilityScore: 0.5,
    recentActivity: 5,
    ...overrides,
  };
}

// ── scoreCandidate ─────────────────────────────────────────────────────────

describe('scoreCandidate', () => {
  it('returns a positive score for a typical shop', () => {
    const shop = makeShop({ distanceKm: 1.0, reliabilityScore: 0.8, recentActivity: 4 });
    expect(scoreCandidate(shop)).toBeGreaterThan(0);
  });

  it('nearby shops score higher than far shops (same reliability)', () => {
    const near = makeShop({ distanceKm: 0.5, reliabilityScore: 0.5, recentActivity: 3 });
    const far = makeShop({ distanceKm: 3.0, reliabilityScore: 0.5, recentActivity: 3 });
    expect(scoreCandidate(near)).toBeGreaterThan(scoreCandidate(far));
  });

  it('more reliable shops score higher than less reliable shops (same distance)', () => {
    const reliable = makeShop({ distanceKm: 1.0, reliabilityScore: 0.9, recentActivity: 3 });
    const unreliable = makeShop({ distanceKm: 1.0, reliabilityScore: 0.1, recentActivity: 3 });
    expect(scoreCandidate(reliable)).toBeGreaterThan(scoreCandidate(unreliable));
  });

  it('guards divide-by-zero: zero distance uses 0.05 km floor', () => {
    const zeroDistance = makeShop({ distanceKm: 0, reliabilityScore: 0.5, recentActivity: 0 });
    const tinyDistance = makeShop({ distanceKm: 0.05, reliabilityScore: 0.5, recentActivity: 0 });
    expect(scoreCandidate(zeroDistance)).toBeCloseTo(scoreCandidate(tinyDistance), 3);
  });

  it('recency is capped: activity=20 scores same as activity=10', () => {
    const high = makeShop({ distanceKm: 1.0, reliabilityScore: 0.5, recentActivity: 20 });
    const capped = makeShop({ distanceKm: 1.0, reliabilityScore: 0.5, recentActivity: 10 });
    expect(scoreCandidate(high)).toBeCloseTo(scoreCandidate(capped), 5);
  });

  it('respects custom weight overrides', () => {
    const shop = makeShop({ distanceKm: 1.0, reliabilityScore: 0.5, recentActivity: 5 });
    const zeroWeights: ScoreWeights = { distance: 0, reliability: 0, recency: 0 };
    expect(scoreCandidate(shop, zeroWeights)).toBe(0);
  });

  it('rounds result to 3 decimal places', () => {
    const shop = makeShop({ distanceKm: 1.3, reliabilityScore: 0.7, recentActivity: 7 });
    const result = scoreCandidate(shop);
    const decimals = result.toString().split('.')[1]?.length ?? 0;
    expect(decimals).toBeLessThanOrEqual(3);
  });
});

// ── rankCandidates ─────────────────────────────────────────────────────────

describe('rankCandidates', () => {
  it('returns a new array (does not mutate input)', () => {
    const shops = [
      makeShop({ id: 'a', distanceKm: 2 }),
      makeShop({ id: 'b', distanceKm: 1 }),
    ];
    const original = [...shops];
    rankCandidates(shops);
    expect(shops).toEqual(original);
  });

  it('places nearer, more reliable shop first', () => {
    const best = makeShop({ id: 'best', distanceKm: 0.5, reliabilityScore: 0.9, recentActivity: 8 });
    const worst = makeShop({ id: 'worst', distanceKm: 2.5, reliabilityScore: 0.2, recentActivity: 1 });
    const ranked = rankCandidates([worst, best]);
    expect(ranked[0].id).toBe('best');
  });

  it('ranks three shops in descending score order', () => {
    const shops: CandidateShop[] = [
      { id: 'far-unreliable', distanceKm: 4, reliabilityScore: 0.1, recentActivity: 0 },
      { id: 'near-reliable', distanceKm: 0.3, reliabilityScore: 0.95, recentActivity: 10 },
      { id: 'mid', distanceKm: 1.5, reliabilityScore: 0.6, recentActivity: 5 },
    ];
    const ranked = rankCandidates(shops);
    expect(ranked[0].id).toBe('near-reliable');
    expect(ranked[2].id).toBe('far-unreliable');
  });

  it('attaches score property to each returned shop', () => {
    const shops = [makeShop({ id: 'x' })];
    const ranked = rankCandidates(shops);
    expect(ranked[0].score).toBeDefined();
    expect(typeof ranked[0].score).toBe('number');
  });

  it('handles empty array', () => {
    expect(rankCandidates([])).toEqual([]);
  });

  it('handles single-shop array', () => {
    const shop = makeShop({ id: 'only' });
    const ranked = rankCandidates([shop]);
    expect(ranked).toHaveLength(1);
    expect(ranked[0].id).toBe('only');
  });
});

// ── updateReliability ──────────────────────────────────────────────────────

describe('updateReliability', () => {
  it('nudges score UP on fulfilled outcome', () => {
    const next = updateReliability(0.5, 'fulfilled');
    expect(next).toBeGreaterThan(0.5);
  });

  it('nudges score DOWN on ghosted outcome', () => {
    const next = updateReliability(0.5, 'ghosted');
    expect(next).toBeLessThan(0.5);
  });

  it('ghosted penalty is larger than fulfilled reward', () => {
    const base = 0.5;
    const gain = updateReliability(base, 'fulfilled') - base;
    const loss = base - updateReliability(base, 'ghosted');
    expect(loss).toBeGreaterThan(gain);
  });

  it('caps fulfilled at 1.0 (cannot exceed maximum)', () => {
    expect(updateReliability(1.0, 'fulfilled')).toBe(1.0);
    expect(updateReliability(0.99, 'fulfilled')).toBeLessThanOrEqual(1.0);
  });

  it('floors ghosted at 0.0 (cannot go negative)', () => {
    expect(updateReliability(0.0, 'ghosted')).toBe(0.0);
    expect(updateReliability(0.01, 'ghosted')).toBeGreaterThanOrEqual(0.0);
  });

  it('result is rounded to 3 decimal places', () => {
    const result = updateReliability(0.333, 'fulfilled');
    const decimals = result.toString().split('.')[1]?.length ?? 0;
    expect(decimals).toBeLessThanOrEqual(3);
  });

  it('repeated fulfilled calls eventually reach 1.0', () => {
    let score = 0.5;
    for (let i = 0; i < 100; i++) {
      score = updateReliability(score, 'fulfilled');
    }
    expect(score).toBe(1.0);
  });

  it('repeated ghosted calls eventually reach 0.0', () => {
    let score = 0.5;
    for (let i = 0; i < 100; i++) {
      score = updateReliability(score, 'ghosted');
    }
    expect(score).toBe(0.0);
  });
});

// ── haversineKm ────────────────────────────────────────────────────────────

describe('haversineKm', () => {
  it('returns 0 for same-point coords', () => {
    expect(haversineKm(27.7, 85.3, 27.7, 85.3)).toBeCloseTo(0, 3);
  });

  it('Kathmandu ↔ Patan (~5 km straight line)', () => {
    // Kathmandu Durbar Square ≈ 27.7042, 85.3077
    // Patan Durbar Square   ≈ 27.6736, 85.3232
    const dist = haversineKm(27.7042, 85.3077, 27.6736, 85.3232);
    expect(dist).toBeGreaterThan(3);
    expect(dist).toBeLessThan(6);
  });

  it('is symmetric (A→B == B→A)', () => {
    const ab = haversineKm(27.7, 85.3, 27.72, 85.32);
    const ba = haversineKm(27.72, 85.32, 27.7, 85.3);
    expect(ab).toBeCloseTo(ba, 6);
  });

  it('increases as coordinates diverge', () => {
    const short = haversineKm(27.7, 85.3, 27.71, 85.31);
    const long = haversineKm(27.7, 85.3, 27.8, 85.4);
    expect(long).toBeGreaterThan(short);
  });
});

// ── Integration: ranking under dispatch conditions ─────────────────────────

describe('dispatch scoring integration', () => {
  it('top-3 slice of ranked shops excludes the worst candidate', () => {
    const shops: CandidateShop[] = [
      { id: 'A', distanceKm: 0.4, reliabilityScore: 0.9, recentActivity: 8 },
      { id: 'B', distanceKm: 0.8, reliabilityScore: 0.7, recentActivity: 5 },
      { id: 'C', distanceKm: 1.5, reliabilityScore: 0.6, recentActivity: 3 },
      { id: 'D', distanceKm: 4.0, reliabilityScore: 0.1, recentActivity: 0 },
    ];
    const topN = rankCandidates(shops).slice(0, 3);
    const ids = topN.map((s) => s.id);
    expect(ids).toContain('A');
    expect(ids).not.toContain('D');
  });

  it('a newly-ghosted shop (score drop) falls below a fresh reliable shop', () => {
    const ghostedScore = 0.5 - 0.08; // after one ghost
    const freshScore = 0.5;
    const ghosted: CandidateShop = {
      id: 'ghost',
      distanceKm: 0.6,
      reliabilityScore: ghostedScore,
      recentActivity: 4,
    };
    const fresh: CandidateShop = {
      id: 'fresh',
      distanceKm: 0.7,
      reliabilityScore: freshScore,
      recentActivity: 4,
    };
    const ranked = rankCandidates([ghosted, fresh]);
    expect(ranked[0].id).toBe('fresh');
  });
});
