'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/context/auth-context';
import { addressService } from '@/lib/services';
import type { Address } from '@/lib/types';

export default function AddressesPage() {
  const { isAuthenticated } = useAuth();
  const router = useRouter();
  const [addresses, setAddresses] = useState<Address[]>([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState({ label: '', line1: '', city: 'Kathmandu', lat: 27.7, lng: 85.3 });

  useEffect(() => {
    if (!isAuthenticated) { router.push('/login'); return; }
    loadAddresses();
  }, [isAuthenticated, router]);

  const loadAddresses = () => {
    addressService.list().then(setAddresses).catch(() => {}).finally(() => setLoading(false));
  };

  const addAddress = async () => {
    if (!form.label || !form.line1) return;
    await addressService.add(form);
    setShowForm(false);
    setForm({ label: '', line1: '', city: 'Kathmandu', lat: 27.7, lng: 85.3 });
    loadAddresses();
  };

  const setDefault = async (id: string) => {
    await addressService.setDefault(id);
    loadAddresses();
  };

  const remove = async (id: string) => {
    await addressService.remove(id);
    loadAddresses();
  };

  return (
    <div className="max-w-lg mx-auto px-4 py-6">
      <h1 className="font-heading text-2xl font-bold mb-6">Saved Addresses</h1>

      {loading ? (
        <div className="animate-pulse space-y-3">{[1,2].map(i => <div key={i} className="h-16 bg-surface-tint rounded-card" />)}</div>
      ) : (
        <div className="space-y-3 mb-6">
          {addresses.map(addr => (
            <div key={addr.id} className={`bg-white rounded-card border p-4 ${addr.isDefault ? 'border-primary' : 'border-border'}`}>
              <div className="flex items-start justify-between">
                <div>
                  <div className="flex items-center gap-2">
                    <p className="font-semibold text-sm">{addr.label}</p>
                    {addr.isDefault && <span className="text-[10px] bg-primary/10 text-primary px-2 py-0.5 rounded-pill font-semibold">Default</span>}
                  </div>
                  <p className="text-xs text-text-muted mt-0.5">{addr.line1}, {addr.city}</p>
                </div>
                <div className="flex gap-2">
                  {!addr.isDefault && <button onClick={() => setDefault(addr.id)} className="text-xs text-primary hover:underline">Set default</button>}
                  <button onClick={() => remove(addr.id)} className="text-xs text-error hover:underline">Delete</button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {showForm ? (
        <div className="bg-white rounded-card border border-border p-4 space-y-3">
          <input type="text" placeholder="Label (e.g. Home, Office)" value={form.label} onChange={e => setForm(f => ({ ...f, label: e.target.value }))}
            className="w-full px-3 py-2 border border-border rounded-card text-sm focus:outline-none focus:ring-2 focus:ring-primary/30" />
          <input type="text" placeholder="Address line 1" value={form.line1} onChange={e => setForm(f => ({ ...f, line1: e.target.value }))}
            className="w-full px-3 py-2 border border-border rounded-card text-sm focus:outline-none focus:ring-2 focus:ring-primary/30" />
          <input type="text" placeholder="City" value={form.city} onChange={e => setForm(f => ({ ...f, city: e.target.value }))}
            className="w-full px-3 py-2 border border-border rounded-card text-sm focus:outline-none focus:ring-2 focus:ring-primary/30" />
          <div className="flex gap-2">
            <button onClick={addAddress} className="bg-primary text-white px-4 py-2 rounded-pill text-sm font-semibold">Save Address</button>
            <button onClick={() => setShowForm(false)} className="text-sm text-text-muted hover:underline">Cancel</button>
          </div>
        </div>
      ) : (
        <button onClick={() => setShowForm(true)} className="w-full border-2 border-dashed border-border rounded-card p-4 text-sm text-text-muted hover:border-primary/50 hover:text-primary transition">
          + Add New Address
        </button>
      )}
    </div>
  );
}
