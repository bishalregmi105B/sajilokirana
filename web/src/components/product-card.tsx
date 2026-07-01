'use client';

import { useCart } from '@/context/cart-context';
import type { Product } from '@/lib/types';

export function ProductCard({ product }: { product: Product }) {
  const { addItem, setQty, qtyFor } = useCart();
  const qty = qtyFor(product.id);

  return (
    <div className="bg-white rounded-card border border-border overflow-hidden hover:shadow-md transition group">
      <div className="aspect-square bg-surface-tint flex items-center justify-center">
        <svg className="w-12 h-12 text-text-muted/40" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1}>
          <path strokeLinecap="round" strokeLinejoin="round" d="m2.25 15.75 5.159-5.159a2.25 2.25 0 0 1 3.182 0l5.159 5.159m-1.5-1.5 1.409-1.409a2.25 2.25 0 0 1 3.182 0l2.909 2.909M3.75 21h16.5" />
        </svg>
      </div>
      <div className="p-3">
        <h3 className="font-semibold text-sm text-charcoal truncate">{product.name}</h3>
        {product.unit && <p className="text-xs text-text-muted mt-0.5">{product.unit}</p>}
        <div className="flex items-center justify-between mt-2">
          <span className="font-semibold text-sm">
            {product.minPrice != null ? `\u0930\u0941 ${product.minPrice}` : 'N/A'}
          </span>
          {!product.inStock ? (
            <span className="text-xs text-error border border-error px-2 py-0.5 rounded-pill">Out of stock</span>
          ) : qty === 0 ? (
            <button
              onClick={() => addItem({ productId: product.id, name: product.name, unit: product.unit, price: product.minPrice ?? 0 })}
              className="bg-primary text-white text-xs font-semibold px-4 py-1.5 rounded-pill hover:bg-primary-dark transition"
            >
              Add
            </button>
          ) : (
            <div className="flex items-center gap-1 bg-primary rounded-pill">
              <button onClick={() => setQty(product.id, qty - 1)} className="w-7 h-7 flex items-center justify-center text-white">
                <svg className="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}><path strokeLinecap="round" d="M5 12h14" /></svg>
              </button>
              <span className="text-white text-xs font-semibold min-w-[16px] text-center">{qty}</span>
              <button onClick={() => setQty(product.id, qty + 1)} className="w-7 h-7 flex items-center justify-center text-white">
                <svg className="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}><path strokeLinecap="round" d="M12 5v14m-7-7h14" /></svg>
              </button>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
