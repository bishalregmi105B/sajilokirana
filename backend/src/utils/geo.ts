/**
 * Order + driver status enums as plain string unions. These MUST match the
 * Prisma schema comments and the customer app's `OrderStatusBadge` (which
 * maps these slugs to labels + colors via AppColors.forOrderStatus).
 */
export const OrderStatus = {
  PENDING: 'pending',
  BROADCASTING: 'broadcasting',
  SHOP_CONFIRMED: 'shop_confirmed',
  PICKED_UP: 'picked_up',
  IN_TRANSIT: 'in_transit',
  DELIVERED: 'delivered',
  CANCELLED: 'cancelled',
} as const;
export type OrderStatus = (typeof OrderStatus)[keyof typeof OrderStatus];

export const DriverStatus = {
  OFFLINE: 'offline',
  AVAILABLE: 'available',
  BUSY: 'busy',
} as const;
export type DriverStatus = (typeof DriverStatus)[keyof typeof DriverStatus];

/** Haversine distance in km between two lat/lng points. */
export function haversineKm(
  lat1: number,
  lng1: number,
  lat2: number,
  lng2: number,
): number {
  const R = 6371; // Earth radius km
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
  return 2 * R * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

const toRad = (deg: number): number => (deg * Math.PI) / 180;
