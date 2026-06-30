/**
 * Order routes (Part D.3) — customer side.
 *   POST   /orders                  create order + kick off dispatch
 *   GET    /orders/:id
 *   PATCH  /orders/:id/status
 */
import { Router } from 'express';
import { z } from 'zod';
import { asyncHandler } from '../utils/asyncHandler';
import { prisma } from '../config/prisma';
import { requireAuth } from '../middleware/auth';
import { dispatch } from '../services/dispatch';
import { BadRequestError, ForbiddenError, NotFoundError } from '../utils/errors';
import { OrderStatus } from '../utils/geo';

export const ordersRouter = Router();

ordersRouter.use(requireAuth);

const createSchema = z.object({
  items: z.array(z.object({
    productId: z.string().uuid(),
    qty: z.number().int().positive(),
  })).min(1),
  deliveryAddress: z.object({
    label: z.string().optional(),
    line1: z.string(),
    line2: z.string().optional(),
    city: z.string(),
    lat: z.number(),
    lng: z.number(),
  }),
});

ordersRouter.post(
  '/',
  asyncHandler(async (req, res) => {
    const body = createSchema.parse(req.body);
    const actor = req.actor!;

    // Resolve unit prices from the cheapest in-stock inventory entry per
    // product (simple MVP pricing; richer shop-bound pricing happens post-dispatch).
    const products = await prisma.productCatalog.findMany({
      where: { id: { in: body.items.map((i) => i.productId) } },
      include: {
        inventory: { where: { inStock: true }, orderBy: { price: 'asc' } },
      },
    });

    if (products.length !== body.items.length) {
      throw new BadRequestError('One or more products not found');
    }

    let total = 0;
    const itemRows = body.items.map((item) => {
      const product = products.find((p) => p.id === item.productId)!;
      const cheapest = product.inventory[0];
      if (!cheapest) {
        throw new BadRequestError(`${product.name} is out of stock everywhere`);
      }
      const lineTotal = cheapest.price * item.qty;
      total += lineTotal;
      return {
        productId: item.productId,
        qty: item.qty,
        unitPrice: cheapest.price,
      };
    });

    const order = await prisma.order.create({
      data: {
        customerId: actor.id,
        status: OrderStatus.PENDING,
        totalAmount: total,
        deliveryAddress: body.deliveryAddress,
        items: { create: itemRows },
      },
      include: { items: true },
    });

    // Kick off the dispatch engine (async — don't block the response).
    dispatch.startDispatch(order.id).catch((err) => {
      console.error(`[orders] dispatch failed for ${order.id}:`, err);
    });

    res.status(201).json(order);
  }),
);

// List all orders for the current customer.
ordersRouter.get(
  '/',
  asyncHandler(async (req, res) => {
    const orders = await prisma.order.findMany({
      where: { customerId: req.actor!.id },
      include: {
        items: { include: { product: true } },
        assignedShop: { select: { shopName: true } },
      },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });
    res.json(orders);
  }),
);

ordersRouter.get(
  '/:id',
  asyncHandler(async (req, res) => {
    const order = await prisma.order.findUnique({
      where: { id: req.params.id as string },
      include: {
        items: { include: { product: true } },
        assignedShop: true,
      },
    });
    if (!order) throw new NotFoundError('Order not found');
    if (order.customerId !== req.actor!.id && req.actor!.role !== 'admin') {
      throw new ForbiddenError();
    }
    res.json(order);
  }),
);

const statusSchema = z.object({
  status: z.enum([
    OrderStatus.PENDING,
    OrderStatus.BROADCASTING,
    OrderStatus.SHOP_CONFIRMED,
    OrderStatus.PICKED_UP,
    OrderStatus.IN_TRANSIT,
    OrderStatus.DELIVERED,
    OrderStatus.CANCELLED,
  ]),
});

ordersRouter.patch(
  '/:id/status',
  asyncHandler(async (req, res) => {
    const { status } = statusSchema.parse(req.body);
    const orderId = req.params.id as string;
    const order = await prisma.order.findUnique({ where: { id: orderId } });
    if (!order) throw new NotFoundError('Order not found');

    const updated = await prisma.order.update({
      where: { id: orderId },
      data: { status },
    });

    // Reliability update on terminal states (D.4 step 7).
    if (status === OrderStatus.DELIVERED && order.assignedShopId) {
      await dispatch.applyReliabilityUpdate(order.assignedShopId, 'fulfilled');
    } else if (status === OrderStatus.CANCELLED && order.assignedShopId && order.status === OrderStatus.SHOP_CONFIRMED) {
      await dispatch.applyReliabilityUpdate(order.assignedShopId, 'ghosted');
    }

    res.json(updated);
  }),
);
