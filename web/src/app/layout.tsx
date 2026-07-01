import type { Metadata } from 'next';
import './globals.css';
import { AuthProvider } from '@/context/auth-context';
import { CartProvider } from '@/context/cart-context';
import { Header } from '@/components/header';
import { Footer } from '@/components/footer';

export const metadata: Metadata = {
  title: 'SajiloKirana - Groceries from your local kirana',
  description: 'Order groceries and daily essentials from trusted local shops near you.',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <AuthProvider>
          <CartProvider>
            <Header />
            <main className="min-h-screen">{children}</main>
            <Footer />
          </CartProvider>
        </AuthProvider>
      </body>
    </html>
  );
}
