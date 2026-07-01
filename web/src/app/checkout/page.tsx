'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useCart } from '@/context/cart-context';
import { useAuth } from '@/context/auth-context';
import { addressService, ordersService } from '@/lib/services';
import type { Address } from '@/lib/types';

export default function CheckoutPage() {
  const { items, total, clear, isEmpty } = useCart();
  const { isAuthenticated } = useAuth();
  const router = useRouter();
  const [addresses, setAddresses] = useState<Address[]>([]);
  const [selectedAddr, setSelectedAddr] = useState<Address | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!isAuthenticated) { router.push('/login'); return; }
    if (isEmpty) { router.push('/cart'); return; }
    addressService.list().then(addrs => {
      setAddresses(addrs);
      setSelectedAddr(addrs.find(a => a.isDefault) || addrs[0] || null);
    }).catch(() => {});
  }, [isAuthenticated, isEmpty, router]);

  const placeOrder = async () => {
    if (!selectedAddr) { setError('Please select a delivery address'); return; }
    setLoading(true); setError(null);
    try {
      const order = await ordersService.create(
        items.map(i => ({ productId: i.productId, qty: i.qty })),
        { label: selectedAddr.label, line1: selectedAddr.line1, line2: selectedAddr.line2, city: selectedAddr.city, lat: selectedAddr.lat, lng: selectedAddr.lng },
      );
      clear();
      router.push(`/orders/${order.id}`);
    } catch (e: any) { setError(e.message || 'Failed to place order'); }
    finally { setLoading(false); }
  };

  return (
    <div className="max-w-2xl mx-auto px-4 py-6">
      <h1 className="font-heading text-2xl font-bold mb-6">Checkout</h1>

      {/* Address selection */}
      <section className="mb-6">
        <h2 className="font-semibold text-sm mb-3">Delivery Address</h2>
        {addresses.length === 0 ? (
          <div className="bg-white rounded-card border border-border p-4 text-center">
            <p className="text-text-muted text-sm mb-3">No saved addresses</p>
            <button onClick={() => router.push('/profile/addresses')} className="text-primary text-sm font-semibold hover:underline">Add Address</button>
          </div>
        ) : (
          <div className="space-y-2">
            {addresses.map(addr => (
              <button key={addr.id} onClick={() => setSelectedAddr(addr)}
                className={`w-full text-left bg-white rounded-card border p-3 transition ${
                  selectedAddr?.id === addr.id ? 'border-primary ring-1 ring-primary/30' : 'border-border hover:border-primary/50'
                }`}>
                <div className="flex items-center gap-2">
                  <div className={`w-4 h-4 rounded-full border-2 flex items-center justify-center ${
                    selectedAddr?.id === addr.id ? 'border-primary' : 'border-border'
                  }`}>
                    {selectedAddr?.id === addr.id && <div className="w-2 h-2 rounded-full bg-primary" />}
                  </div>
                  <div>
                    <p className="font-semibold text-sm">{addr.label}</p>
                    <p className="text-xs text-text-muted">{addr.line1}, {addr.city}</p>
                  </div>
                </div>
              </button>
            ))}
          </div>
        )}
      </section>

      {/* Order summary */}
      <section className="bg-white rounded-card border border-border p-4 mb-6">
        <h2 className="font-semibold text-sm mb-3">Order Summary</h2>
        {items.map(item => (
          <div key={item.productId} className="flex justify-between text-sm py-1">
            <span>{item.name} x {item.qty}</span>
            <span>\u0930\u0941 {item.price * item.qty}</span>
          </div>
        ))}
        <div className="border-t border-border mt-2 pt-2 flex justify-between font-semibold">
          <span>Total</span><span>\u0930\u0941 {total}</span>
        </div>
      </section>

      {error && <p className="text-error text-sm mb-4">{error}</p>}

      <button onClick={placeOrder} disabled={loading || !selectedAddr}
        className="w-full bg-primary text-white py-3 rounded-pill font-semibold hover:bg-primary-dark transition disabled:opacity-50">
        {loading ? 'Placing Order...' : `Place Order - \u0930\u0941 ${total}`}
      </button>
    </div>
  );
}
