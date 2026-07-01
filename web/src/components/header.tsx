'use client';

import Link from 'next/link';
import { useAuth } from '@/context/auth-context';
import { useCart } from '@/context/cart-context';

export function Header() {
  const { isAuthenticated, user, logout } = useAuth();
  const { itemCount } = useCart();

  return (
    <header className="sticky top-0 z-50 bg-white border-b border-border">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
        <Link href="/" className="flex items-center gap-2">
          <div className="w-8 h-8 bg-primary rounded-lg flex items-center justify-center">
            <span className="text-white font-bold text-sm">SK</span>
          </div>
          <span className="font-heading text-xl font-semibold text-charcoal">SajiloKirana</span>
        </Link>

        <nav className="hidden md:flex items-center gap-6">
          <Link href="/" className="text-sm font-medium text-text-muted hover:text-charcoal transition">Home</Link>
          <Link href="/search" className="text-sm font-medium text-text-muted hover:text-charcoal transition">Search</Link>
          {isAuthenticated && (
            <Link href="/orders" className="text-sm font-medium text-text-muted hover:text-charcoal transition">Orders</Link>
          )}
        </nav>

        <div className="flex items-center gap-4">
          <Link href="/cart" className="relative p-2 hover:bg-surface-tint rounded-full transition">
            <svg className="w-6 h-6 text-charcoal" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M2.25 3h1.386c.51 0 .955.343 1.087.835l.383 1.437M7.5 14.25a3 3 0 0 0-3 3h15.75m-12.75-3h11.218c1.121-2.3 2.1-4.684 2.924-7.138a60.114 60.114 0 0 0-16.536-1.84M7.5 14.25 5.106 5.272M6 20.25a.75.75 0 1 1-1.5 0 .75.75 0 0 1 1.5 0Zm12.75 0a.75.75 0 1 1-1.5 0 .75.75 0 0 1 1.5 0Z" />
            </svg>
            {itemCount > 0 && (
              <span className="absolute -top-0.5 -right-0.5 bg-primary text-white text-[10px] font-bold w-5 h-5 rounded-full flex items-center justify-center">
                {itemCount}
              </span>
            )}
          </Link>

          {isAuthenticated ? (
            <div className="flex items-center gap-3">
              <Link href="/profile" className="text-sm font-medium text-charcoal hover:text-primary transition">
                {user?.name || 'Profile'}
              </Link>
              <button onClick={logout} className="text-sm text-text-muted hover:text-error transition">Logout</button>
            </div>
          ) : (
            <Link href="/login" className="bg-primary text-white px-4 py-2 rounded-pill text-sm font-semibold hover:bg-primary-dark transition">
              Login
            </Link>
          )}
        </div>
      </div>
    </header>
  );
}
