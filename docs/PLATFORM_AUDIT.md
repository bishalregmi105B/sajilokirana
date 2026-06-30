# SajiloKirana — Full Platform Audit Report

**Date:** June 30, 2026  
**Repo:** https://github.com/bishalregmi105B/sajilokirana  
**Auditor:** GitHub Copilot (automated end-to-end)

---

## 1. Project Overview

SajiloKirana is a Nepal quick-commerce platform (Blinkit-model) built for the Kathmandu pilot market. It comprises **5 software components** across 3 technology stacks:

| Component | Stack | Files | Approx. Lines |
|-----------|-------|-------|---------------|
| Backend API | Node.js / Express 5.x / TypeScript / Prisma 7 | 22 `.ts` | ~1,800 |
| ML Service | Python / FastAPI | 1 `.py` | 263 |
| Customer App | Flutter / Dart | 80+ `.dart` | ~5,000 |
| Shopkeeper App | Flutter / Dart | 1 `.dart` | 682 |
| Driver App | Flutter / Dart | 1 `.dart` | 680 |

**Infrastructure:** Docker Compose (Postgres 16, Redis 7, ML service, Backend)  
**GitHub:** https://github.com/bishalregmi105B/sajilokirana — public, 3 commits, 440+ files

### 1.1 Docker Container Status

| Container | Image | Host Port | Status |
|-----------|-------|-----------|--------|
| `sajilo_postgres` | postgres:16-alpine | 5432 | ✅ healthy |
| `sajilo_redis` | redis:7-alpine | — (internal) | ✅ healthy |
| `sajilo_redis2` | redis:7-alpine | — (network alias: sajilo_redis) | ✅ running |
| `sajilo_ml` | custom Python build | 8005→8001 | ✅ running |
| `sajilo_backend` | node:20-alpine | 4001→4000 | ✅ running |

> **Port offsets:** ML service uses host port 8005 (8001 occupied by stale docker-proxy from previous session). Backend uses host port 4001 (4000 occupied similarly).

---

## 2. Backend API (`backend/`)

### 2.1 Technology Stack

| Layer | Technology | Version |
|-------|-----------|---------|
| Runtime | Node.js | 20-alpine (Docker) |
| Framework | Express | ^5.1.0 |
| Language | TypeScript | 5.9.x |
| ORM | Prisma | 7.8.0 |
| DB adapter | @prisma/adapter-pg (PrismaPg) | 7.8.0 |
| Auth | jsonwebtoken | ^9.0.2 |
| Validation | Zod | ^3.23.8 |
| Real-time | Socket.io | ^4.7.5 |
| Cache / queues | ioredis | ^5.4.1 |
| Database | PostgreSQL | 16-alpine |
| Cache | Redis | 7-alpine |

### 2.2 File Structure

```
backend/
├── Dockerfile
├── jest.config.ts
├── package.json
├── prisma.config.ts              — Prisma 7 adapter config (dotenv + PrismaPg)
├── tsconfig.json
├── tsconfig.test.json
├── prisma/
│   ├── schema.prisma             — 10 models (178 lines)
│   └── seed.ts                  — 25 products, 3 shops, 53 inventory rows, 4 users
└── src/
    ├── server.ts                 — Express + Socket.io app entry
    ├── config/
    │   ├── env.ts                — Typed env access, validates all vars at boot
    │   ├── prisma.ts             — PrismaClient singleton
    │   └── redis.ts              — ioredis client singleton
    ├── middleware/
    │   ├── auth.ts               — requireAuth + requireRole guards
    │   └── error.ts              — Central JSON error handler
    ├── routes/
    │   ├── auth.ts               — OTP request / verify
    │   ├── catalog.ts            — Products + categories
    │   ├── shops.ts              — Nearby shop discovery
    │   ├── orders.ts             — Customer order lifecycle
    │   ├── users.ts              — Profile + address management
    │   ├── shop.ts               — Shopkeeper dashboard routes
    │   ├── driver.ts             — Driver operations
    │   └── webhooks.ts           — SMS / stock inbound webhooks (265 lines)
    ├── services/
    │   ├── authService.ts        — OTP flow, JWT issuance (135 lines)
    │   └── dispatch.ts           — Dispatch engine, ML integration (404 lines)
    ├── sockets/
    │   └── realtime.ts           — Socket.io auth + room management
    ├── types/
    │   ├── auth.ts               — AuthActor type
    │   └── express.d.ts          — req.actor augmentation
    └── utils/
        ├── asyncHandler.ts       — Promise wrapper for Express handlers
        ├── errors.ts             — HttpError hierarchy (400/401/403/404/409)
        └── geo.ts                — Haversine formula + OrderStatus enum
```

### 2.3 Complete API Route Map (24 routes)

| Method | Path | Auth | Role | Description |
|--------|------|------|------|-------------|
| `GET` | `/healthz` | ✗ | — | Liveness probe → `{"ok":true}` |
| `POST` | `/auth/otp/request` | ✗ | — | Send OTP (dev: fixed `123456`) |
| `POST` | `/auth/otp/verify` | ✗ | — | Verify OTP → JWT + user object |
| `GET` | `/catalog` | ✗ | — | Products with minPrice, inStock from inventory |
| `GET` | `/catalog/categories` | ✗ | — | Distinct category array |
| `GET` | `/shops/nearby` | ✓ | any | Shops by `?lat=&lng=&radius=` with full inventory |
| `GET` | `/orders` | ✓ | customer | List authenticated user's orders |
| `POST` | `/orders` | ✓ | customer | Create order → triggers dispatch engine |
| `GET` | `/orders/:id` | ✓ | customer | Single order with items array |
| `PATCH` | `/orders/:id/status` | ✓ | customer | Update status (e.g. cancel) |
| `GET` | `/me` | ✓ | any | User profile |
| `PATCH` | `/me` | ✓ | any | Update name / language |
| `GET` | `/me/addresses` | ✓ | customer | List addresses |
| `POST` | `/me/addresses` | ✓ | customer | Create address (first → isDefault=true) |
| `PATCH` | `/me/addresses/:id/default` | ✓ | customer | Set default address |
| `DELETE` | `/me/addresses/:id` | ✓ | customer | Soft-delete address |
| `GET` | `/shop/orders/incoming` | ✓ | shop | DispatchBroadcast queue for shopkeeper |
| `POST` | `/shop/orders/:id/accept` | ✓ | shop | Accept order — Redis atomic first-win |
| `POST` | `/shop/orders/:id/reject` | ✓ | shop | Decline broadcast |
| `PATCH` | `/shop/inventory/:productId` | ✓ | shop | Update price / inStock |
| `GET` | `/driver/batches/current` | ✓ | driver | Active batch or null |
| `POST` | `/driver/orders/:id/pickup` | ✓ | driver | status → picked_up, assigns driver+batch |
| `POST` | `/driver/orders/:id/deliver` | ✓ | driver | status → delivered, updates reliability |
| `POST` | `/driver/location` | ✓ | driver | Stream GPS, emits socket event |
| `POST` | `/webhooks/stock` | ✗ (signed) | — | Tier-1 SMS stock update webhook |

### 2.4 Auth System

| Aspect | Detail |
|--------|--------|
| Algorithm | HS256 JWT (jsonwebtoken) |
| Payload | `{sub: id, phone, role: 'customer'\|'shop'\|'driver'}` |
| Expiry | 7 days |
| OTP TTL | 5 minutes in Redis |
| Resend cooldown | 30 seconds |
| Dev mode | `OTP_USE_FIXED=true`, fixed code `123456` |
| Guard middleware | `requireAuth` extracts Bearer, `requireRole()` enforces role |
| `req.actor` | `{id, phone, role}` — injected by `requireAuth` |

> **Note:** Shop and Driver JWT `sub` is their own model ID (not User ID). OTP is single-use — deleted from Redis on first successful verify.

### 2.5 Dispatch Engine (`services/dispatch.ts`, 404 lines)

The core platform logic. Full flow:

1. **`findCandidates(order)`** — DB query: active shops within `DISPATCH_INITIAL_RADIUS_KM` (default 2 km) that have every ordered item in stock. Returns `CandidateShop[]` with `{id, distanceKm, reliabilityScore, recentActivity, lat, lng}`.

2. **`rankWithMl(shops, orderLat, orderLng)`** — POST to ML service with:
   ```json
   {
     "order_lat": 27.717, "order_lng": 85.314,
     "candidates": [{"id":"...","lat":27.703,"lng":85.312,"reliability":0.8,"seconds_since_last":1800}]
   }
   ```
   Falls back to **local weighted formula** if ML times out (2 s timeout).

3. **Broadcast** — Top-N (default 3) shops receive Socket.io `order:broadcast` event. SMS fallback for Tier-1 shops via Sparrow/Twilio.

4. **Confirm window** — Redis key set with 40 s TTL.

5. **`acceptOrder(orderId, shopId)`** — `redis.getdel(CONFIRM_KEY)` — atomic first-accept-wins. Returns `{won: true}` to winner.

6. **`updateReliability(shopId, outcome)`** — Bayesian smoothing after each delivery/cancellation:
   $$\text{score}_\text{new} = \text{score}_\text{old} \times 0.9 + \text{outcome} \times 0.1$$

**Local scoring formula (fallback):**
$$\text{score} = 0.5 \cdot \frac{1}{d_{\text{km}}} + 0.3 \cdot r + 0.2 \cdot \frac{\min(\text{activity},10)}{10}$$

### 2.6 Real-time Events (Socket.io)

Clients authenticate via handshake `auth.token` (JWT). Auto-join rooms on connect.

| Event | Direction | Room(s) | Trigger |
|-------|-----------|---------|---------|
| `order:broadcast` | server → shop | `shop:<id>` | New dispatch broadcast |
| `order:confirmed` | server → customer + rejected shops | `customer:<id>`, `shop:<id>` | Shop accepts |
| `order:assigned` | server → driver | `driver:<id>` | Driver assigned to batch |
| `driver:location` | server → customer | `order:<id>` | Driver GPS ping |
| `order:status_changed` | server → all | `order:<id>` | Any status change |

Rooms: `shop:<id>`, `driver:<id>`, `customer:<id>`, `order:<id>`

### 2.7 Database Schema (10 Prisma Models)

| Model | Key Fields | Notes |
|-------|-----------|-------|
| `User` | id, name, phone `@unique`, language | Parent for Address[], Order[] |
| `Address` | id, userId, label, line1, city, lat, lng, isDefault | Soft-deletable |
| `Shop` | id, phone `@unique`, lat, lng, categories[], reliabilityScore, onboardingTier | `phone @unique` added this session |
| `ProductCatalog` | id, name, category, unit | Global product catalogue |
| `ShopInventory` | shopId+productId (composite PK), price, inStock, lastConfirmedAt | Per-shop pricing |
| `Order` | id, customerId, shopId, driverId, status, deliveryAddress (JSON), totalAmount, etaSeconds | deliveryAddress is inline JSON, not FK |
| `OrderItem` | id, orderId, productId, qty, unitPrice | Snapshot pricing at order time |
| `DispatchBroadcast` | id, orderId, candidateShopIds[], confirmWindowSeconds, winningShopId | Dispatch record |
| `Driver` | id, phone `@unique`, vehicleType, currentLat/Lng, status, reliabilityScore | |
| `Batch` | id, driverId, orderIds[], status | Groups orders per driver trip |

**Order status lifecycle:**
```
pending → broadcasting → shop_confirmed → picked_up → in_transit → delivered
                                                                  ↘ cancelled
```

### 2.8 Seed Data

| Category | Products |
|----------|---------|
| Staples | Aata, Basmati Rice, Masino Rice, Musuro Dal, Chana Dal, Urad Dal |
| Oils & Fats | Mustard Oil, Sunflower Oil, Ghiu |
| Spices | Himalayan Pink Salt, Turmeric, Red Chilli, Cumin, Garam Masala |
| Dairy | Doodh, Dahi, Paneer |
| Snacks | Wai Wai, Haldiram, Biscuit |
| Beverages | Masala Tea, Drinking Water |
| Cleaning | Surf Excel, Phenyl |
| Hygiene | Lifebuoy Soap |

Shops: **Shrestha General Store**, **Maharjan Kirana Pasal**, **Thapa Bhandar** — all in Kathmandu (27.70–27.71°N, 85.30–85.32°E)  
Drivers: 2 seeded · Customers: 2 seeded · Inventory rows: 53

### 2.9 Environment Variables

| Variable | Dev Default | Purpose |
|----------|------------|---------|
| `DATABASE_URL` | required | Postgres connection string |
| `REDIS_URL` | required | Redis connection string |
| `JWT_SECRET` | required | HS256 signing key |
| `OTP_USE_FIXED` | `true` | Enable fixed dev OTP |
| `OTP_FIXED_CODE` | `123456` | Fixed dev OTP value |
| `ML_SERVICE_URL` | `""` | ML service base URL |
| `DISPATCH_CONFIRM_WINDOW_SECONDS` | `40` | Shop accept window duration |
| `DISPATCH_INITIAL_RADIUS_KM` | `2` | Candidate shop search radius |
| `DISPATCH_TOP_N_CANDIDATES` | `3` | Max shops in one broadcast |
| `SPARROW_SMS_TOKEN` | `""` | Nepal Sparrow SMS gateway |
| `ESEWA_MERCHANT_ID` | `""` | eSewa payment stub |
| `KHALTI_SECRET_KEY` | `""` | Khalti payment stub |
| `FONEPAY_*` | `""` | FonePay payment stub |
| `FCM_SERVER_KEY` | `""` | Push notification stub |

---

## 3. ML Service (`ml_service/`)

### 3.1 Stack

| | |
|-|-|
| Language | Python 3.12 |
| Framework | FastAPI |
| Server | uvicorn |
| Data validation | pydantic v2 |
| HTTP client | httpx (async) |
| Math | numpy |
| VRP solver | OR-Tools 9.9.3963 (installed, reserved for Phase 1) |
| Routing | OSRM (live: `http://router.project-osrm.org`) |

### 3.2 Endpoints (5 total)

#### `GET /healthz`
```json
{"status": "ok", "service": "ml"}
```

#### `POST /ml/dispatch/score`
**Input:**
```json
{
  "order_lat": 27.7172,
  "order_lng": 85.314,
  "candidates": [
    {"id": "uuid", "lat": 27.703, "lng": 85.312, "reliability": 0.8, "seconds_since_last": 1800}
  ],
  "weights": {"distance": 0.5, "reliability": 0.3, "recency": 0.2}
}
```
**Output:**
```json
{"ranked": [{"id": "uuid", "score": 0.566, "distance_km": 1.591}]}
```
**Algorithm:** Weighted scoring —
$$\text{score} = w_d \cdot \frac{1}{d_{\text{km}}} + w_r \cdot r + w_t \cdot \frac{1}{1 + t/3600}$$

#### `POST /ml/routing/optimize`
**Input:**
```json
{"driver_lat": 27.72, "driver_lng": 85.32, "stops": [{"id":"s1","lat":27.703,"lng":85.312}]}
```
**Output:**
```json
{"ordered_stop_ids": ["s1"], "estimated_total_km": 1.485}
```
**Algorithm:** Greedy nearest-neighbour TSP. OR-Tools VRP solver is the Phase 1 upgrade.

#### `POST /ml/eta/predict`
**Input:**
```json
{"from_lat": 27.703, "from_lng": 85.312, "to_lat": 27.717, "to_lng": 85.314}
```
**Output:**
```json
{"eta_seconds": 309, "distance_km": 3.979, "source": "osrm"}
```
**Algorithm:** OSRM live routing API, haversine ÷ 20 km/h fallback on timeout.

#### `GET /ml/forecast/shop/{shop_id}/sku/{product_id}`
**Output:**
```json
{
  "shop_id": "uuid",
  "product_id": "uuid",
  "predicted_demand_next_24h": 17.58,
  "confidence": 0.35,
  "model_version": "heuristic-v0"
}
```
**Algorithm:** Phase 0 heuristic — `base(20) ± random(0–10)`. ML model injection point for Phase 1.

---

## 4. Customer App (`customer_app/`)

### 4.1 Stack

| Layer | Technology | Version |
|-------|-----------|---------|
| Framework | Flutter | ≥ 3.0.5 |
| Package name | `ecom` | — |
| State management | Provider (`ChangeNotifier`) | ^6.0.5 |
| HTTP client | Dio | ^5.3.0 |
| Token storage | flutter_secure_storage | ^9.2.4 |
| Real-time | socket_io_client | ^2.0.3+1 |
| Animations | Lottie | ^3.1.0 |
| Loading states | shimmer | ^3.0.0 |
| Fonts | google_fonts (Lora + Inter) | ^6.2.1 |
| SVG | flutter_svg | ^2.0.7 |
| Toasts | fluttertoast | ^8.2.8 |
| PDF | pdfx | ^2.6.0 |
| Share | share_plus | ^7.0.2 |

### 4.2 Architecture

```
lib/
├── main.dart               — MultiProvider root (4 providers) + MaterialApp
├── route_generator.dart    — AppRouter.generateRoute, ScalePageRoute transitions
├── constants.dart          — Currency (रु), dial code (+977), dummy data, festival calendar
│
├── theme/                  — Design system (single source of truth)
│   ├── app_colors.dart     — 14 color tokens
│   ├── app_typography.dart — Lora (heading) / Inter (body) text styles
│   ├── app_spacing.dart    — xs/sm/md/lg/xl/xxl constants
│   └── app_theme.dart      — ThemeData builder (AppTheme.light)
│
├── Services/
│   ├── Providers/          — ChangeNotifier state classes (4)
│   └── Exceptions/
│       └── api_exception.dart
│
├── services/               — Dio-backed API clients (5)
│
├── Screens/                — 19 screens
├── widgets/                — 14 design-system widgets
└── UI/Widgets/             — 22 legacy atomic / organism widgets
```

### 4.3 State Providers

| Provider | State Held | Key Methods |
|---------|-----------|-------------|
| `AuthProvider` | `AuthState` enum, token, user | `_init()` (token restore on boot), `requestOtp()`, `verifyOtp()`, `logout()`, `refreshProfile()` |
| `CartProvider` | `Map<String, CartItem>`, subtotal, fees | `addItem()`, `setQty()`, `removeItem()`, `clear()`, `toOrderItem()` |
| `CatalogProvider` | products[], categories[], search results | `load()`, `search()` (350ms debounce), `filterByCategory()`, `byCategory()`, `refresh()` |
| `OrdersProvider` | orders[], loading, error | `load()`, `fetchOne(orderId)`, `placeOrder()` |

**Cart pricing logic:** Free delivery if subtotal > रु1,500; otherwise रु50 fee.

### 4.4 Service Layer

| Service | API Methods | Backend Endpoints |
|---------|-------------|------------------|
| `ApiClient` | `get()`, `post()`, `patch()`, `delete()` | Auto-injects Bearer token; normalizes errors → `ApiException` |
| `AuthApiService` | `requestOtp()`, `verifyOtp()`, `getSavedToken()`, `logout()`, `getProfile()`, `updateProfile()` | `/auth/otp/*`, `/me` |
| `CatalogService` | `fetchProducts()`, `fetchCategories()`, `fetchNearbyShops()` | `/catalog`, `/catalog/categories`, `/shops/nearby` |
| `AddressService` | `fetchAddresses()`, `addAddress()`, `setDefault()`, `deleteAddress()` | `/me/addresses` |
| `OrdersService` | `createOrder()`, `fetchOrders()`, `fetchOrder(id)` | `/orders` |

### 4.5 All Screens

| # | Screen Class | Route | API Connected | Description |
|---|-------------|-------|--------------|-------------|
| 1 | `LoginScreen` | `/` | `AuthProvider.requestOtp()` | Phone input, +977 prefix |
| 2 | `OTPVerificationScreen` | `/otp/verify` | `AuthProvider.verifyOtp()` | 6-digit PIN, 60 s resend timer |
| 3 | `OnboardingScreen` | `/onboarding` | — | Static onboarding slides |
| 4 | `HomeScreen` | `/home` | `CatalogProvider` | 4-tab shell — Home / Search / Orders / Profile |
| 5 | `SearchScreen` | `/search` | `CatalogProvider.search()` | 350 ms debounced real-time search |
| 6 | `ProductsScreen` | `/products` | `CatalogProvider.filterByCategory()` | Category-filtered product grid |
| 7 | `ProductDetailScreen` | `/product/detail` | `CartProvider` | Full page, qty stepper, out-of-stock guard |
| 8 | `CouponsSelectionScreen` | `/coupons` | — (dummy) | `kDummyCoupons` list display |
| 9 | `CartGiftScreen` | `/cart/gift` | — | Gift option screen |
| 10 | `CartScreen` | `/cart` | `CartProvider` + `OrdersProvider` | Bill summary, place order |
| 11 | `OrderConfirmationScreen` | `/order/confirm` | — | Lottie animation, auto-navigate /home after 5 s |
| 12 | `OrderSummaryScreen` | `/order` | `OrdersProvider.fetchOne()` | Order detail + "Track Order" CTA |
| 13 | `OrderTrackingScreen` | `/order/track` | `OrdersProvider.fetchOne()` | 15 s polling, ETA countdown, status timeline |
| 14 | `ViewOrderInvoiceScreen` | `/order/invoice` | — | PDF viewer (pdfx) |
| 15 | `OrdersScreen` | `/orders` | `OrdersProvider.load()` | Order history, RefreshIndicator |
| 16 | `UserAddressScreen` | `/user/address` | `AddressService` | List / add / set-default / delete addresses |
| 17 | `ProfileScreen` | `/profile` | `AuthProvider` | User info, logout |
| 18 | `WishlistScreen` | `/wishlist` | — (stub) | Empty wishlist placeholder |
| 19 | `NotificationsScreen` | `/notifications` | — (stub) | Placeholder |
| — | `AppAboutScreen` | `/app/about` | — | Static brand info |
| — | `ErrorScreem` | (default) | — | Named route fallback |

### 4.6 Widget Library

**Design-system widgets (`lib/widgets/`, 14 widgets):**

| Widget | Description |
|--------|-------------|
| `AppButton` | Primary / secondary / outline button variants |
| `AppCard` | Rounded card with consistent elevation |
| `AppTextField` | Styled text input with error state |
| `AppSearchBar` | Search input, autofocus param |
| `AppBarWidget` | Consistent AppBar with back/close |
| `AppListTile` | List tile with leading/trailing tokens |
| `BottomNavBar` | 4-tab `AppNavTab` navigation bar |
| `CategoryChip` | Horizontally scrollable category filter |
| `EmptyState` | Icon + heading + body placeholder |
| `LoadingShimmer` | Shimmer skeleton loader |
| `OrderStatusBadge` | Coloured badge per order status |
| `ProductCard` | Product grid card with add-to-cart |
| `QuantityStepper` | ─ / + qty control |
| `ToastNotification` | Contextual toast helper |

**Legacy widgets (`lib/UI/Widgets/`):**  
22 widgets (Atoms: AddToCartButton, CardProduct, CardProductCartScreen, CardProductOrderSummary, CategoryWidget, CustomButton, CustomTextField, + 10 others; Organisms: BottomCartContainer, CardApplyCoupon, HomeScreenAppBar, HomeScreenCarousel, CategoryWithProducts, + 5 others).

### 4.7 Design Tokens

| Token | Value | Use |
|-------|-------|-----|
| `AppColors.primary` | `#A8442C` (Terracotta) | Buttons, active states |
| `AppColors.primaryDark` | `#2B2D3D` (Charcoal) | Headers, primary text |
| `AppColors.accent` | `#E8A33D` (Gold) | Highlights, badges |
| `AppColors.surface` | `#FFFFFF` | Backgrounds |
| `AppColors.surfaceTint` | `#FBEEE8` | Cards, containers |
| `AppColors.success` | `#2E7D52` | Delivered, confirmed |
| `AppColors.error` | `#C0392B` | Failures, out-of-stock |
| `AppColors.warning` | `#E8A33D` | Low stock, delays |
| `AppColors.border` | `#E7E5E2` | Dividers |
| `AppColors.textMuted` | `#6B6F7A` | Secondary text |
| `appCurrencySymbol` | `रु` | All price displays |
| `appDialCode` | `+977` | Phone input prefix |
| Heading font | Lora (serif) | All display/headline styles |
| Body font | Inter (sans-serif) | All body/caption styles |
| `AppSpacing.xs/sm/md/lg/xl/xxl` | 4/8/12/16/24/32 px | All layout spacing |

### 4.8 Route Transitions

All routes use `ScalePageRoute` (custom `PageRouteBuilder`):
- **center** — scale from center (default, most screens)
- **leftToRight** — slide from left (back navigation)
- **rightToLeft** — slide from right (forward navigation)

Transition duration: 300 ms.

### 4.9 Feature Flags / Constants

| Constant | Value | Purpose |
|----------|-------|---------|
| `apiBaseUrl` | `http://10.0.2.2:4000` | Android emulator → host; overridable via `--dart-define=API_BASE_URL=...` |
| `kDummyProducts` | 25 Nepali product names | Search suggest fallback (unused now — real backend wired) |
| `kCategoriesTitles` | 20 categories | UI category chips |
| `kDummyCoupons` | 5 coupons | Coupons screen display |
| `kFestivalCalendar` | 8 festivals | Demand forecasting feature flags, in-app banners |

---

## 5. Shopkeeper App (`shopkeeper_app/`)

**Single file:** `shopkeeper_app/lib/main.dart` — **682 lines**

| Screen | Class | Description |
|--------|-------|-------------|
| Login | `ShopLoginScreen` | Phone + OTP auth flow |
| Home shell | `ShopHomeScreen` | `NavigationBar` with 4 tabs |
| Orders | `ShopOrdersScreen` | Incoming broadcast queue — Accept (green) / Reject (red) per order, 40 s countdown |
| Inventory | `ShopInventoryScreen` | Product list with in-stock toggle, tier badge (SMS Tier-1 / App Tier-2) |
| Reliability | `ShopReliabilityScreen` | Score display — Bronze (<0.6) / Silver (<0.8) / Gold |
| Payouts | `ShopPayoutsScreen` | Payout history stub |
| Onboarding | `ShopOnboardingScreen` | 3-step wizard (Tier 1 → 2 → 3 upgrade) |

> ⚠️ **All screens use local mock data.** Backend is architecturally ready (JWT `role: 'shop'`) but HTTP calls are not yet wired. The accept/reject countdown timer in `ShopOrdersScreen` matches the backend's 40 s Redis confirm window.

---

## 6. Driver App (`driver_app/`)

**Single file:** `driver_app/lib/main.dart` — **680 lines**

| Screen | Class | Description |
|--------|-------|-------------|
| Login | `DriverLoginScreen` | Phone + OTP auth flow |
| Home | `DriverHomeScreen` | Online / Offline toggle, current batch info, earnings summary |
| Active delivery | `ActiveDeliveryScreen` | Stop-by-stop sequence — Pickup → Deliver each stop with GPS display |
| Earnings | `EarningsScreen` | Today's and weekly earnings breakdown |
| Batch history | `BatchHistoryScreen` | Past batch records list |

> ⚠️ **All screens use local mock data.** Backend is architecturally ready (JWT `role: 'driver'`) but HTTP calls are not yet wired.

---

## 7. Infrastructure

### 7.1 Docker Compose (`docker-compose.yml`)

```
services:
  sajilo_postgres   — postgres:16-alpine, port 5432:5432, named volume
  sajilo_redis      — redis:7-alpine, internal only (no host port mapping)
  sajilo_ml         — custom Python build, port 8005:8001
  sajilo_backend    — node:20-alpine, port 4001:4000
```

**Docker network:** `sajilo_net` (bridge). `sajilo_redis2` is a temporary workaround container created to fix Redis hostname resolution for the backend container (`--network-alias sajilo_redis`).

### 7.2 Backend Dockerfile

```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npx prisma generate
RUN npm run build
CMD ["node", "dist/server.js"]
```

### 7.3 ML Service Dockerfile

```dockerfile
FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8001"]
```

> ⚠️ Healthcheck uses `curl` which is not installed in `python:3.12-slim`. Container shows "unhealthy" in `docker compose ps` despite endpoint working correctly. Fix: replace healthcheck with a Python-based check or `apt-get install curl`.

---

## 8. Test Coverage

### 8.1 Backend Unit Tests (`backend/tests/`)

| Test file | Functions tested |
|-----------|----------------|
| `dispatch.test.ts` | `scoreCandidate`, `rankCandidates`, `updateReliability`, `haversineKm` |

> ⚠️ `dispatch.test.ts` `makeShop()` fixture is missing the `lat` and `lng` fields that were added to the `CandidateShop` interface during the ML integration fix. Tests will fail to compile until the fixture is updated.

### 8.2 Customer App Tests

`customer_app/test/widget_test.dart` — default Flutter counter widget test (not updated for SajiloKirana).

### 8.3 Manually Verified API Calls (All Passing ✅)

| Route | Verified Response |
|-------|-----------------|
| `GET /healthz` | `{"ok":true}` |
| `POST /auth/otp/request` | `{"ok":true,"devCode":"123456"}` |
| `POST /auth/otp/verify` | `{"token":"eyJ...","user":{"id":"...","phone":"..."}}` |
| `GET /catalog` | Array of 25 products with minPrice/inStock |
| `GET /catalog/categories` | `["Beverages","Cleaning","Dairy","Hygiene","Oils & Fats","Snacks","Spices","Staples"]` |
| `GET /shops/nearby?lat=27.7034&lng=85.3127&radius=5` | 3 shops with full inventory |
| `POST /orders` | Order created, status=pending → broadcasting |
| `GET /orders` | Order list |
| `GET /orders/:id` | Order detail with items |
| `PATCH /orders/:id/status` | Updated status |
| `GET /me` | User profile |
| `PATCH /me` | Updated profile |
| `POST /me/addresses` | New address |
| `GET /me/addresses` | Address list |
| `PATCH /me/addresses/:id/default` | Default set |
| `DELETE /me/addresses/:id` | Soft-deleted |
| `GET /shop/orders/incoming` | Broadcast queue |
| `POST /shop/orders/:id/accept` | `{"won":true}` |
| `POST /shop/orders/:id/reject` | `{"ok":true}` |
| `PATCH /shop/inventory/:productId` | Updated inventory row |
| `GET /driver/batches/current` | `null` (no active batch) |
| `POST /driver/orders/:id/pickup` | status=picked_up |
| `POST /driver/orders/:id/deliver` | status=delivered |
| `POST /driver/location` | `{"ok":true}` |
| `POST /ml/dispatch/score` | Ranked candidates with scores |
| `POST /ml/routing/optimize` | Ordered stop IDs + total km |
| `POST /ml/eta/predict` | `{"eta_seconds":309,"distance_km":3.979,"source":"osrm"}` |
| `GET /ml/forecast/shop/.../sku/...` | Predicted demand 24h |
| `GET /ml/healthz` | `{"status":"ok","service":"ml"}` |

---

## 9. Issues & Gaps

### 🔴 Critical

| # | Issue | Location | Required Fix |
|---|-------|----------|-------------|
| 1 | `dispatch.test.ts` `makeShop()` missing `lat`/`lng` — TypeScript will not compile tests | `backend/tests/dispatch.test.ts:36` | Add `lat: 27.7, lng: 85.3` to the fixture |
| 2 | ML Docker healthcheck uses `curl` (not installed in slim image) — false "unhealthy" status | `docker-compose.yml` ml healthcheck | Replace with `CMD ["python","-c","import urllib.request; urllib.request.urlopen('http://localhost:8001/healthz')"]` |

### 🟡 Medium

| # | Issue | Location | Impact |
|---|-------|----------|--------|
| 3 | Shopkeeper app — no backend HTTP calls, all mock data | `shopkeeper_app/lib/main.dart` | Shopkeeper cannot use real orders or inventory |
| 4 | Driver app — no backend HTTP calls, all mock data | `driver_app/lib/main.dart` | Driver cannot receive or act on real batches |
| 5 | `apiBaseUrl` hardcoded to `10.0.2.2:4000` — fails on physical device / iOS sim | `customer_app/lib/constants.dart:10` | Use `--dart-define=API_BASE_URL=` at build time |
| 6 | Payments (eSewa, Khalti, Fonepay) are env-var stubs only | `backend/.env.example` | No payment processing implemented |
| 7 | Push notifications (FCM) are env-var stubs only | `backend/.env.example` | No push delivery |
| 8 | SMS delivery uses console log in dev — Sparrow/Twilio not called | `backend/src/services/authService.ts` | OTPs only viewable in container logs |
| 9 | `POST /orders` `deliveryAddress` must be inline JSON object, not address ID | `backend/src/routes/orders.ts` | Flutter `OrdersService.createOrder()` must serialize the full address object |
| 10 | `stale docker-proxy` leaves port 4000/8001 occupied across reboots | Docker daemon | `docker system prune` and restart daemon to clear |

### 🟢 Low / Cosmetic

| # | Issue | Location |
|---|-------|----------|
| 11 | `WishlistScreen` and `NotificationsScreen` are empty placeholders | Customer app |
| 12 | Shopkeeper + Driver apps are single 680-line monolithic files | Both satellite apps |
| 13 | `kDummyProducts` list in `constants.dart` unused (real catalog now available) | `constants.dart` |
| 14 | `cart_gift_screen.dart` has no gift logic | Customer app |
| 15 | `ErrorScreem` class has a typo in its name | `customer_app/lib/Screens/error_screen.dart` |
| 16 | `coupons_screeen.dart` filename has a double-e typo | `customer_app/lib/Screens/` |
| 17 | `customer_app/test/widget_test.dart` — default Flutter counter test, not updated | `customer_app/test/` |

---

## 10. What's Implemented vs. Planned

| Feature | Status |
|---------|--------|
| OTP auth for all 3 roles | ✅ Complete |
| Product catalog API | ✅ Complete |
| Nearby shop discovery | ✅ Complete |
| Customer order placement | ✅ Complete |
| Dispatch engine (ML-ranked) | ✅ Complete |
| Shop accept / reject (atomic) | ✅ Complete |
| Driver pickup + deliver | ✅ Complete |
| Driver GPS streaming | ✅ Complete |
| Order tracking (poll + socket) | ✅ Complete |
| Address CRUD | ✅ Complete |
| Customer Flutter app (API-connected) | ✅ Complete |
| ML dispatch scoring | ✅ Complete |
| ML route optimization (TSP) | ✅ Complete |
| ML ETA prediction (OSRM live) | ✅ Complete |
| ML demand forecast (heuristic) | ✅ Stub (Phase 1: real model) |
| SMS OTP delivery | ⚠️ Console only |
| Push notifications (FCM) | ❌ Not implemented |
| eSewa payment | ❌ Not implemented |
| Khalti payment | ❌ Not implemented |
| Shopkeeper app HTTP integration | ❌ Mock only |
| Driver app HTTP integration | ❌ Mock only |
| OR-Tools VRP routing | 🔲 Phase 1 |
| ML demand forecasting model | 🔲 Phase 1 |
| Admin dashboard | 🔲 Not started |
| Shop tier upgrade flow | 🔲 UI only |
| Coupon redemption backend | 🔲 Not started |

---

## 11. Key Architecture Decisions

| Decision | Rationale |
|----------|-----------|
| Prisma 7 with `@prisma/adapter-pg` (no `url` in datasource) | Required by Prisma 7's driver adapter architecture — `prisma.config.ts` handles connection |
| `deliveryAddress` as JSON field, not FK | Order snapshots delivery location at creation time; address can later be deleted |
| Redis `GETDEL` for accept-race | Atomic — exactly one shop wins even under concurrent accepts |
| 2 s ML timeout with local fallback | Keeps p95 order-creation latency bounded regardless of ML service health |
| `req.actor` pattern (not `req.user`) | Avoids naming collision with Passport.js conventions, works for all 3 roles |
| Single Flutter file for shopkeeper + driver | Expedient for MVP; intended to be split into proper screen modules in Phase 1 |
| `OTP_USE_FIXED=true` in dev | Eliminates SMS cost and Sparrow API dependency during development |
| `prisma db push` requires `--url` flag inside Docker | node_modules installed by Alpine root user with musl engines; env var resolution differs |

---

*End of audit. Generated by automated end-to-end analysis on 2026-06-30.*
