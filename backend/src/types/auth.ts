/**
 * AuthActor — the decoded JWT payload attached to req.actor by requireAuth.
 * Kept in its own module so both middleware and route files can import it
 * without touching express.d.ts (which must remain a global ambient file).
 */
export interface AuthActor {
  id: string;
  phone: string;
  role: 'customer' | 'shop' | 'driver' | 'admin';
}
