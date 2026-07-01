'use client';

import { createContext, useContext, useState, useCallback, type ReactNode } from 'react';
import type { CartItem } from '@/lib/types';

interface CartCtx {
  items: CartItem[];
  itemCount: number;
  subtotal: number;
  deliveryFee: number;
  total: number;
  isEmpty: boolean;
  addItem: (item: Omit<CartItem, 'qty'>) => void;
  setQty: (productId: string, qty: number) => void;
  removeItem: (productId: string) => void;
  clear: () => void;
  qtyFor: (productId: string) => number;
}

const CartContext = createContext<CartCtx | null>(null);

export function CartProvider({ children }: { children: ReactNode }) {
  const [items, setItems] = useState<CartItem[]>([]);

  const addItem = useCallback((item: Omit<CartItem, 'qty'>) => {
    setItems(prev => {
      const existing = prev.find(i => i.productId === item.productId);
      if (existing) return prev.map(i => i.productId === item.productId ? { ...i, qty: i.qty + 1 } : i);
      return [...prev, { ...item, qty: 1 }];
    });
  }, []);

  const setQty = useCallback((productId: string, qty: number) => {
    setItems(prev => qty <= 0 ? prev.filter(i => i.productId !== productId) : prev.map(i => i.productId === productId ? { ...i, qty } : i));
  }, []);

  const removeItem = useCallback((productId: string) => {
    setItems(prev => prev.filter(i => i.productId !== productId));
  }, []);

  const clear = useCallback(() => setItems([]), []);

  const qtyFor = useCallback((productId: string) => items.find(i => i.productId === productId)?.qty ?? 0, [items]);

  const itemCount = items.reduce((s, i) => s + i.qty, 0);
  const subtotal = items.reduce((s, i) => s + i.price * i.qty, 0);
  const deliveryFee = subtotal > 1500 ? 0 : 50;
  const total = subtotal + deliveryFee;

  return (
    <CartContext.Provider value={{ items, itemCount, subtotal, deliveryFee, total, isEmpty: items.length === 0, addItem, setQty, removeItem, clear, qtyFor }}>
      {children}
    </CartContext.Provider>
  );
}

export function useCart() {
  const ctx = useContext(CartContext);
  if (!ctx) throw new Error('useCart must be inside CartProvider');
  return ctx;
}
