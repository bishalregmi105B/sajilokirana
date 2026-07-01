/**
 * Driver routes (Part D.3).
 *   GET  /driver/batches/current      — driver's active batch
 *   POST /driver/orders/:id/pickup    — mark picked up
 *   POST /driver/orders/:id/deliver   — mark delivered
 *   POST /driver/location             — background location ping
 */
import { Router } from 'express';
import { z } from 'zod';
import { asyncHandler } from '../utils/asyncHandler';
import { prisma } from '../config/prisma';
import { requireAuth, requireRole } from '../middleware/auth';
import { dispatch } from '../services/dispatch';
import { realtime } from '../sockets/realtime';
import { NotFoundError } from '../utils/errors';
import { OrderStatus, DriverStatus } from '../utils/geo';

export const driverRouter = Router();

driverRouter.use(requireAuth, requireRole('driver'));

const driverId = (req: { actor?: { id: string } }): string => req.actor!.id;

driverRouter.get(
  '/me',
  asyncHandler(async (req, res) => {
    const driver = await prisma.driver.findUnique({ where: { id: driverId(req) } });
    if (!driver) throw new NotFoundError('Driver not found');
    res.json(driver);
  }),
);

const statusToggleSchema = z.object({
  status: z.enum([DriverStatus.AVAILABLE, DriverStatus.OFFLINE]),
});

driverRouter.patch(
  '/status',
  asyncHandler(async (req, res) => {
    const { status } = statusToggleSchema.parse(req.body);
    const driver = await prisma.driver.update({ where: { id: driverId(req) }, data: { status } });
    res.json(driver);
  }),
);

driverRouter.get(
  '/batches/current',
  asyncHandler(async (req, res) => {
    const batch = await prisma.batch.findFirst({
      where: { driverId: driverId(req), status: { in: ['assigned', 'in_progress'] } },
      include: {
        orders: {
          include: {
            items: { include: { product: true } },
            assignedShop: { select: { shopName: true, lat: true, lng: true, phone: true } },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
    res.json(batch);
  }),
);

driverRouter.post(
  '/orders/:id/pickup',
  asyncHandler(async (req, res) => {
    const order = await prisma.order.findUnique({ where: { id: req.params.id as string } });
    if (!order) throw new NotFoundError('Order not found');
    if (order.assignedDriverId !== driverId(req)) {
      throw new NotFoundError('Order not assigned to you');
    }

    const updated = await prisma.order.update({
      where: { id: order.id },
      data: { status: OrderStatus.PICKED_UP },
    });
    realtime.emitStatusChanged(order.id, OrderStatus.PICKED_UP);
    res.json(updated);
  }),
);

driverRouter.post(
  '/orders/:id/deliver',
  asyncHandler(async (req, res) => {
    const order = await prisma.order.findUnique({ where: { id: req.params.id as string } });
    if (!order) throw new NotFoundError('Order not found');
    if (order.assignedDriverId !== driverId(req)) {
      throw new NotFoundError('Order not assigned to you');
    }

    const updated = await prisma.order.update({
      where: { id: order.id },
      data: { status: OrderStatus.DELIVERED },
    });

    // Free the driver + complete the batch.
    await prisma.driver.update({
      where: { id: driverId(req) },
      data: { status: DriverStatus.AVAILABLE, currentBatchId: null },
    });
    if (order.batchId) {
      await prisma.batch.update({
        where: { id: order.batchId },
        data: { status: 'completed' },
      });
    }

    // Reliability reward for the shop (D.4 step 7).
    if (order.assignedShopId) {
      await dispatch.applyReliabilityUpdate(order.assignedShopId, 'fulfilled');
    }

    realtime.emitStatusChanged(order.id, OrderStatus.DELIVERED);
    res.json(updated);
  }),
);

const locationSchema = z.object({
  lat: z.number(),
  lng: z.number(),
  orderId: z.string().uuid().optional(),
});

driverRouter.post(
  '/location',
  asyncHandler(async (req, res) => {
    const { lat, lng, orderId } = locationSchema.parse(req.body);

    await prisma.driver.update({
      where: { id: driverId(req) },
      data: { currentLat: lat, currentLng: lng },
    });

    if (orderId) {
      realtime.emitDriverLocation(orderId, lat, lng);
    }
    res.json({ ok: true });
  }),
);

driverRouter.get(
  '/earnings',
  asyncHandler(async (req, res) => {
    const id = driverId(req);
    const now = new Date();
    const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const weekStart = new Date(todayStart.getTime() - 7 * 24 * 60 * 60 * 1000);
    const [todayBatches, weekBatches, allBatches] = await Promise.all([
      prisma.batch.findMany({ where: { driverId: id, status: 'completed', createdAt: { gte: todayStart } }, include: { orders: { select: { totalAmount: true } } } }),
      prisma.batch.findMany({ where: { driverId: id, status: 'completed', createdAt: { gte: weekStart } }, include: { orders: { select: { totalAmount: true } } } }),
      prisma.batch.findMany({ where: { driverId: id, status: 'completed' }, include: { orders: { select: { totalAmount: true } } } }),
    ]);
    const DRIVER_CUT = 0.15;
    const calc = (b: typeof todayBatches) => b.reduce((s, x) => s + x.orders.reduce((a, o) => a + o.totalAmount, 0) * DRIVER_CUT, 0);
    const dels = (b: typeof todayBatches) => b.reduce((s, x) => s + x.orders.length, 0);
    res.json({
      today: { earnings: Math.round(calc(todayBatches)), deliveries: dels(todayBatches) },
      thisWeek: { earnings: Math.round(calc(weekBatches)), deliveries: dels(weekBatches) },
      allTime: { earnings: Math.round(calc(allBatches)), deliveries: dels(allBatches), batches: allBatches.length },
    });
  }),
);

driverRouter.get(
  '/history',
  asyncHandler(async (req, res) => {
    const batches = await prisma.batch.findMany({
      where: { driverId: driverId(req), status: 'completed' },
      include: { orders: { select: { id: true, totalAmount: true, status: true, createdAt: true, assignedShop: { select: { shopName: true } } } } },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });
    res.json(batches);
  }),
);
