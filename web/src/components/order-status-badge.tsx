const STATUS_MAP: Record<string, { label: string; color: string }> = {
  pending: { label: 'Pending', color: 'bg-warning/15 text-warning' },
  broadcasting: { label: 'Finding shop', color: 'bg-warning/15 text-warning' },
  shop_confirmed: { label: 'Shop confirmed', color: 'bg-primary/15 text-primary' },
  picked_up: { label: 'Picked up', color: 'bg-primary/15 text-primary' },
  in_transit: { label: 'On the way', color: 'bg-primary/15 text-primary' },
  delivered: { label: 'Delivered', color: 'bg-success/15 text-success' },
  cancelled: { label: 'Cancelled', color: 'bg-error/15 text-error' },
};

export function OrderStatusBadge({ status }: { status: string }) {
  const s = STATUS_MAP[status] ?? { label: status.replace(/_/g, ' '), color: 'bg-gray-100 text-gray-600' };
  return (
    <span className={`inline-block px-2.5 py-0.5 rounded-pill text-xs font-semibold ${s.color}`}>
      {s.label}
    </span>
  );
}
