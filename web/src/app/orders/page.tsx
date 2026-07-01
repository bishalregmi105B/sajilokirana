'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/context/auth-context';
import { ordersService } from '@/lib/services';
import { OrderStatusBadge } from '@/components/order-status-badge';
import type { Order } from '@/lib/types';

export default function OrdersPage() {
  const { isAuthenticated } = useAuth();
  const router = useRouter();
  const [orders, setOrders] = useState<Order[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!isAuthenticated) { router.push('/login'); return; }
    ordersService.list().then(setOrders).catch(() => {}).finally(() => setLoading(false));
  }, [isAuthenticated, router]);

  return (
    <div className="max-w-3xl mx-auto px-4 py-6">
      <h1 className="font-heading text-2xl font-bold mb-6">Your Orders</h1>
      {loading ? (
        <div className="space-y-3">{Array.from({ length: 4 }).map((_, i) => (
          <div key={i} className="bg-white rounded-card border border-border p-4 animate-pulse"><div className="h-4 bg-surface-tint rounded w-1/3 mb-2" /><div className="h-3 bg-surface-tint rounded w-2/3" /></div>
        ))}</div>
      ) : orders.length === 0 ? (
        <div className="text-center py-16">
          <p className="text-text-muted mb-4">No orders yet</p>
          <Link href="/" className="bg-primary text-white px-6 py-2.5 rounded-pill text-sm font-semibold">Start Shopping</Link>
        </div>
      ) : (
        <div className="space-y-3">
          {orders.map(order => (
            <Link key={order.id} href={`/orders/${order.id}`}
              className="block bg-white rounded-card border border-border p-4 hover:border-primary/50 transition">
              <div className="flex items-center justify-between mb-2">
                <span className="font-semibold text-sm">Order #{order.id.substring(0, 8)}</span>
                <OrderStatusBadge status={order.status} />
              </div>
              <p className="text-sm text-text-muted">
                {order.items.length} item{order.items.length > 1 ? 's' : ''} &middot; \u0930\u0941 {order.totalAmount}
              </p>
              <p className="text-xs text-text-muted mt-1">{new Date(order.createdAt).toLocaleDateString('en-NP', { day: 'numeric', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' })}</p>
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}
