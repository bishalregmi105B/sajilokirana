/**
 * Webhooks (Part D.5).
 *
 * SMS Tier-1 inventory webhook:
 *   POST /webhooks/sms        — Sparrow SMS inbound webhook.
 *                               Parses shopkeeper replies: "OUT 14" / "IN 14"
 *                               and updates ShopInventory.inStock accordingly.
 *
 * Payment callbacks (stubs — to be completed once live merchant docs are
 * confirmed; see Section D.5 and master prompt Section 8):
 *   GET  /webhooks/payment/esewa    — eSewa success/failure redirect
 *   POST /webhooks/payment/khalti   — Khalti server-to-server notification
 *   POST /webhooks/payment/fonepay  — Fonepay callback
 *
 * SECURITY: These endpoints must NOT require auth (they're called by external
 * services), but they MUST validate the vendor's HMAC/token signature before
 * trusting the payload. The SMS endpoint uses phone-based identity (the
 * sender phone = the shop's registered phone); the payment endpoints verify
 * against vendor-supplied signatures stored in env.
 */
import crypto from 'crypto';
import { Router } from 'express';
import { z } from 'zod';
import { asyncHandler } from '../utils/asyncHandler';
import { prisma } from '../config/prisma';
import { env } from '../config/env';
import { BadRequestError } from '../utils/errors';

export const webhooksRouter = Router();

// ── SMS Tier-1 inventory webhook ──────────────────────────────────────────

/**
 * Sparrow SMS inbound message format (POST, form-urlencoded or JSON):
 *   mobile   : sender phone (e.g. "+9779801234567")
 *   text     : message body (e.g. "OUT 14" or "IN 14")
 *   datetime : timestamp string (optional)
 *
 * Command grammar (case-insensitive):
 *   OUT <productId>   →  mark product out of stock in this shop's inventory
 *   IN  <productId>   →  mark product back in stock
 *
 * <productId> may be a full UUID or a short catalogue numeric alias seeded in
 * ProductCatalog.name. The handler tries UUID first; if it fails, it falls
 * back to a name-prefix match so shopkeepers can use memorable numbers.
 */
const smsBodySchema = z.object({
  mobile: z.string(),
  text: z.string(),
});

webhooksRouter.post(
  '/sms',
  asyncHandler(async (req, res) => {
    // Accept form-urlencoded or JSON.
    const parsed = smsBodySchema.safeParse(req.body);
    if (!parsed.success) {
      // Silently accept malformed pings (vendor retries on non-200 → avoid loops).
      return res.json({ ok: true });
    }

    const { mobile, text } = parsed.data;
    const normalizedPhone = normalizePhone(mobile);

    // Identify the shop by the sender's phone number.
    const shop = await prisma.shop.findFirst({
      where: { phone: { in: [normalizedPhone, mobile] } },
    });

    if (!shop) {
      // Unknown number — log and ack (don't 404, which could cause retries).
      console.warn(`[sms-webhook] Unknown sender: ${mobile}`);
      return res.json({ ok: true, warning: 'unknown_sender' });
    }

    // Parse command.
    const cmd = parseSmsCommand(text.trim());
    if (!cmd) {
      console.warn(`[sms-webhook] Unrecognised command from ${mobile}: "${text}"`);
      return res.json({ ok: true, warning: 'unrecognised_command' });
    }

    // Resolve productId: try UUID match then name-prefix search.
    const product = await resolveProduct(cmd.ref);
    if (!product) {
      console.warn(`[sms-webhook] Product not found for ref "${cmd.ref}" from ${mobile}`);
      return res.json({ ok: true, warning: 'product_not_found' });
    }

    // Check the shop actually carries this product.
    const entry = await prisma.shopInventory.findUnique({
      where: { shopId_productId: { shopId: shop.id, productId: product.id } },
    });
    if (!entry) {
      console.warn(`[sms-webhook] Shop ${shop.id} does not carry product ${product.id}`);
      return res.json({ ok: true, warning: 'product_not_in_inventory' });
    }

    const inStock = cmd.action === 'IN';
    await prisma.shopInventory.update({
      where: { shopId_productId: { shopId: shop.id, productId: product.id } },
      data: { inStock, lastConfirmedAt: new Date() },
    });

    console.log(
      `[sms-webhook] ${shop.shopName} (${shop.phone}) → ${cmd.action} ${product.name} (inStock=${inStock})`,
    );

    res.json({ ok: true, shop: shop.shopName, product: product.name, inStock });
  }),
);

// ── Payment callbacks (stubs) ─────────────────────────────────────────────

/**
 * eSewa payment success/failure redirect.
 * eSewa redirects the customer browser back to this URL after payment.
 *
 * Live implementation notes (fill in once merchant account is active):
 *   1. Verify the transaction by calling eSewa's status-check API with refId.
 *   2. Match oid → Order.id, confirm amt == Order.totalAmount.
 *   3. Mark Order.paymentStatus = 'paid' and trigger dispatch if not yet started.
 *
 * Docs: https://developer.esewa.com.np/#/epay (verify before implementing)
 */
webhooksRouter.get(
  '/payment/esewa',
  asyncHandler(async (req, res) => {
    const { oid, amt, refId } = req.query as { oid?: string; amt?: string; refId?: string };

    if (!oid || !amt || !refId) {
      throw new BadRequestError('Missing eSewa callback params');
    }

    // TODO(D.5 live): call eSewa status-check API to verify transaction.
    console.log(`[payment/esewa] oid=${oid} amt=${amt} refId=${refId} — stub, not yet verified`);

    // For now redirect to app deep-link (replace with real scheme/host).
    res.redirect(`/order-confirmation?orderId=${encodeURIComponent(oid)}&status=success`);
  }),
);

/**
 * Khalti server-to-server webhook.
 * Khalti POSTs a JSON payload when a payment settles.
 *
 * Live implementation notes:
 *   1. Validate the `X-Khalti-Signature` header using your secret key.
 *   2. Call Khalti's lookup API (/api/v2/payment/verify/) to confirm amount.
 *   3. Match purchase_order_id → Order.id; mark paid + trigger dispatch.
 *
 * Docs: https://docs.khalti.com/#/khalti-epayment (verify before implementing)
 */
const khaltiSchema = z.object({
  event: z.string().optional(),
  purchase_order_id: z.string().optional(),
  total_amount: z.number().optional(),
  transaction_id: z.string().optional(),
});

webhooksRouter.post(
  '/payment/khalti',
  asyncHandler(async (req, res) => {
    // SECURITY: validate signature from Khalti header before trusting body.
    const signature = req.headers['x-khalti-signature'] as string | undefined;
    if (env.payments.khaltiSecretKey && !validateKhaltiSignature(req.body, signature, env.payments.khaltiSecretKey)) {
      throw new BadRequestError('Invalid Khalti signature');
    }

    const payload = khaltiSchema.safeParse(req.body);
    if (!payload.success) {
      return res.status(200).json({ ok: true }); // ack to avoid retries
    }

    const { purchase_order_id, total_amount, transaction_id } = payload.data;
    console.log(`[payment/khalti] orderId=${purchase_order_id} amount=${total_amount} txn=${transaction_id} — stub`);

    // TODO(D.5 live): verify with Khalti API + mark order paid.

    res.json({ ok: true });
  }),
);

/**
 * Fonepay callback.
 * Fonepay GET-redirects or POSTs a callback after payment.
 *
 * Live implementation notes:
 *   1. Compute HMAC-SHA512 over the response params using your merchant password.
 *   2. Compare with the `DV` (data verification) field sent by Fonepay.
 *   3. Match PRN (purchase reference) → Order.id; mark paid + trigger dispatch.
 *
 * Docs: https://developer.fonepay.com (verify before implementing)
 */
const fonepaySchema = z.object({
  PRN: z.string().optional(), // purchase reference (our Order.id)
  BID: z.string().optional(), // bank transaction id
  AMT: z.string().optional(), // amount
  DV: z.string().optional(),  // data verification (HMAC)
  RC: z.string().optional(),  // response code ("successful" | "failed")
});

webhooksRouter.post(
  '/payment/fonepay',
  asyncHandler(async (req, res) => {
    const payload = fonepaySchema.safeParse(req.body);
    if (!payload.success || !payload.data.PRN) {
      return res.status(200).json({ ok: true });
    }

    const { PRN, BID, AMT, RC } = payload.data;

    // TODO(D.5 live): validate DV HMAC, verify amount, mark order paid.
    console.log(`[payment/fonepay] PRN=${PRN} BID=${BID} AMT=${AMT} RC=${RC} — stub`);

    res.json({ ok: true });
  }),
);

// ── helpers ───────────────────────────────────────────────────────────────

/** Normalise +977... or 977... or 98... to a consistent E.164-ish format. */
function normalizePhone(raw: string): string {
  const digits = raw.replace(/\D/g, '');
  if (digits.startsWith('977')) return `+${digits}`;
  if (digits.length === 10 && digits.startsWith('9')) return `+977${digits}`;
  return raw; // return as-is if we can't normalise
}

/** Parse "OUT 14" / "IN 14" / "out abc-uuid" etc. */
function parseSmsCommand(text: string): { action: 'IN' | 'OUT'; ref: string } | null {
  const match = text.match(/^(in|out)\s+(\S+)$/i);
  if (!match) return null;
  return { action: match[1].toUpperCase() as 'IN' | 'OUT', ref: match[2] };
}

/** Try UUID exact match first, then case-insensitive name prefix. */
async function resolveProduct(ref: string): Promise<{ id: string; name: string } | null> {
  const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  if (UUID_RE.test(ref)) {
    return prisma.productCatalog.findUnique({ where: { id: ref }, select: { id: true, name: true } });
  }
  // Name prefix fallback (e.g. shopkeeper sends "OUT rice").
  return prisma.productCatalog.findFirst({
    where: { name: { contains: ref, mode: 'insensitive' } },
    select: { id: true, name: true },
  });
}

/**
 * Validate Khalti HMAC-SHA256 signature.
 * The exact algorithm must be confirmed from Khalti's live developer docs
 * before going to production — this is a placeholder implementation.
 */
function validateKhaltiSignature(body: unknown, signature: string | undefined, secret: string): boolean {
  if (!signature) return false;
  const payload = typeof body === 'string' ? body : JSON.stringify(body);
  const expected = crypto.createHmac('sha256', secret).update(payload).digest('hex');
  // Constant-time comparison to prevent timing attacks.
  try {
    return crypto.timingSafeEqual(Buffer.from(signature, 'hex'), Buffer.from(expected, 'hex'));
  } catch {
    return false;
  }
}
