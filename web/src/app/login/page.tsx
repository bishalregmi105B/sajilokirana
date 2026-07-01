'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/context/auth-context';

export default function LoginPage() {
  const [phone, setPhone] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const { requestOtp } = useAuth();
  const router = useRouter();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const fullPhone = `+977${phone.trim()}`;
    if (phone.trim().length < 8) { setError('Enter a valid phone number'); return; }
    setLoading(true); setError(null);
    try {
      const { resentAfter } = await requestOtp(fullPhone);
      if (resentAfter && resentAfter > 0) {
        setError(`Please wait ${resentAfter}s before retrying`);
      } else {
        router.push(`/login/verify?phone=${encodeURIComponent(fullPhone)}`);
      }
    } catch (e: any) { setError(e.message || 'Failed to send OTP'); }
    finally { setLoading(false); }
  };

  return (
    <div className="min-h-[80vh] flex items-center justify-center px-4">
      <div className="w-full max-w-sm">
        <div className="text-center mb-8">
          <div className="w-16 h-16 bg-primary rounded-2xl flex items-center justify-center mx-auto mb-4">
            <span className="text-white font-bold text-2xl">SK</span>
          </div>
          <h1 className="font-heading text-2xl font-bold text-charcoal">Welcome to SajiloKirana</h1>
          <p className="text-text-muted mt-1">Enter your phone number to continue</p>
        </div>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-charcoal mb-1">Phone number</label>
            <div className="flex">
              <span className="inline-flex items-center px-3 bg-surface-tint border border-r-0 border-border rounded-l-card text-sm text-text-muted">+977</span>
              <input type="tel" value={phone} onChange={e => setPhone(e.target.value)} placeholder="98XXXXXXXX"
                className="flex-1 px-4 py-3 border border-border rounded-r-card focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary" />
            </div>
          </div>
          {error && <p className="text-error text-sm">{error}</p>}
          <button type="submit" disabled={loading}
            className="w-full bg-primary text-white py-3 rounded-pill font-semibold hover:bg-primary-dark transition disabled:opacity-50">
            {loading ? 'Sending...' : 'Send OTP'}
          </button>
        </form>
      </div>
    </div>
  );
}
