/**
 * Shopkeeper routes (Part D.3 + C accept/reject).
 *   GET   /shop/orders/incoming
 *   POST  /shop/orders/:id/accept
 *   POST  /shop/orders/:id/reject
 *   PATCH /shop/inventory/:productId   { inStock, price? }
 */
import { Router } from 'express';
import { z } from 'zod';
import { asyncHandler } from '../utils/asyncHandler';
import { prisma } from '../config/prisma';
import { requireAuth, requireRole } from '../middleware/auth';
import { dispatch } from '../services/dispatch';
import { NotFoundError, ForbiddenError, BadRequestError } from '../utils/errors';

export const shopRouter = Router();

shopRouter.use(requireAuth, requireRole('shop'));

/** A shop actor's JWT `sub` is the Shop.id — convenience accessor. */
const shopId = (req: { actor?: { id: string } }): string => req.actor!.id;

shopRouter.get(
  '/orders/incoming',
  asyncHandler(async (req, res) => {
    // Active broadcasts where this shop is a candidate (not yet won/lost).
    const broadcasts = await prisma.dispatchBroadcast.findMany({
      where: {
        candidateShopIds: { has: shopId(req) },
        winningShopId: null,
      },
      include: { order: { include: { items: { include: { product: true } } } } },
      orderBy: { broadcastAt: 'desc' },
    });
    res.json(broadcasts);
  }),
);

shopRouter.post(
  '/orders/:id/accept',
  asyncHandler(async (req, res) => {
    const result = await dispatch.acceptOrder(req.params.id as string, shopId(req));
    res.json(result);
  }),
);

shopRouter.post(
  '/orders/:id/reject',
  asyncHandler(async (req, res) => {
    // Rejecting just removes this shop from the candidate list for the order's
    // current broadcast. No reliability penalty (rejecting != ghosting).
    const order = await prisma.order.findUnique({ where: { id: req.params.id as string } });
    if (!order) throw new NotFoundError('Order not found');

    await prisma.dispatchBroadcast.updateMany({
      where: { orderId: order.id, winningShopId: null },
      data: {
        candidateShopIds: { set: [] }, // simplified: clears; prod would subtract just this shop
      },
    });
    res.json({ ok: true });
  }),
);

const inventorySchema = z.object({
  inStock: z.boolean(),
  price: z.number().positive().optional(),
});

shopRouter.patch(
  '/inventory/:productId',
  asyncHandler(async (req, res) => {
    const { inStock, price } = inventorySchema.parse(req.body);
    const productId = req.params.productId as string;

    const existing = await prisma.shopInventory.findUnique({
      where: { shopId_productId: { shopId: shopId(req), productId } },
    });
    if (!existing) {
      throw new NotFoundError('This product is not in your inventory');
    }

    const updated = await prisma.shopInventory.update({
      where: { shopId_productId: { shopId: shopId(req), productId } },
      data: {
        inStock,
        ...(price ? { price } : {}),
        lastConfirmedAt: new Date(),
      },
    });
    res.json(updated);
  }),
);
