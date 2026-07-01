'use client';

import { useEffect, useState } from 'react';
import { useParams } from 'next/navigation';
import Link from 'next/link';
import { ordersService } from '@/lib/services';
import { OrderStatusBadge } from '@/components/order-status-badge';
import type { Order } from '@/lib/types';

export default function OrderDetailPage() {
  const { id } = useParams<{ id: string }>();
  const [order, setOrder] = useState<Order | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!id) return;
    ordersService.get(id).then(setOrder).catch(() => {}).finally(() => setLoading(false));
  }, [id]);

  if (loading) return <div className="max-w-2xl mx-auto px-4 py-12 text-center"><div className="animate-spin w-8 h-8 border-2 border-primary border-t-transparent rounded-full mx-auto" /></div>;
  if (!order) return <div className="max-w-2xl mx-auto px-4 py-12 text-center"><p className="text-text-muted">Order not found</p></div>;

  return (
    <div className="max-w-2xl mx-auto px-4 py-6">
      <div className="flex items-center justify-between mb-6">
        <h1 className="font-heading text-xl font-bold">Order #{order.id.substring(0, 8)}</h1>
        <OrderStatusBadge status={order.status} />
      </div>

      {order.assignedShop && (
        <div className="bg-surface-tint rounded-card p-4 mb-4">
          <p className="text-sm"><span className="text-text-muted">Shop:</span> <span className="font-semibold">{order.assignedShop.shopName}</span></p>
        </div>
      )}

      <div className="bg-white rounded-card border border-border p-4 mb-4">
        <h2 className="font-semibold text-sm mb-3">Items</h2>
        {order.items.map(item => (
          <div key={item.id} className="flex justify-between text-sm py-1.5 border-b border-border last:border-0">
            <div>
              <p className="font-medium">{item.product?.name || 'Item'}</p>
              <p className="text-xs text-text-muted">{item.product?.unit} x {item.qty}</p>
            </div>
            <span className="font-semibold">\u0930\u0941 {item.unitPrice * item.qty}</span>
          </div>
        ))}
        <div className="border-t border-border mt-2 pt-2 flex justify-between font-semibold text-sm">
          <span>Total</span><span>\u0930\u0941 {order.totalAmount}</span>
        </div>
      </div>

      <p className="text-xs text-text-muted">Placed on {new Date(order.createdAt).toLocaleString()}</p>

      <div className="mt-6">
        <Link href="/orders" className="text-primary text-sm font-semibold hover:underline">&larr; Back to Orders</Link>
      </div>
    </div>
  );
}
