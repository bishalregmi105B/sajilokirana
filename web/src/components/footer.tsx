import Link from 'next/link';

export function Footer() {
  return (
    <footer className="bg-charcoal text-white mt-16">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
          <div>
            <div className="flex items-center gap-2 mb-4">
              <div className="w-8 h-8 bg-primary rounded-lg flex items-center justify-center">
                <span className="text-white font-bold text-sm">SK</span>
              </div>
              <span className="font-heading text-lg font-semibold">SajiloKirana</span>
            </div>
            <p className="text-sm text-white/60">Your neighborhood kirana shop, online. Order groceries from trusted local shops near you.</p>
          </div>
          <div>
            <h3 className="font-semibold text-sm mb-3">Shop</h3>
            <ul className="space-y-2 text-sm text-white/60">
              <li><Link href="/" className="hover:text-white transition">Browse Products</Link></li>
              <li><Link href="/search" className="hover:text-white transition">Search</Link></li>
              <li><Link href="/cart" className="hover:text-white transition">Cart</Link></li>
            </ul>
          </div>
          <div>
            <h3 className="font-semibold text-sm mb-3">Account</h3>
            <ul className="space-y-2 text-sm text-white/60">
              <li><Link href="/orders" className="hover:text-white transition">Orders</Link></li>
              <li><Link href="/profile" className="hover:text-white transition">Profile</Link></li>
              <li><Link href="/profile/addresses" className="hover:text-white transition">Addresses</Link></li>
            </ul>
          </div>
          <div>
            <h3 className="font-semibold text-sm mb-3">Payment Partners</h3>
            <ul className="space-y-2 text-sm text-white/60">
              <li>eSewa</li>
              <li>Khalti</li>
              <li>Fonepay</li>
              <li>Cash on Delivery</li>
            </ul>
          </div>
        </div>
        <div className="border-t border-white/10 mt-8 pt-8 text-center text-xs text-white/40">
          &copy; {new Date().getFullYear()} SajiloKirana. All rights reserved.
        </div>
      </div>
    </footer>
  );
}
