/**
 * Auth service: OTP request/verify + JWT issuance.
 *
 * OTP flow (Part D.3):
 *   POST /auth/otp/request { phone }  → stores code in Redis with TTL
 *   POST /auth/otp/verify  { phone, code } → validates, upserts User, issues JWT
 *
 * In dev (OTP_USE_FIXED=true) the code is fixed + logged. In prod this is where
 * the SMS gateway call (Part D.5) would be made.
 */
import jwt from 'jsonwebtoken';
import { env } from '../config/env';
import { redis } from '../config/redis';
import { prisma } from '../config/prisma';
import { BadRequestError, UnauthorizedError } from '../utils/errors';

const OTP_KEY = (phone: string) => `otp:${phone}`;
const COOLDOWN_KEY = (phone: string) => `otp:cooldown:${phone}`;

interface JwtPayload {
  sub: string; // user id
  phone: string;
  role: string; // 'customer' | 'shop' | 'driver'
}

export class AuthService {
  /** Step 1: generate + store OTP, enforce resend cooldown. */
  async requestOtp(phone: string, role: JwtPayload['role'] = 'customer'): Promise<{ resentAfter: number | null }> {
    if (!/^\+?\d{8,15}$/.test(phone)) {
      throw new BadRequestError('Invalid phone number');
    }

    const cooldown = await redis.ttl(COOLDOWN_KEY(phone));
    if (cooldown > 0) {
      return { resentAfter: cooldown };
    }

    const code = env.otp.useFixed ? env.otp.fixedCode : randomCode();

    await redis.set(
      OTP_KEY(phone),
      JSON.stringify({ code, role }),
      'EX',
      env.otp.ttlSeconds,
    );
    await redis.set(COOLDOWN_KEY(phone), '1', 'EX', env.otp.resendCooldown);

    if (env.otp.useFixed) {
      console.log(`[otp] DEV fixed code for ${phone}: ${code}`);
    } else {
      // TODO(Part D.5): send via Sparrow SMS / Twilio WhatsApp.
      console.log(`[otp] PROD: would SMS ${code} to ${phone}`);
    }

    return { resentAfter: null };
  }

  /** Step 2: verify code, upsert the actor, issue JWT. */
  async verifyOtp(phone: string, code: string, role: JwtPayload['role'] = 'customer'): Promise<{ token: string; user: { id: string; phone: string } }> {
    const raw = await redis.get(OTP_KEY(phone));
    if (!raw) {
      throw new UnauthorizedError('OTP expired or not requested');
    }

    let stored: { code: string; role: string };
    try {
      stored = JSON.parse(raw);
    } catch {
      throw new BadRequestError('Corrupted OTP record');
    }

    if (stored.code !== code) {
      throw new UnauthorizedError('Invalid code');
    }

    // Consume the OTP (one-time use).
    await redis.del(OTP_KEY(phone));

    // Resolve or create the actor depending on role. For the customer app the
    // actor is a User; shop/driver are looked up by phone too (their own models).
    const user = await resolveActor(phone, role);

    const payload: JwtPayload = { sub: user.id, phone, role };
    // @types/jsonwebtoken v9 narrowed expiresIn to StringValue (ms-format);
    // casting via unknown is safe since jsonwebtoken's runtime accepts any ms string.
    const token = jwt.sign(payload, env.jwtSecret, {
      expiresIn: env.jwtExpiresIn as unknown as number,
    });

    return { token, user: { id: user.id, phone: user.phone } };
  }

  verifyToken(token: string): JwtPayload {
    try {
      return jwt.verify(token, env.jwtSecret) as JwtPayload;
    } catch {
      throw new UnauthorizedError('Invalid or expired token');
    }
  }
}

export const authService = new AuthService();

// ── helpers ────────────────────────────────────────────────────────────────
function randomCode(): string {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

/** Returns { id, phone } for whichever table the role maps to. */
async function resolveActor(
  phone: string,
  role: string,
): Promise<{ id: string; phone: string }> {
  switch (role) {
    case 'shop': {
      const shop = await prisma.shop.findFirst({ where: { phone } });
      if (!shop) throw new UnauthorizedError('No shop linked to this number');
      return shop;
    }
    case 'driver': {
      const driver = await prisma.driver.findFirst({ where: { phone } });
      if (!driver) throw new UnauthorizedError('No driver linked to this number');
      return driver;
    }
    default: {
      // Customer: upsert (login-or-signup in one shot).
      const user = await prisma.user.upsert({
        where: { phone },
        update: {},
        create: { phone, name: `User-${phone.slice(-4)}` },
      });
      return user;
    }
  }
}
