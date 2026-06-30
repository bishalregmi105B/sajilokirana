/**
 * Catalog routes (Part D.3).
 *   GET /catalog              — list all products with min price from inventory
 *   GET /catalog/categories   — distinct categories
 */
import { Router } from 'express';
import { z } from 'zod';
import { asyncHandler } from '../utils/asyncHandler';
import { prisma } from '../config/prisma';

export const catalogRouter = Router();

const querySchema = z.object({
  category: z.string().optional(),
  q: z.string().optional(),
  limit: z.coerce.number().int().positive().max(200).optional(),
  offset: z.coerce.number().int().min(0).optional(),
});

catalogRouter.get(
  '/categories',
  asyncHandler(async (_req, res) => {
    const rows = await prisma.productCatalog.findMany({
      select: { category: true },
      distinct: ['category'],
      orderBy: { category: 'asc' },
    });
    res.json(rows.map((r) => r.category));
  }),
);

catalogRouter.get(
  '/',
  asyncHandler(async (req, res) => {
    const { category, q, limit = 100, offset = 0 } = querySchema.parse(req.query);

    const products = await prisma.productCatalog.findMany({
      where: {
        ...(category ? { category } : {}),
        ...(q ? { name: { contains: q, mode: 'insensitive' } } : {}),
      },
      include: {
        inventory: {
          where: { inStock: true },
          orderBy: { price: 'asc' },
          take: 1,
          select: { price: true, shopId: true },
        },
      },
      orderBy: { name: 'asc' },
      take: limit,
      skip: offset,
    });

    // Shape each product to include convenient price/inStock fields.
    const shaped = products.map((p) => ({
      id: p.id,
      name: p.name,
      category: p.category,
      unit: p.unit,
      minPrice: p.inventory[0]?.price ?? null,
      inStock: p.inventory.length > 0,
    }));

    res.json(shaped);
  }),
);
