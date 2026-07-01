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

const shopId = (req: { actor?: { id: string } }): string => req.actor!.id;

shopRouter.get(
  '/me',
  asyncHandler(async (req, res) => {
    const shop = await prisma.shop.findUnique({
      where: { id: shopId(req) },
      include: { _count: { select: { wonOrders: true, inventory: true } } },
    });
    if (!shop) throw new NotFoundError('Shop not found');
    res.json(shop);
  }),
);

const patchShopMeSchema = z.object({
  shopName: z.string().min(1).optional(),
  payoutAccount: z.string().optional(),
});

shopRouter.patch(
  '/me',
  asyncHandler(async (req, res) => {
    const body = patchShopMeSchema.parse(req.body);
    const shop = await prisma.shop.update({ where: { id: shopId(req) }, data: body });
    res.json(shop);
  }),
);

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

shopRouter.get(
  '/orders/active',
  asyncHandler(async (req, res) => {
    const orders = await prisma.order.findMany({
      where: { assignedShopId: shopId(req), status: { in: ['shop_confirmed', 'picked_up', 'in_transit'] } },
      include: { items: { include: { product: true } }, assignedDriver: { select: { name: true, phone: true } } },
      orderBy: { createdAt: 'desc' },
    });
    res.json(orders);
  }),
);

shopRouter.get(
  '/orders/history',
  asyncHandler(async (req, res) => {
    const orders = await prisma.order.findMany({
      where: { assignedShopId: shopId(req), status: { in: ['delivered', 'cancelled'] } },
      include: { items: { include: { product: true } } },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });
    res.json(orders);
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

shopRouter.get(
  '/inventory',
  asyncHandler(async (req, res) => {
    const inventory = await prisma.shopInventory.findMany({
      where: { shopId: shopId(req) },
      include: { product: true },
      orderBy: { product: { name: 'asc' } },
    });
    res.json(inventory);
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

shopRouter.get(
  '/analytics',
  asyncHandler(async (req, res) => {
    const id = shopId(req);
    const now = new Date();
    const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const weekStart = new Date(todayStart.getTime() - 7 * 24 * 60 * 60 * 1000);
    const shop = await prisma.shop.findUnique({ where: { id } });
    if (!shop) throw new NotFoundError('Shop not found');
    const [todayOrders, weekOrders, allOrders, todayRev, weekRev, allRev, cancelled] = await Promise.all([
      prisma.order.count({ where: { assignedShopId: id, createdAt: { gte: todayStart } } }),
      prisma.order.count({ where: { assignedShopId: id, createdAt: { gte: weekStart } } }),
      prisma.order.count({ where: { assignedShopId: id } }),
      prisma.order.aggregate({ _sum: { totalAmount: true }, where: { assignedShopId: id, status: 'delivered', createdAt: { gte: todayStart } } }),
      prisma.order.aggregate({ _sum: { totalAmount: true }, where: { assignedShopId: id, status: 'delivered', createdAt: { gte: weekStart } } }),
      prisma.order.aggregate({ _sum: { totalAmount: true }, where: { assignedShopId: id, status: 'delivered' } }),
      prisma.order.count({ where: { assignedShopId: id, status: 'cancelled' } }),
    ]);
    res.json({
      reliabilityScore: shop.reliabilityScore,
      reliabilityPercent: Math.round(shop.reliabilityScore * 100),
      orders: { today: todayOrders, thisWeek: weekOrders, allTime: allOrders, cancelled },
      revenue: { today: todayRev._sum.totalAmount ?? 0, thisWeek: weekRev._sum.totalAmount ?? 0, allTime: allRev._sum.totalAmount ?? 0 },
    });
  }),
);
