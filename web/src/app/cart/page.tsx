'use client';

import Link from 'next/link';
import { useCart } from '@/context/cart-context';
import { useAuth } from '@/context/auth-context';

export default function CartPage() {
  const { items, subtotal, deliveryFee, total, isEmpty, setQty, removeItem } = useCart();
  const { isAuthenticated } = useAuth();

  if (isEmpty) {
    return (
      <div className="max-w-2xl mx-auto px-4 py-16 text-center">
        <div className="w-20 h-20 bg-surface-tint rounded-full flex items-center justify-center mx-auto mb-4">
          <svg className="w-10 h-10 text-text-muted" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M2.25 3h1.386c.51 0 .955.343 1.087.835l.383 1.437M7.5 14.25a3 3 0 0 0-3 3h15.75m-12.75-3h11.218c1.121-2.3 2.1-4.684 2.924-7.138a60.114 60.114 0 0 0-16.536-1.84M7.5 14.25 5.106 5.272M6 20.25a.75.75 0 1 1-1.5 0 .75.75 0 0 1 1.5 0Zm12.75 0a.75.75 0 1 1-1.5 0 .75.75 0 0 1 1.5 0Z" />
          </svg>
        </div>
        <h2 className="font-heading text-xl font-semibold mb-2">Your cart is empty</h2>
        <p className="text-text-muted mb-6">Add items from the catalog to get started</p>
        <Link href="/" className="bg-primary text-white px-6 py-2.5 rounded-pill text-sm font-semibold hover:bg-primary-dark transition">Browse Products</Link>
      </div>
    );
  }

  return (
    <div className="max-w-3xl mx-auto px-4 py-6">
      <h1 className="font-heading text-2xl font-bold mb-6">Your Cart</h1>
      <div className="space-y-3 mb-6">
        {items.map(item => (
          <div key={item.productId} className="bg-white rounded-card border border-border p-4 flex items-center gap-4">
            <div className="w-16 h-16 bg-surface-tint rounded-card flex items-center justify-center shrink-0">
              <svg className="w-6 h-6 text-text-muted/40" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1}>
                <path strokeLinecap="round" strokeLinejoin="round" d="m2.25 15.75 5.159-5.159a2.25 2.25 0 0 1 3.182 0l5.159 5.159m-1.5-1.5 1.409-1.409a2.25 2.25 0 0 1 3.182 0l2.909 2.909M3.75 21h16.5" />
              </svg>
            </div>
            <div className="flex-1 min-w-0">
              <h3 className="font-semibold text-sm truncate">{item.name}</h3>
              <p className="text-xs text-text-muted">{item.unit}</p>
              <p className="text-sm font-semibold mt-1">\u0930\u0941 {item.price} each</p>
            </div>
            <div className="flex items-center gap-1 bg-primary rounded-pill">
              <button onClick={() => setQty(item.productId, item.qty - 1)} className="w-8 h-8 flex items-center justify-center text-white">
                <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}><path strokeLinecap="round" d="M5 12h14" /></svg>
              </button>
              <span className="text-white text-sm font-semibold min-w-[20px] text-center">{item.qty}</span>
              <button onClick={() => setQty(item.productId, item.qty + 1)} className="w-8 h-8 flex items-center justify-center text-white">
                <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}><path strokeLinecap="round" d="M12 5v14m-7-7h14" /></svg>
              </button>
            </div>
            <div className="text-right">
              <p className="font-semibold text-sm">\u0930\u0941 {item.price * item.qty}</p>
              <button onClick={() => removeItem(item.productId)} className="text-xs text-error hover:underline mt-1">Remove</button>
            </div>
          </div>
        ))}
      </div>

      {/* Price breakdown */}
      <div className="bg-white rounded-card border border-border p-4 mb-6">
        <div className="flex justify-between text-sm mb-2"><span className="text-text-muted">Subtotal</span><span>\u0930\u0941 {subtotal}</span></div>
        <div className="flex justify-between text-sm mb-2"><span className="text-text-muted">Delivery fee</span><span>{deliveryFee === 0 ? <span className="text-success">FREE</span> : `\u0930\u0941 ${deliveryFee}`}</span></div>
        {deliveryFee > 0 && <p className="text-xs text-text-muted mb-2">Free delivery on orders above \u0930\u0941 1,500</p>}
        <div className="border-t border-border pt-2 flex justify-between font-semibold"><span>Total</span><span>\u0930\u0941 {total}</span></div>
      </div>

      {isAuthenticated ? (
        <Link href="/checkout" className="block w-full bg-primary text-white py-3 rounded-pill text-center font-semibold hover:bg-primary-dark transition">
          Proceed to Checkout
        </Link>
      ) : (
        <Link href="/login" className="block w-full bg-primary text-white py-3 rounded-pill text-center font-semibold hover:bg-primary-dark transition">
          Login to Checkout
        </Link>
      )}
    </div>
  );
}
