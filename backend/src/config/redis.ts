/**
 * Redis client (ioredis). Used for:
 *  - dispatch confirm-window TTL keys (Part D.4 step 4)
 *  - OTP storage + TTL
 *  - caching hot queries
 * See master prompt D.1.
 */
import Redis from 'ioredis';
import { env } from './env';

const globalForRedis = globalThis as unknown as { redis?: Redis };

export const redis =
  globalForRedis.redis ??
  new Redis(env.redisUrl, {
    maxRetriesPerRequest: 3,
    enableReadyCheck: true,
    lazyConnect: false,
  });

if (env.isDev) {
  globalForRedis.redis = redis;
}

redis.on('error', (err) => {
  // Don't crash the process on transient redis errors — the dispatch engine
  // degrades gracefully (see services/dispatch.ts).
  console.error('[redis] error:', err.message);
});
