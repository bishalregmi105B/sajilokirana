'use client';

import { useState, Suspense } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { useAuth } from '@/context/auth-context';

function VerifyForm() {
  const [code, setCode] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const { verifyOtp } = useAuth();
  const router = useRouter();
  const params = useSearchParams();
  const phone = params.get('phone') || '';

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (code.trim().length < 4) { setError('Enter the OTP code'); return; }
    setLoading(true); setError(null);
    try {
      await verifyOtp(phone, code.trim());
      router.push('/');
    } catch (e: any) { setError('Invalid or expired code'); }
    finally { setLoading(false); }
  };

  return (
    <div className="min-h-[80vh] flex items-center justify-center px-4">
      <div className="w-full max-w-sm">
        <div className="text-center mb-8">
          <h1 className="font-heading text-2xl font-bold text-charcoal">Verify OTP</h1>
          <p className="text-text-muted mt-1">Enter the code sent to {phone}</p>
        </div>
        <form onSubmit={handleSubmit} className="space-y-4">
          <input type="text" value={code} onChange={e => setCode(e.target.value)} placeholder="123456"
            className="w-full px-4 py-3 border border-border rounded-card text-center text-2xl tracking-[0.5em] focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary" />
          {error && <p className="text-error text-sm text-center">{error}</p>}
          <button type="submit" disabled={loading}
            className="w-full bg-primary text-white py-3 rounded-pill font-semibold hover:bg-primary-dark transition disabled:opacity-50">
            {loading ? 'Verifying...' : 'Verify'}
          </button>
        </form>
      </div>
    </div>
  );
}

export default function VerifyPage() {
  return <Suspense fallback={<div className="min-h-[80vh] flex items-center justify-center"><p>Loading...</p></div>}><VerifyForm /></Suspense>;
}
