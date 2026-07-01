/**
 * Admin routes — platform management.
 *   POST  /admin/shops        — onboard a new shop
 *   GET   /admin/shops        — list all shops
 *   PATCH /admin/shops/:id    — update shop details
 *   GET   /admin/dashboard    — platform-wide stats
 */
import { Router } from 'express';
import { z } from 'zod';
import { asyncHandler } from '../utils/asyncHandler';
import { prisma } from '../config/prisma';
import { requireAuth, requireRole } from '../middleware/auth';
import { BadRequestError, NotFoundError } from '../utils/errors';

export const adminRouter = Router();

adminRouter.use(requireAuth, requireRole('admin'));

const onboardShopSchema = z.object({
  ownerName: z.string().min(1),
  shopName: z.string().min(1),
  phone: z.string().regex(/^\+?\d{8,15}$/),
  lat: z.number(),
  lng: z.number(),
  categories: z.array(z.string()).min(1),
  onboardingTier: z.number().int().min(1).max(3).optional().default(2),
});

adminRouter.post(
  '/shops',
  asyncHandler(async (req, res) => {
    const body = onboardShopSchema.parse(req.body);
    const existing = await prisma.shop.findFirst({ where: { phone: body.phone } });
    if (existing) throw new BadRequestError('Shop with this phone already exists');
    const shop = await prisma.shop.create({ data: body });
    res.status(201).json(shop);
  }),
);

adminRouter.get(
  '/shops',
  asyncHandler(async (_req, res) => {
    const shops = await prisma.shop.findMany({
      include: { _count: { select: { wonOrders: true, inventory: true } } },
      orderBy: { createdAt: 'desc' },
    });
    res.json(shops);
  }),
);

const patchShopSchema = z.object({
  shopName: z.string().min(1).optional(),
  status: z.enum(['active', 'paused', 'suspended']).optional(),
  onboardingTier: z.number().int().min(1).max(3).optional(),
  categories: z.array(z.string()).optional(),
});

adminRouter.patch(
  '/shops/:id',
  asyncHandler(async (req, res) => {
    const body = patchShopSchema.parse(req.body);
    const shop = await prisma.shop.findUnique({ where: { id: req.params.id as string } });
    if (!shop) throw new NotFoundError('Shop not found');
    const updated = await prisma.shop.update({ where: { id: shop.id }, data: body });
    res.json(updated);
  }),
);

adminRouter.get(
  '/dashboard',
  asyncHandler(async (_req, res) => {
    const now = new Date();
    const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const weekStart = new Date(todayStart.getTime() - 7 * 24 * 60 * 60 * 1000);
    const [totalOrders, todayOrders, weekOrders, totalShops, activeShops, totalDrivers, availableDrivers, totalUsers, totalRevenue] = await Promise.all([
      prisma.order.count(),
      prisma.order.count({ where: { createdAt: { gte: todayStart } } }),
      prisma.order.count({ where: { createdAt: { gte: weekStart } } }),
      prisma.shop.count(),
      prisma.shop.count({ where: { status: 'active' } }),
      prisma.driver.count(),
      prisma.driver.count({ where: { status: 'available' } }),
      prisma.user.count(),
      prisma.order.aggregate({ _sum: { totalAmount: true }, where: { status: 'delivered' } }),
    ]);
    res.json({
      orders: { total: totalOrders, today: todayOrders, thisWeek: weekOrders },
      shops: { total: totalShops, active: activeShops },
      drivers: { total: totalDrivers, available: availableDrivers },
      users: { total: totalUsers },
      revenue: { total: totalRevenue._sum.totalAmount ?? 0 },
    });
  }),
);
