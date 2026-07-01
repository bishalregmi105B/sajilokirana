'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { useAuth } from '@/context/auth-context';
import { authService } from '@/lib/services';

export default function ProfilePage() {
  const { isAuthenticated, user, logout, refreshProfile } = useAuth();
  const router = useRouter();
  const [name, setName] = useState('');
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (!isAuthenticated) { router.push('/login'); return; }
    if (user) setName(user.name);
  }, [isAuthenticated, user, router]);

  const saveName = async () => {
    setSaving(true);
    try {
      await authService.updateProfile({ name });
      await refreshProfile();
    } catch (_) {}
    setSaving(false);
  };

  if (!user) return null;

  return (
    <div className="max-w-lg mx-auto px-4 py-6">
      <h1 className="font-heading text-2xl font-bold mb-6">Profile</h1>

      <div className="bg-white rounded-card border border-border p-4 mb-4">
        <label className="block text-sm font-medium text-charcoal mb-1">Name</label>
        <div className="flex gap-2">
          <input type="text" value={name} onChange={e => setName(e.target.value)}
            className="flex-1 px-3 py-2 border border-border rounded-card text-sm focus:outline-none focus:ring-2 focus:ring-primary/30" />
          <button onClick={saveName} disabled={saving || name === user.name}
            className="bg-primary text-white px-4 py-2 rounded-pill text-sm font-semibold disabled:opacity-50">Save</button>
        </div>
      </div>

      <div className="bg-white rounded-card border border-border p-4 mb-4">
        <p className="text-sm"><span className="text-text-muted">Phone:</span> {user.phone}</p>
      </div>

      <div className="space-y-2">
        <Link href="/profile/addresses" className="block bg-white rounded-card border border-border p-4 hover:border-primary/50 transition">
          <div className="flex items-center justify-between">
            <span className="font-medium text-sm">Saved Addresses</span>
            <svg className="w-4 h-4 text-text-muted" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}><path strokeLinecap="round" d="m9 5 7 7-7 7" /></svg>
          </div>
        </Link>
        <Link href="/orders" className="block bg-white rounded-card border border-border p-4 hover:border-primary/50 transition">
          <div className="flex items-center justify-between">
            <span className="font-medium text-sm">Order History</span>
            <svg className="w-4 h-4 text-text-muted" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}><path strokeLinecap="round" d="m9 5 7 7-7 7" /></svg>
          </div>
        </Link>
      </div>

      <button onClick={() => { logout(); router.push('/'); }}
        className="w-full mt-6 border border-error text-error py-2.5 rounded-pill text-sm font-semibold hover:bg-error/5 transition">Logout</button>
    </div>
  );
}
