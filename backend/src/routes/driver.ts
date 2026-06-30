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
  '/batches/current',
  asyncHandler(async (req, res) => {
    const batch = await prisma.batch.findFirst({
      where: { driverId: driverId(req), status: { in: ['assigned', 'in_progress'] } },
      include: { orders: { include: { items: { include: { product: true } } } } },
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
