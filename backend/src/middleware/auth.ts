import { Request, Response, NextFunction, RequestHandler } from 'express';
import { authService } from '../services/authService';
import { UnauthorizedError, ForbiddenError } from '../utils/errors';
import { AuthActor } from '../types/auth';

/**
 * Extracts + verifies the Bearer token, attaching `req.actor`.
 * Usage: router.use(requireAuth)
 *        router.use(requireRole('shop'))
 */

const TOKEN_PREFIX = 'Bearer ';

export const requireAuth = (req: Request, _res: Response, next: NextFunction): void => {
  const header = req.headers.authorization;
  if (!header || !header.startsWith(TOKEN_PREFIX)) {
    next(new UnauthorizedError('Missing bearer token'));
    return;
  }
  const token = header.slice(TOKEN_PREFIX.length);
  const payload = authService.verifyToken(token);

  req.actor = {
    id: payload.sub,
    phone: payload.phone,
    role: payload.role,
  } as AuthActor;
  next();
};

/** Require a specific role. Call AFTER requireAuth. */
export const requireRole =
  (...roles: AuthActor['role'][]): RequestHandler =>
  (req: Request, _res: Response, next: NextFunction) => {
    if (!req.actor) { next(new UnauthorizedError()); return; }
    if (!roles.includes(req.actor.role as AuthActor['role'])) {
      next(new ForbiddenError('Insufficient role'));
      return;
    }
    next();
  };
