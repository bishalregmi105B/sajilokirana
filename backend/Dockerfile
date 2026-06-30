# SajiloKirana backend — production image (Section 6).
# Multi-stage: build TS, then slim runtime.
FROM node:20-alpine AS builder
WORKDIR /app

COPY package*.json ./
COPY prisma ./prisma
RUN npm ci

COPY tsconfig.json ./
COPY src ./src
RUN npx prisma generate
RUN npm run build && npm prune --production

# ── runtime ────────────────────────────────────────────────────────────────
FROM node:20-alpine AS runtime
WORKDIR /app
ENV NODE_ENV=production

# Safe-by-default; override at deploy time.
ENV PORT=4000

COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/prisma ./prisma
COPY package*.json ./

EXPOSE 4000

# Generate Prisma client at start (uses mounted schema) then run.
CMD ["sh", "-c", "npx prisma generate && node dist/server.js"]
