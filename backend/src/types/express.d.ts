/**
 * Express.Request augmentation — actor is attached by the requireAuth middleware.
 *
 * The `export {}` turns this into a module so `declare module` below is treated
 * as an augmentation rather than an ambient module replacement.
 */
export {};

declare module 'express-serve-static-core' {
  interface Request {
    actor?: {
      id: string;
      phone: string;
      role: 'customer' | 'shop' | 'driver' | 'admin';
    };
  }
}
