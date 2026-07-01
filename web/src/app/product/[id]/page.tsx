'use client';

import { useEffect, useState } from 'react';
import { useParams } from 'next/navigation';
import { catalogService } from '@/lib/services';
import { useCart } from '@/context/cart-context';
import type { ProductDetail } from '@/lib/types';

export default function ProductDetailPage() {
  const { id } = useParams<{ id: string }>();
  const [product, setProduct] = useState<ProductDetail | null>(null);
  const [loading, setLoading] = useState(true);
  const { addItem, setQty, qtyFor } = useCart();

  useEffect(() => {
    if (!id) return;
    catalogService.getProduct(id).then(setProduct).catch(() => {}).finally(() => setLoading(false));
  }, [id]);

  if (loading) return <div className="max-w-2xl mx-auto px-4 py-12 text-center"><div className="animate-spin w-8 h-8 border-2 border-primary border-t-transparent rounded-full mx-auto" /></div>;
  if (!product) return <div className="max-w-2xl mx-auto px-4 py-12 text-center"><p className="text-text-muted">Product not found</p></div>;

  const qty = qtyFor(product.id);

  return (
    <div className="max-w-3xl mx-auto px-4 py-6">
      <div className="grid md:grid-cols-2 gap-8">
        <div className="aspect-square bg-surface-tint rounded-card flex items-center justify-center">
          <svg className="w-24 h-24 text-text-muted/30" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={0.5}>
            <path strokeLinecap="round" strokeLinejoin="round" d="m2.25 15.75 5.159-5.159a2.25 2.25 0 0 1 3.182 0l5.159 5.159m-1.5-1.5 1.409-1.409a2.25 2.25 0 0 1 3.182 0l2.909 2.909M3.75 21h16.5" />
          </svg>
        </div>
        <div>
          <span className="text-xs text-text-muted bg-surface-tint px-2 py-1 rounded-pill">{product.category}</span>
          <h1 className="font-heading text-2xl font-bold mt-2 mb-1">{product.name}</h1>
          <p className="text-text-muted text-sm mb-4">{product.unit}</p>
          {product.minPrice != null && <p className="text-2xl font-bold mb-4">\u0930\u0941 {product.minPrice}</p>}

          {!product.inStock ? (
            <p className="text-error font-semibold">Out of stock</p>
          ) : qty === 0 ? (
            <button onClick={() => addItem({ productId: product.id, name: product.name, unit: product.unit, price: product.minPrice ?? 0 })}
              className="bg-primary text-white px-8 py-3 rounded-pill font-semibold hover:bg-primary-dark transition">Add to Cart</button>
          ) : (
            <div className="flex items-center gap-3">
              <div className="flex items-center gap-1 bg-primary rounded-pill">
                <button onClick={() => setQty(product.id, qty - 1)} className="w-10 h-10 flex items-center justify-center text-white">-</button>
                <span className="text-white font-semibold min-w-[24px] text-center">{qty}</span>
                <button onClick={() => setQty(product.id, qty + 1)} className="w-10 h-10 flex items-center justify-center text-white">+</button>
              </div>
              <span className="text-sm text-text-muted">in cart</span>
            </div>
          )}
        </div>
      </div>

      {/* Shop prices */}
      {product.shops.length > 0 && (
        <section className="mt-8">
          <h2 className="font-heading text-lg font-semibold mb-4">Available at {product.shops.length} shop{product.shops.length > 1 ? 's' : ''}</h2>
          <div className="space-y-2">
            {product.shops.map(shop => (
              <div key={shop.shopId} className="bg-white rounded-card border border-border p-4 flex items-center justify-between">
                <div>
                  <p className="font-semibold text-sm">{shop.shopName}</p>
                  <p className="text-xs text-text-muted">Reliability: {Math.round(shop.reliabilityScore * 100)}%</p>
                </div>
                <span className="font-bold">\u0930\u0941 {shop.price}</span>
              </div>
            ))}
          </div>
        </section>
      )}
    </div>
  );
}
