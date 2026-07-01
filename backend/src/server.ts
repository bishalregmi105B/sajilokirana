/**
 * SajiloKirana backend entry point.
 * Creates the Express app, mounts all routers, attaches Socket.io, and starts
 * the HTTP server.  All environment access goes through config/env.ts —
 * never read process.env directly here.
 */
import 'dotenv/config';
import http from 'http';
import cors from 'cors';
import express from 'express';

import { env } from './config/env';
import { realtime } from './sockets/realtime';

import { authRouter } from './routes/auth';
import { catalogRouter } from './routes/catalog';
import { shopsRouter } from './routes/shops';
import { ordersRouter } from './routes/orders';
import { shopRouter } from './routes/shop';
import { driverRouter } from './routes/driver';
import { webhooksRouter } from './routes/webhooks';
import { usersRouter } from './routes/users';
import { adminRouter } from './routes/admin';

import { notFound, errorHandler } from './middleware/error';

// ── App ───────────────────────────────────────────────────────────────────

const app = express();

app.use(cors());
app.use(express.json());

// Health check — used by Docker compose health probes.
app.get('/healthz', (_req, res) => res.json({ ok: true }));

// ── Routes ────────────────────────────────────────────────────────────────

app.use('/auth', authRouter);
app.use('/catalog', catalogRouter);
app.use('/shops', shopsRouter);
app.use('/orders', ordersRouter);
app.use('/shop', shopRouter);
app.use('/driver', driverRouter);
app.use('/webhooks', webhooksRouter);
app.use('/admin', adminRouter);
app.use('/', usersRouter);

// ── Error layer (must be last) ────────────────────────────────────────────

app.use(notFound);
app.use(errorHandler);

// ── HTTP + Socket.io server ───────────────────────────────────────────────

const httpServer = http.createServer(app);

realtime.init(httpServer);

httpServer.listen(env.port, () => {
  console.log(`[server] SajiloKirana backend running on port ${env.port} (${env.nodeEnv})`);
});

export { app, httpServer };
