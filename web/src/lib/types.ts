export interface Product {
  id: string;
  name: string;
  category: string;
  unit: string;
  minPrice: number | null;
  inStock: boolean;
}

export interface ProductDetail extends Product {
  shops: ShopPrice[];
}

export interface ShopPrice {
  shopId: string;
  shopName: string;
  price: number;
  inStock: boolean;
  lat: number;
  lng: number;
  reliabilityScore: number;
}

export interface Order {
  id: string;
  status: string;
  totalAmount: number;
  items: OrderItem[];
  createdAt: string;
  etaSeconds?: number;
  assignedShop?: { shopName: string };
}

export interface OrderItem {
  id: string;
  productId: string;
  qty: number;
  unitPrice: number;
  product?: { name: string; unit: string };
}

export interface Address {
  id: string;
  label: string;
  line1: string;
  line2?: string;
  city: string;
  lat: number;
  lng: number;
  isDefault: boolean;
}

export interface User {
  id: string;
  name: string;
  phone: string;
  language: string;
}

export interface CartItem {
  productId: string;
  name: string;
  unit: string;
  price: number;
  qty: number;
}
