// Prisma v7 configuration file.
// Replaces the `url` property that was removed from schema.prisma in Prisma v7.
// Used by `prisma migrate`, `prisma db push`, `prisma studio`, and `prisma generate`.
// Runtime connection is handled via the PrismaPg adapter in src/config/prisma.ts.
// See: https://pris.ly/d/config-datasource

import { defineConfig } from 'prisma/config';
import 'dotenv/config';

export default defineConfig({
  datasources: {
    db: {
      url: process.env.DATABASE_URL!,
    },
  },
});
