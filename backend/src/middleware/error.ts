import { Request, Response, NextFunction } from 'express';
import { ZodError } from 'zod';
import { HttpError } from '../utils/errors';
import { env } from '../config/env';

/** 404 for unmatched routes. */
export const notFound = (_req: Request, res: Response): void => {
  res.status(404).json({ error: 'Not found' });
};

/** Central error handler. Converts thrown errors → consistent JSON. */
export const errorHandler = (err: unknown, _req: Request, res: Response, _next: NextFunction): void => {
  if (err instanceof ZodError) {
    res.status(400).json({
      error: 'Validation error',
      details: err.flatten(),
    });
    return;
  }

  if (err instanceof HttpError) {
    res.status(err.statusCode).json({
      error: err.message,
      ...(err.details ? { details: err.details } : {}),
    });
    return;
  }

  // Unknown — log full trace, return generic message (never leak internals).
  console.error('[unhandled]', err);
  const message = env.isProd ? 'Internal server error' : (err instanceof Error ? err.message : String(err));
  res.status(500).json({ error: message });
};
