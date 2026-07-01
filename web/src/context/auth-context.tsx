'use client';

import { createContext, useContext, useState, useEffect, useCallback, type ReactNode } from 'react';
import { authService } from '@/lib/services';
import { clearToken } from '@/lib/api';
import type { User } from '@/lib/types';

interface AuthCtx {
  user: User | null;
  isLoading: boolean;
  isAuthenticated: boolean;
  requestOtp: (phone: string) => Promise<{ resentAfter?: number }>;
  verifyOtp: (phone: string, code: string) => Promise<void>;
  logout: () => void;
  refreshProfile: () => Promise<void>;
}

const AuthContext = createContext<AuthCtx | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const token = localStorage.getItem('authToken');
    if (token) {
      authService.getProfile()
        .then(setUser)
        .catch(() => { clearToken(); })
        .finally(() => setIsLoading(false));
    } else {
      setIsLoading(false);
    }
  }, []);

  const requestOtp = useCallback(async (phone: string) => {
    const res = await authService.requestOtp(phone);
    return { resentAfter: res.resentAfter };
  }, []);

  const verifyOtp = useCallback(async (phone: string, code: string) => {
    const data = await authService.verifyOtp(phone, code);
    const profile = await authService.getProfile();
    setUser(profile);
  }, []);

  const logout = useCallback(() => {
    clearToken();
    setUser(null);
  }, []);

  const refreshProfile = useCallback(async () => {
    const profile = await authService.getProfile();
    setUser(profile);
  }, []);

  return (
    <AuthContext.Provider value={{ user, isLoading, isAuthenticated: !!user, requestOtp, verifyOtp, logout, refreshProfile }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be inside AuthProvider');
  return ctx;
}
