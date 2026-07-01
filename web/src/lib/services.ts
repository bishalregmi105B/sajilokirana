import { api, setToken } from './api';
import type { Product, ProductDetail, Order, Address, User } from './types';

export const authService = {
  requestOtp: (phone: string) =>
    api.post<{ ok: boolean; resentAfter?: number; devCode?: string }>('/auth/otp/request', { phone, role: 'customer' }),

  verifyOtp: async (phone: string, code: string) => {
    const data = await api.post<{ token: string; user: { id: string; phone: string } }>('/auth/otp/verify', { phone, code, role: 'customer' });
    setToken(data.token);
    localStorage.setItem('user', JSON.stringify(data.user));
    return data;
  },

  getProfile: () => api.get<User>('/me'),
  updateProfile: (body: Partial<User>) => api.patch<User>('/me', body),
};

export const catalogService = {
  getProducts: (params?: { category?: string; q?: string; limit?: number }) =>
    api.get<Product[]>('/catalog', params as Record<string, string | number>),

  getCategories: () => api.get<string[]>('/catalog/categories'),

  getProduct: (id: string) => api.get<ProductDetail>(`/catalog/${id}`),
};

export const ordersService = {
  create: (items: { productId: string; qty: number }[], deliveryAddress: Record<string, unknown>) =>
    api.post<Order>('/orders', { items, deliveryAddress }),

  list: () => api.get<Order[]>('/orders'),

  get: (id: string) => api.get<Order>(`/orders/${id}`),
};

export const addressService = {
  list: () => api.get<Address[]>('/me/addresses'),
  add: (body: Omit<Address, 'id' | 'isDefault'> & { isDefault?: boolean }) =>
    api.post<Address>('/me/addresses', body),
  setDefault: (id: string) => api.patch<Address>(`/me/addresses/${id}/default`),
  remove: (id: string) => api.delete(`/me/addresses/${id}`),
};
