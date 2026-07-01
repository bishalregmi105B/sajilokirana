'use client';

import { useState, useEffect, useRef } from 'react';
import { catalogService } from '@/lib/services';
import type { Product } from '@/lib/types';
import { ProductCard } from '@/components/product-card';

export default function SearchPage() {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState<Product[]>([]);
  const [loading, setLoading] = useState(false);
  const debounceRef = useRef<ReturnType<typeof setTimeout>>();

  useEffect(() => {
    if (debounceRef.current) clearTimeout(debounceRef.current);
    if (!query.trim()) { setResults([]); return; }
    debounceRef.current = setTimeout(() => {
      setLoading(true);
      catalogService.getProducts({ q: query.trim() })
        .then(setResults)
        .catch(() => setResults([]))
        .finally(() => setLoading(false));
    }, 300);
    return () => { if (debounceRef.current) clearTimeout(debounceRef.current); };
  }, [query]);

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
      <div className="max-w-xl mx-auto mb-8">
        <div className="relative">
          <svg className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-text-muted" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
            <path strokeLinecap="round" strokeLinejoin="round" d="m21 21-5.197-5.197m0 0A7.5 7.5 0 1 0 5.196 5.196a7.5 7.5 0 0 0 10.607 10.607Z" />
          </svg>
          <input type="text" value={query} onChange={e => setQuery(e.target.value)} placeholder="Search for groceries..."
            className="w-full pl-10 pr-4 py-3 border border-border rounded-card bg-white focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary"
            autoFocus />
        </div>
      </div>

      {loading ? (
        <div className="text-center py-8"><div className="animate-spin w-6 h-6 border-2 border-primary border-t-transparent rounded-full mx-auto" /></div>
      ) : query.trim() && results.length === 0 ? (
        <div className="text-center py-12"><p className="text-text-muted">No results for "{query}"</p></div>
      ) : (
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-4">
          {results.map(p => <ProductCard key={p.id} product={p} />)}
        </div>
      )}
    </div>
  );
}
