/**
 * User profile & address routes.
 *   GET    /me                       — current user profile
 *   PATCH  /me                       — update name/language
 *   GET    /me/addresses             — list saved addresses
 *   POST   /me/addresses             — add new address
 *   PATCH  /me/addresses/:id/default — set as default
 *   DELETE /me/addresses/:id         — remove address
 */
import { Router } from 'express';
import { z } from 'zod';
import { asyncHandler } from '../utils/asyncHandler';
import { prisma } from '../config/prisma';
import { requireAuth } from '../middleware/auth';
import { BadRequestError, ForbiddenError, NotFoundError } from '../utils/errors';

export const usersRouter = Router();
usersRouter.use(requireAuth);

// ── Profile ──────────────────────────────────────────────────────────────────

usersRouter.get(
  '/me',
  asyncHandler(async (req, res) => {
    const user = await prisma.user.findUniqueOrThrow({
      where: { id: req.actor!.id },
      select: { id: true, name: true, phone: true, language: true, createdAt: true },
    });
    res.json(user);
  }),
);

const patchMeSchema = z.object({
  name: z.string().min(1).max(100).optional(),
  language: z.enum(['ne', 'en']).optional(),
});

usersRouter.patch(
  '/me',
  asyncHandler(async (req, res) => {
    const body = patchMeSchema.parse(req.body);
    const user = await prisma.user.update({
      where: { id: req.actor!.id },
      data: body,
      select: { id: true, name: true, phone: true, language: true },
    });
    res.json(user);
  }),
);

// ── Addresses ─────────────────────────────────────────────────────────────────

const addressSchema = z.object({
  label: z.string().min(1).max(50),
  line1: z.string().min(1).max(200),
  line2: z.string().max(200).optional(),
  city: z.string().min(1).max(100),
  lat: z.number(),
  lng: z.number(),
  isDefault: z.boolean().optional(),
});

usersRouter.get(
  '/me/addresses',
  asyncHandler(async (req, res) => {
    const addresses = await prisma.address.findMany({
      where: { userId: req.actor!.id },
      orderBy: [{ isDefault: 'desc' }, { id: 'asc' }],
    });
    res.json(addresses);
  }),
);

usersRouter.post(
  '/me/addresses',
  asyncHandler(async (req, res) => {
    const body = addressSchema.parse(req.body);
    const userId = req.actor!.id;

    // If first address or isDefault=true, clear other defaults first.
    const count = await prisma.address.count({ where: { userId } });
    const makeDefault = body.isDefault ?? count === 0;

    if (makeDefault) {
      await prisma.address.updateMany({
        where: { userId },
        data: { isDefault: false },
      });
    }

    const address = await prisma.address.create({
      data: { ...body, userId, isDefault: makeDefault },
    });
    res.status(201).json(address);
  }),
);

usersRouter.patch(
  '/me/addresses/:id/default',
  asyncHandler(async (req, res) => {
    const userId = req.actor!.id;
    const id = String(req.params.id);
    const existing = await prisma.address.findUnique({ where: { id } });
    if (!existing) throw new NotFoundError('Address not found');
    if (existing.userId !== userId) throw new ForbiddenError('Not your address');

    await prisma.address.updateMany({ where: { userId }, data: { isDefault: false } });
    const updated = await prisma.address.update({
      where: { id },
      data: { isDefault: true },
    });
    res.json(updated);
  }),
);

usersRouter.delete(
  '/me/addresses/:id',
  asyncHandler(async (req, res) => {
    const userId = req.actor!.id;
    const id = String(req.params.id);
    const existing = await prisma.address.findUnique({ where: { id } });
    if (!existing) throw new NotFoundError('Address not found');
    if (existing.userId !== userId) throw new ForbiddenError('Not your address');

    await prisma.address.delete({ where: { id } });
    res.status(204).end();
  }),
);
