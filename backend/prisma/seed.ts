/**
 * Prisma seed script (Part D.2 — seed script TODO).
 * Run:  npx prisma db seed   OR   npm run prisma:seed
 *
 * Seeds Nepal-context data for a Kathmandu pilot cluster:
 *   - 25 products (Nepal grocery staples)
 *   - 3 shops in Kathmandu with realistic inventory
 *   - 2 drivers
 *   - 2 customer accounts
 *
 * Safe to re-run: uses upsert wherever possible. Order/Batch data is NOT
 * seeded — those are created at runtime via the dispatch flow.
 */

import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import 'dotenv/config';

const adapter = new PrismaPg({ connectionString: process.env.DATABASE_URL! });
const prisma = new PrismaClient({ adapter });

// ── Products ──────────────────────────────────────────────────────────────

const PRODUCTS = [
  // Staples
  { name: 'Aata (Wheat Flour)', category: 'Staples', unit: '5kg bag' },
  { name: 'Basmati Rice', category: 'Staples', unit: '5kg bag' },
  { name: 'Masino Rice (Local)', category: 'Staples', unit: '5kg bag' },
  { name: 'Musuro Dal (Red Lentil)', category: 'Staples', unit: '500g' },
  { name: 'Chana Dal (Chickpea)', category: 'Staples', unit: '500g' },
  { name: 'Urad Dal (Black Lentil)', category: 'Staples', unit: '500g' },
  // Cooking essentials
  { name: 'Mustard Oil', category: 'Oils & Fats', unit: '1L bottle' },
  { name: 'Sunflower Oil', category: 'Oils & Fats', unit: '1L bottle' },
  { name: 'Ghiu (Ghee)', category: 'Oils & Fats', unit: '500ml' },
  // Spices
  { name: 'Himalayan Pink Salt', category: 'Spices', unit: '1kg packet' },
  { name: 'Turmeric Powder', category: 'Spices', unit: '100g' },
  { name: 'Red Chilli Powder', category: 'Spices', unit: '100g' },
  { name: 'Cumin Powder', category: 'Spices', unit: '50g' },
  { name: 'Garam Masala', category: 'Spices', unit: '50g' },
  // Dairy
  { name: 'Doodh (Full Cream Milk)', category: 'Dairy', unit: '1L pouch' },
  { name: 'Dahi (Curd)', category: 'Dairy', unit: '400g cup' },
  { name: 'Paneer', category: 'Dairy', unit: '200g block' },
  // Snacks
  { name: 'Wai Wai Noodles', category: 'Snacks', unit: '75g pack' },
  { name: 'Haldiram Aloo Bhujia', category: 'Snacks', unit: '200g pack' },
  { name: 'Biscuit (Glucose)', category: 'Snacks', unit: '100g pack' },
  // Beverages
  { name: 'Masala Tea Leaves', category: 'Beverages', unit: '250g packet' },
  { name: 'Drinking Water (Bottle)', category: 'Beverages', unit: '1L bottle' },
  // Cleaning
  { name: 'Surf Excel Detergent', category: 'Cleaning', unit: '500g box' },
  { name: 'Phenyl Floor Cleaner', category: 'Cleaning', unit: '500ml bottle' },
  // Hygiene
  { name: 'Lifebuoy Soap', category: 'Hygiene', unit: '75g bar' },
];

// ── Shops (Kathmandu pilot cluster) ───────────────────────────────────────

const SHOPS = [
  {
    ownerName: 'Ram Bahadur Shrestha',
    shopName: 'Shrestha General Store',
    phone: '+9779801234567',
    lat: 27.7034,
    lng: 85.3127,
    categories: ['Staples', 'Spices', 'Oils & Fats', 'Dairy', 'Snacks', 'Beverages'],
    onboardingTier: 2,
    reliabilityScore: 0.8,
  },
  {
    ownerName: 'Sita Maharjan',
    shopName: 'Maharjan Kirana Pasal',
    phone: '+9779807654321',
    lat: 27.7098,
    lng: 85.3180,
    categories: ['Staples', 'Snacks', 'Cleaning', 'Hygiene', 'Beverages'],
    onboardingTier: 2,
    reliabilityScore: 0.65,
  },
  {
    ownerName: 'Krishna Prasad Thapa',
    shopName: 'Thapa Bhandar',
    phone: '+9779811111222',
    lat: 27.6980,
    lng: 85.3065,
    categories: ['Staples', 'Dairy', 'Oils & Fats', 'Spices'],
    onboardingTier: 1, // SMS-only Tier-1 shop
    reliabilityScore: 0.55,
  },
];

// ── Drivers ───────────────────────────────────────────────────────────────

const DRIVERS = [
  {
    name: 'Bikash Tamang',
    phone: '+9779849001122',
    vehicleType: 'bike',
    currentLat: 27.7010,
    currentLng: 85.3150,
    status: 'available',
  },
  {
    name: 'Roshan Gurung',
    phone: '+9779849003344',
    vehicleType: 'scooter',
    currentLat: 27.7060,
    currentLng: 85.3100,
    status: 'available',
  },
];

// ── Customers ─────────────────────────────────────────────────────────────

const USERS = [
  { name: 'Anjali Karki', phone: '+9779860111222' },
  { name: 'Suresh Poudel', phone: '+9779860333444' },
];

// ── Seed runner ───────────────────────────────────────────────────────────

async function main() {
  console.log('[seed] Starting SajiloKirana seed …');

  // 1. Products — findOrCreate by name (no unique constraint, so check first).
  for (const p of PRODUCTS) {
    const existing = await prisma.productCatalog.findFirst({ where: { name: p.name } });
    if (!existing) {
      await prisma.productCatalog.create({ data: p });
    }
  }
  const allProducts = await prisma.productCatalog.findMany();
  console.log(`[seed] ${allProducts.length} products in catalog`);

  // 2. Shops
  const shopRecords: { id: string; categories: string[]; phone: string }[] = [];
  for (const s of SHOPS) {
    const shop = await prisma.shop.upsert({
      where: { phone: s.phone },
      update: {
        lat: s.lat,
        lng: s.lng,
        reliabilityScore: s.reliabilityScore,
        onboardingTier: s.onboardingTier,
      },
      create: {
        ownerName: s.ownerName,
        shopName: s.shopName,
        phone: s.phone,
        lat: s.lat,
        lng: s.lng,
        categories: s.categories,
        onboardingTier: s.onboardingTier,
        reliabilityScore: s.reliabilityScore,
      },
    });
    shopRecords.push({ id: shop.id, categories: s.categories, phone: s.phone });
  }
  console.log(`[seed] ${shopRecords.length} shops upserted`);

  // 3. Inventory — each shop stocks products that match its declared categories.
  //    Prices are realistic NPR amounts.
  const PRICE_MAP: Record<string, number> = {
    'Staples': 120,
    'Oils & Fats': 250,
    'Spices': 60,
    'Dairy': 80,
    'Snacks': 45,
    'Beverages': 30,
    'Cleaning': 150,
    'Hygiene': 55,
  };

  let inventoryCount = 0;
  for (const shop of shopRecords) {
    const matchingProducts = allProducts.filter((p) =>
      shop.categories.includes(p.category),
    );
    for (const product of matchingProducts) {
      const basePrice = PRICE_MAP[product.category] ?? 100;
      // Small per-shop variance ±10%.
      const price = Math.round(basePrice * (0.9 + Math.random() * 0.2));
      await prisma.shopInventory.upsert({
        where: { shopId_productId: { shopId: shop.id, productId: product.id } },
        update: {},
        create: {
          shopId: shop.id,
          productId: product.id,
          price,
          inStock: true,
        },
      });
      inventoryCount++;
    }
  }
  console.log(`[seed] ${inventoryCount} inventory lines upserted`);

  // 4. Drivers
  for (const d of DRIVERS) {
    await prisma.driver.upsert({
      where: { phone: d.phone },
      update: { status: d.status, currentLat: d.currentLat, currentLng: d.currentLng },
      create: d,
    });
  }
  console.log(`[seed] ${DRIVERS.length} drivers upserted`);

  // 5. Customer accounts
  for (const u of USERS) {
    await prisma.user.upsert({
      where: { phone: u.phone },
      update: {},
      create: u,
    });
  }
  console.log(`[seed] ${USERS.length} customers upserted`);

  console.log('[seed] Done ✓');
}

main()
  .catch((e) => {
    console.error('[seed] Error:', e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
