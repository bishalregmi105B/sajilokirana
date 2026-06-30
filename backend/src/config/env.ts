/**
 * Centralized environment access for the SajiloKirana backend.
 * This is the ONLY place that reads `process.env`; everything else imports
 * from here so missing/mistyped config fails loudly at boot, not at runtime.
 * See master prompt Section 6 (environments: dev/staging/prod).
 */
import dotenv from 'dotenv';

dotenv.config();

const required = (key: string, fallback?: string): string => {
  const v = process.env[key] ?? fallback;
  if (v === undefined) {
    throw new Error(`[env] Missing required env var: ${key}`);
  }
  return v;
};

const num = (key: string, fallback: number): number => {
  const raw = process.env[key];
  if (raw === undefined || raw === '') return fallback;
  const n = Number(raw);
  if (Number.isNaN(n)) throw new Error(`[env] ${key} must be a number, got: ${raw}`);
  return n;
};

const bool = (key: string, fallback: boolean): boolean => {
  const raw = process.env[key];
  if (raw === undefined || raw === '') return fallback;
  return raw === 'true' || raw === '1';
};

export const env = {
  nodeEnv: process.env.NODE_ENV ?? 'development',
  isDev: (process.env.NODE_ENV ?? 'development') === 'development',
  isProd: process.env.NODE_ENV === 'production',
  port: num('PORT', 4000),

  databaseUrl: required('DATABASE_URL'),

  redisUrl: required('REDIS_URL'),

  jwtSecret: required('JWT_SECRET', 'dev-insecure-secret-change-me'),
  jwtExpiresIn: process.env.JWT_EXPIRES_IN ?? '7d',

  otp: {
    useFixed: bool('OTP_USE_FIXED', true),
    fixedCode: process.env.OTP_FIXED_CODE ?? '123456',
    ttlSeconds: num('OTP_TTL_SECONDS', 300),
    resendCooldown: num('OTP_RESEND_COOLDOWN_SECONDS', 30),
  },

  dispatch: {
    confirmWindowSeconds: num('DISPATCH_CONFIRM_WINDOW_SECONDS', 40),
    initialRadiusKm: num('DISPATCH_INITIAL_RADIUS_KM', 2),
    expandedRadiusKm: num('DISPATCH_EXPANDED_RADIUS_KM', 5),
    topNCandidates: num('DISPATCH_TOP_N_CANDIDATES', 3),
  },

  mlServiceUrl: process.env.ML_SERVICE_URL ?? '',

  // Vendor integration config (Part D.5). Empty = not wired.
  sparrow: {
    token: process.env.SPARROW_SMS_TOKEN ?? '',
    from: process.env.SPARROW_SMS_FROM ?? '',
  },
  twilio: {
    accountSid: process.env.TWILIO_ACCOUNT_SID ?? '',
    authToken: process.env.TWILIO_AUTH_TOKEN ?? '',
    whatsappFrom: process.env.TWILIO_WHATSAPP_FROM ?? '',
  },
  payments: {
    esewaMerchantId: process.env.ESEWA_MERCHANT_ID ?? '',
    esewaSecret: process.env.ESEWA_SECRET ?? '',
    khaltiSecretKey: process.env.KHALTI_SECRET_KEY ?? '',
    fonepayMerchantId: process.env.FONEPAY_MERCHANT_ID ?? '',
    fonepayPassword: process.env.FONEPAY_PASSWORD ?? '',
  },
  fcmServerKey: process.env.FCM_SERVER_KEY ?? '',
} as const;

export type Env = typeof env;
