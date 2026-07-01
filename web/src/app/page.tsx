'use client';

import { useEffect, useState } from 'react';
import { catalogService } from '@/lib/services';
import type { Product } from '@/lib/types';
import { ProductCard } from '@/components/product-card';
import { CategoryChips } from '@/components/category-chips';

export default function HomePage() {
  const [products, setProducts] = useState<Product[]>([]);
  const [categories, setCategories] = useState<string[]>([]);
  const [selectedCat, setSelectedCat] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    Promise.all([
      catalogService.getProducts(),
      catalogService.getCategories(),
    ]).then(([prods, cats]) => {
      setProducts(prods);
      setCategories(cats);
    }).catch(e => setError(e.message))
      .finally(() => setLoading(false));
  }, []);

  const filtered = selectedCat ? products.filter(p => p.category === selectedCat) : products;

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
      {/* Hero banner */}
      <div className="bg-gradient-to-r from-primary to-charcoal rounded-card p-6 sm:p-8 mb-8">
        <div className="max-w-lg">
          <span className="inline-block bg-accent text-charcoal text-xs font-bold px-3 py-1 rounded-pill mb-3">FREE DELIVERY</span>
          <h1 className="font-heading text-2xl sm:text-3xl font-bold text-white mb-2">
            \u0930\u0941100 off on your first order
          </h1>
          <p className="text-white/80 text-sm">Order groceries from your trusted local kirana shops</p>
        </div>
      </div>

      {/* Categories */}
      <section className="mb-6">
        <h2 className="font-heading text-lg font-semibold mb-3">Shop by category</h2>
        <CategoryChips categories={categories} selected={selectedCat} onSelect={setSelectedCat} />
      </section>

      {/* Products */}
      <section>
        <h2 className="font-heading text-lg font-semibold mb-4">{selectedCat ?? 'Popular items'}</h2>
        {loading ? (
          <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-4">
            {Array.from({ length: 10 }).map((_, i) => (
              <div key={i} className="bg-white rounded-card border border-border animate-pulse">
                <div className="aspect-square bg-surface-tint" />
                <div className="p-3 space-y-2">
                  <div className="h-4 bg-surface-tint rounded w-3/4" />
                  <div className="h-3 bg-surface-tint rounded w-1/2" />
                </div>
              </div>
            ))}
          </div>
        ) : error ? (
          <div className="text-center py-12">
            <p className="text-text-muted mb-4">Could not load products</p>
            <button onClick={() => window.location.reload()} className="bg-primary text-white px-6 py-2 rounded-pill text-sm font-semibold">Retry</button>
          </div>
        ) : filtered.length === 0 ? (
          <div className="text-center py-12">
            <p className="text-text-muted">No products found</p>
          </div>
        ) : (
          <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-4">
            {filtered.map(p => <ProductCard key={p.id} product={p} />)}
          </div>
        )}
      </section>
    </div>
  );
}
