/**
 * Auth routes (Part D.3).
 *   POST /auth/otp/request  { phone }
 *   POST /auth/otp/verify   { phone, code } → { token }
 */
import { Router } from 'express';
import { z } from 'zod';
import { asyncHandler } from '../utils/asyncHandler';
import { authService } from '../services/authService';
import { BadRequestError } from '../utils/errors';

export const authRouter = Router();

const phoneSchema = z.object({
  phone: z.string().regex(/^\+?\d{8,15}$/, 'Invalid phone'),
  role: z.enum(['customer', 'shop', 'driver']).optional().default('customer'),
});

authRouter.post(
  '/otp/request',
  asyncHandler(async (req, res) => {
    const { phone, role } = phoneSchema.parse(req.body);
    const { resentAfter } = await authService.requestOtp(phone, role);
    res.json({
      ok: true,
      ...(resentAfter ? { resentAfter } : {}),
      // In dev, echo the fixed code so the client/test can read it without SMS.
      ...(process.env.OTP_USE_FIXED === 'true'
        ? { devCode: process.env.OTP_FIXED_CODE ?? '123456' }
        : {}),
    });
  }),
);

const verifySchema = z.object({
  phone: z.string().regex(/^\+?\d{8,15}$/, 'Invalid phone'),
  code: z.string().regex(/^\d{4,8}$/, 'Invalid code'),
  role: z.enum(['customer', 'shop', 'driver']).optional().default('customer'),
});

authRouter.post(
  '/otp/verify',
  asyncHandler(async (req, res) => {
    const { phone, code, role } = verifySchema.parse(req.body);
    if (!code) throw new BadRequestError('Code required');
    const result = await authService.verifyOtp(phone, code, role);
    res.json(result);
  }),
);
