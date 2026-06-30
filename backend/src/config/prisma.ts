/**
 * Prisma client singleton (Prisma v7).
 *
 * In Prisma v7 the `url` property was removed from schema.prisma datasource.
 * Runtime connections are made via the @prisma/adapter-pg driver adapter.
 * Migration connection config lives in prisma.config.ts.
 */
import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { env } from './env';

const globalForPrisma = globalThis as unknown as { prisma?: PrismaClient };

function createPrisma(): PrismaClient {
  const adapter = new PrismaPg({ connectionString: env.databaseUrl });
  return new PrismaClient({
    adapter,
    log: env.isDev ? ['query', 'warn', 'error'] : ['warn', 'error'],
  });
}

export const prisma = globalForPrisma.prisma ?? createPrisma();

if (env.isDev) {
  globalForPrisma.prisma = prisma;
}
