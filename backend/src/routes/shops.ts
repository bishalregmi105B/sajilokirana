/**
 * Shop discovery routes (Part D.3).
 *   GET /shops/nearby?lat&lng&radius   — active shops within radius (km),
 *                                        optionally filtered by category.
 *
 * Distance is computed in-process via haversine (good enough for the low
 * shop density of an MVP pilot). At scale this becomes a PostGIS query.
 */
import { Router } from 'express';
import { z } from 'zod';
import { asyncHandler } from '../utils/asyncHandler';
import { prisma } from '../config/prisma';
import { haversineKm } from '../utils/geo';

export const shopsRouter = Router();

const nearbySchema = z.object({
  lat: z.coerce.number(),
  lng: z.coerce.number(),
  radius: z.coerce.number().optional().default(2),
  category: z.string().optional(),
});

shopsRouter.get(
  '/nearby',
  asyncHandler(async (req, res) => {
    const { lat, lng, radius, category } = nearbySchema.parse(req.query);

    const candidates = await prisma.shop.findMany({
      where: { status: 'active' },
      include: { inventory: true },
    });

    const nearby = candidates
      .map((shop) => ({
        ...shop,
        distanceKm: haversineKm(lat, lng, shop.lat, shop.lng),
      }))
      .filter((shop) => shop.distanceKm <= radius)
      .filter((shop) =>
        category ? shop.categories.includes(category) : true,
      )
      .sort((a, b) => a.distanceKm - b.distanceKm);

    res.json(nearby);
  }),
);
