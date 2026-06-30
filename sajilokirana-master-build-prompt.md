> **Note to Bishal — not part of the prompt itself:** Paste everything below the divider into Claude Code, Cursor, or Windsurf, pointed at your repo (with the cloned Flutter app already sitting inside it, e.g. at `/customer_app`). I kept the working name **SajiloKirana** and the terracotta/charcoal/gold palette from your investor deck so everything stays visually consistent — swap both out freely, the AI agent will follow whatever you replace them with. I grounded the ML section in real published approaches (Google/DeepMind's traffic-prediction research, Google's own OR-Tools routing library, and current retail-forecasting literature) rather than guessing — sources are listed at the very bottom for your own reference.

---

# MASTER BUILD PROMPT — SajiloKirana Platform

You are the lead full-stack engineer building **SajiloKirana**, a Nepal-based local-shop quick-commerce platform. There is an existing Flutter customer app (a Blinkit-style open-source clone) already in this repository that needs a complete UI/UX redesign. You will also build two new Flutter apps (driver, shopkeeper), a Node.js/Express backend, and a separate Python ML microservice. Work through this document in the order given in Section 8 — do not skip ahead to later parts before earlier ones are functional, since later parts depend on them.

## 0. Before You Write Any Code

1. **Audit first.** Inspect the existing Flutter app and produce `docs/AUDIT.md` listing every screen, every reusable widget, and every hardcoded `Color(...)`/`TextStyle(...)` found via search. Do not start redesigning until this exists.
2. **Research before implementing the ML and routing pieces (Part E).** Your training data may be stale on package APIs and current best practice. Before writing code for each ML sub-system, web-search the current official documentation for: Google OR-Tools' routing/pickup-delivery module, OSRM setup and its table/route services, FastAPI + LightGBM serving patterns, and any 2026 published approaches to traffic-aware ETA prediction or retail demand forecasting beyond what's specified in Section 6. Report a brief comparison of what you find before locking in an implementation.
3. Confirm current stable versions of Flutter, Node.js, Express, Prisma, FastAPI, LightGBM, and OR-Tools before pinning dependencies — do not assume versions from training data.

## 1. Repository Structure

```
/sajilokirana
  /customer_app      ← existing Flutter app (being redesigned, not rebuilt from scratch)
  /driver_app        ← new Flutter app
  /shopkeeper_app    ← new Flutter app
  /backend           ← Node.js/Express
  /ml_service        ← Python/FastAPI
  /docs
```

---

# PART A — Customer App: Full UI/UX Redesign

The existing code's *logic* (API calls, state management, routing) can largely stay — what must change is everything visual: every widget, every color, every spacing decision.

## A.1 Design System (apply everywhere, zero exceptions)

**Color tokens** — define these once in `lib/theme/app_colors.dart` and never hardcode a color anywhere else in the app:

| Token | Hex | Use |
|---|---|---|
| `primary` | `#A8442C` (terracotta) | Primary buttons, active states, brand accents |
| `primaryDark` | `#2B2D3D` (charcoal) | Headers on dark surfaces, primary text |
| `accent` | `#E8A33D` (gold) | Highlights, badges, secondary CTAs |
| `surface` | `#FFFFFF` | Backgrounds |
| `surfaceTint` | `#FBEEE8` | Cards, subtle containers |
| `textMuted` | `#6B6F7A` | Secondary text, captions |
| `success` | `#2E7D52` | Order confirmed, delivered |
| `error` | `#C0392B` | Failures, out-of-stock flags |
| `warning` | `#E8A33D` | Low stock, delays |

**Typography:** use the `google_fonts` package — headings in **Lora** (serif, matches the brand's print identity), body text in **Inter**. Define a single `AppTypography` class with named styles (`displayLarge`, `headline`, `body`, `caption`, `button`) — no screen should call `TextStyle(fontSize: ...)` directly.

**Spacing scale:** 4 / 8 / 12 / 16 / 24 / 32 (as an `AppSpacing` class of constants). **Corner radius:** 12 for cards, 24 for buttons/pills. **Elevation:** soft shadows only (`blurRadius: 8, opacity: 0.08`), never hard drop shadows.

## A.2 Audit & Refactor Process

1. Produce `docs/AUDIT.md` (Section 0).
2. Build `lib/theme/`: `app_colors.dart`, `app_typography.dart`, `app_spacing.dart`, `app_theme.dart` (a single `ThemeData` consumed via `Theme.of(context)` everywhere — no widget should define its own colors inline).
3. Replace every hardcoded color/style across the codebase with theme tokens. End state: a project-wide search for `Color(0x` or raw hex strings outside `app_colors.dart` returns zero results.
4. Build a shared component library in `lib/widgets/`, used by every screen instead of one-off styling:
   - `AppButton` (primary/secondary/text variants)
   - `AppCard`
   - `ProductCard` (image, name, price, stock badge, add-to-cart stepper)
   - `CategoryChip`
   - `SearchBar`
   - `BottomNavBar`
   - `AppBarWidget`
   - `QuantityStepper`
   - `OrderStatusBadge` (color-coded by status using semantic tokens)
   - `EmptyState` (illustration + message, for empty cart/search/orders)
   - `LoadingShimmer` (skeleton loading, not spinners)
   - `ToastNotification`
5. Redesign screen-by-screen (typical Blinkit-clone screens to expect): Splash → Onboarding → Login/OTP → Home/category feed → Search → Product detail → Cart → Checkout → Address selection → Order tracking (live map + status) → Order history → Profile → Wishlist → Notifications.
6. Add empty, loading, and error states to **every** screen — open-source clones routinely skip these; they're a UX requirement here, not optional polish.
7. **Acceptance checklist before calling this done:** zero hardcoded colors; consistent spacing scale throughout; every screen has loading/empty/error states; every button/card uses the shared widget library, not a local copy.

---

# PART B — Driver App (new Flutter build)

**Screens:** Splash → Login (OTP) → Home (online/offline toggle, current batch summary) → Active Delivery (map with ordered stop sequence, pickup markers distinct from drop-off markers) → Pickup Confirmation (mark picked up per shop; optional photo proof) → Drop Confirmation (mark delivered; optional customer-given OTP confirmation) → Earnings (daily/weekly breakdown) → Batch History → Profile/Documents.

**Key behaviors:**
- Real-time batch assignment via WebSocket (see Part D.3) — no polling.
- Background location ping every 10–15 seconds while online, sent to `POST /driver/location`.
- Local offline queue: if connectivity drops mid-delivery, cache pickup/drop confirmations locally and sync on reconnect rather than blocking the driver.
- Use the same design system as Part A.1 for visual consistency across all three apps.

---

# PART C — Shopkeeper App (new Flutter build)

**Screens:** Login (OTP) → Onboarding wizard (shop details, location pin drop, categories, seed stock for top 20 SKUs) → Dashboard (today's orders + earnings summary) → Incoming Order (accept/reject buttons with a visible countdown matching the backend's confirm window — see Part D.4) → Order Queue (accepted → preparing → ready-for-pickup) → Stock Toggle screen → Payout History → Reliability Score view (tier badge: Bronze/Silver/Gold, leaderboard position — see Part D.2).

**Stock management tiers** (don't force one UX on every shop owner):
- **Tier 1 (lowest friction):** no app screen needed — handled via the SMS/WhatsApp webhook in Part D.5.
- **Tier 2 (default app experience):** simple tap-to-toggle in-stock/out-of-stock on their own top 20–30 SKUs.
- **Tier 3 (power shops):** full catalog and price management screen.

Build the onboarding wizard to let a shopkeeper select their tier — don't assume everyone wants the full catalog UI.

---

# PART D — Backend (Node.js/Express)

## D.1 Stack

Express + **TypeScript recommended** (this domain has enough relational structure — orders, shops, drivers, batches — that types catch real bugs; plain JS is acceptable if you'd rather match your other Node services). **PostgreSQL** via **Prisma** ORM. **Redis** for dispatch confirm-window timers and caching. **Socket.io** for real-time order broadcasts, status updates, and driver location streaming.

## D.2 Data Model (Prisma schema, core entities)

```prisma
model User {
  id        String   @id @default(uuid())
  name      String
  phone     String   @unique
  language  String   @default("ne")
  addresses Address[]
  orders    Order[]
}

model Shop {
  id              String   @id @default(uuid())
  ownerName       String
  shopName        String
  phone           String
  lat             Float
  lng             Float
  categories      String[]
  onboardingTier  Int      @default(2)
  status          String   @default("active")
  reliabilityScore Float   @default(0.5)
  payoutAccount   String?
  inventory       ShopInventory[]
}

model ProductCatalog {
  id       String @id @default(uuid())
  name     String
  category String
  unit     String
}

model ShopInventory {
  shopId           String
  productId        String
  price            Float
  inStock          Boolean  @default(true)
  lastConfirmedAt  DateTime @default(now())
  shop             Shop           @relation(fields: [shopId], references: [id])
  product          ProductCatalog @relation(fields: [productId], references: [id])
  @@id([shopId, productId])
}

model Order {
  id            String   @id @default(uuid())
  customerId    String
  status        String   @default("pending") // pending, broadcasting, shop_confirmed, picked_up, in_transit, delivered, cancelled
  assignedShopId String?
  assignedDriverId String?
  batchId       String?
  etaSeconds    Int?
  createdAt     DateTime @default(now())
  items         OrderItem[]
}

model OrderItem {
  orderId   String
  productId String
  qty       Int
  unitPrice Float
  order     Order @relation(fields: [orderId], references: [id])
}

model DispatchBroadcast {
  id                 String   @id @default(uuid())
  orderId            String
  candidateShopIds   String[]
  broadcastAt        DateTime @default(now())
  confirmWindowSeconds Int    @default(40)
  winningShopId      String?
  confirmedAt        DateTime?
}

model Driver {
  id           String  @id @default(uuid())
  name         String
  phone        String  @unique
  vehicleType  String
  currentLat   Float?
  currentLng   Float?
  status       String  @default("offline") // offline, available, busy
  currentBatchId String?
}

model Batch {
  id        String   @id @default(uuid())
  driverId  String
  orderIds  String[]
  status    String   @default("assigned")
}
```

## D.3 Core API Surface

**REST:**
```
POST /auth/otp/request          { phone }
POST /auth/otp/verify           { phone, code } → { token }

GET  /catalog
GET  /shops/nearby               ?lat&lng&radius

POST /orders                     { items[], deliveryAddress }
GET  /orders/:id
PATCH /orders/:id/status

GET   /shop/orders/incoming
POST  /shop/orders/:id/accept
POST  /shop/orders/:id/reject
PATCH /shop/inventory/:productId { inStock, price? }

GET  /driver/batches/current
POST /driver/orders/:id/pickup
POST /driver/orders/:id/deliver
POST /driver/location            { lat, lng }
```

**WebSocket events:** `order:broadcast` (→ candidate shops), `order:confirmed` (→ customer + losing shops notified order is taken), `order:assigned` (→ driver), `driver:location` (→ customer tracking screen), `order:status_changed` (→ all relevant parties).

## D.4 Dispatch Engine (core business logic)

```
1. New order created → find candidate shops:
   filter by radius (start: 2km), active status, category match,
   at least one ordered item marked in_stock.
2. Call ML service: POST /ml/dispatch/score → ranked candidate shops
   (distance + reliabilityScore + recent activity — see Part E.6).
3. Broadcast order to top 3 ranked shops simultaneously
   (Socket.io event + SMS fallback for Tier-1 shops).
4. Start a 40-second confirm window (Redis TTL key).
   First shop to call /shop/orders/:id/accept wins;
   notify the other candidates the order is taken.
5. No confirmation within window → expand radius and/or broadcast
   to the next-ranked batch.
6. On confirmation → call ML service: POST /ml/routing/optimize
   to assign/batch with a driver (Part E.4).
7. On delivery completion or shop cancellation-after-confirm:
   update that shop's reliabilityScore (positive or negative signal).
   This update is the single most important rule in the system —
   it is the direct fix for the inventory-mismatch problem that
   killed comparable local-shop delivery models elsewhere.
```

## D.5 Integrations

- **Payments:** eSewa, Khalti, Fonepay — fetch their current developer docs before integrating; these APIs change.
- **SMS/Tier-1 shopkeeper fallback:** Sparrow SMS (Nepal) or Twilio WhatsApp Business API. Implement a webhook that parses replies like `OUT 14` / `IN 14` against `productId` 14 and updates `ShopInventory`.
- **Push notifications:** Firebase Cloud Messaging, for all three apps.

---

# PART E — ML Service (Python, separate microservice)

## E.1 Why Separate

Keep all ML logic isolated from the Node backend. The backend calls this service over internal HTTP; it has no direct customer-facing exposure. This also lets you iterate on models independently of the main app release cycle.

## E.2 Recommended Stack

**FastAPI** (async, auto-generated OpenAPI docs, clean integration target for the Node backend) · **scikit-learn + LightGBM/XGBoost** (forecasting and scoring) · **Google OR-Tools** (routing) · **pandas/numpy** (feature engineering) · model versioning via a simple convention (timestamped model files + a `current_model.txt` pointer is enough at this stage — don't reach for MLflow until you have a real retraining cadence to manage).

## E.3 Sub-system 1 — Traffic-Aware ETA Prediction

**What the state of the art actually looks like:** Google partnered with DeepMind to use Graph Neural Networks over road-network "Supersegments," combining live GPS signals with historical patterns, and improved ETA accuracy by up to 50% in some cities (published as *"ETA Prediction with Graph Neural Networks in Google Maps,"* arXiv:2108.11482). That result depends on a scale of live-GPS data no startup has on day one — building a GNN traffic model from scratch right now would be solving a problem you don't have the data to solve well.

**The pragmatic, phased approach:**
- **Phase 0/1 (launch):** don't build your own base travel-time model. Use the **Google Maps Platform Distance Matrix/Routes API** (already traffic-aware) or a **self-hosted OSRM** instance loaded with Nepal OpenStreetMap data (free, no live traffic, but a solid baseline) for raw travel time between two points.
- **Phase 1.5 (once you have a few months of your own delivery data):** train a lightweight **LightGBM regression model** that learns the *residual error* between the base API's prediction and your actual observed delivery times, using features like hour-of-day, day-of-week, weather, festival/holiday flags (Dashain, Tihar, etc.), and each shop's historical prep-time. This residual-correction pattern is exactly what logistics ETA providers like project44 use in production on top of base drive-time models — it's a proven, low-risk way to get most of the accuracy gain without the data requirements of a full custom traffic model.
- **Phase 3 (12+ months of your own GPS trip data):** only at this point consider a custom spatio-temporal graph model over your own road-segment graph, following the published Google/DeepMind approach. Treat this as a real research project, not an MVP task.

**API contract:**
```
POST /ml/eta/predict
{ pickup_latlng, dropoff_latlng, shop_id, order_time }
→ { eta_seconds, confidence_interval }
```

## E.4 Sub-system 2 — Multi-Drop Route Optimization (Batching)

Google OR-Tools ships a purpose-built **Pickup-and-Delivery Vehicle Routing module** — this is Google's own open-source solver for exactly this problem: multiple vehicles picking up at various locations and dropping off at others while minimizing total/longest route. Don't hand-roll a routing algorithm; use this library directly. At very low order density, the simple greedy nearest-neighbor heuristic from the earlier strategy document is fine — treat OR-Tools as the upgrade path once batching volume justifies the added complexity, not as a day-one requirement.

Feed it a distance/time matrix from either self-hosted OSRM's table service (free) or the Google Distance Matrix API (paid, more accurate with live traffic — worth it once volume justifies the cost).

**API contract:**
```
POST /ml/routing/optimize
{ driver_location, pickup_dropoff_pairs[], vehicle_capacity }
→ { ordered_stops[], total_distance, total_time }
```

## E.5 Sub-system 3 — Demand Forecasting (Shop/SKU-level)

Across multiple retail-forecasting studies, gradient-boosted trees (**LightGBM** or **XGBoost**) consistently match or beat deep-learning approaches (LSTM, Temporal Fusion Transformer, N-BEATS) at the data volumes a single-market startup will actually have, while being far cheaper to train and maintain. This is the correct default here, not a compromise — don't over-engineer this with deep learning before the gradient-boosting baseline is actually outgrown.

**Features:** lag sales (7/14/30-day), rolling averages, day-of-week, Nepali festival/holiday calendar flags, weather, price/promo flags.

**API contract:**
```
GET /ml/forecast/shop/{shop_id}/sku/{product_id}
→ { predicted_demand_next_24h, confidence }
```

Consumed by: the shopkeeper app's demand-insight nudges (the analytics-subscription revenue line from the strategy document) and the dispatch ranking (deprioritize shops statistically likely to be out of a given item soon).

## E.6 Sub-system 4 — Shop Reliability / Dispatch Scoring

**MVP:** a simple weighted formula computed directly in the backend (no ML needed yet) — `score = w1·(1/distance) + w2·reliability_score + w3·recency`. This is sufficient until you have enough labeled outcomes to learn from.

**Phase 2 upgrade:** once you have enough confirmed-and-fulfilled vs. ghosted-order outcomes, train a binary classifier (logistic regression or a LightGBM classifier) predicting `P(shop will accept-and-fulfill | order, shop, time-of-day, recent-history)`, replacing the hand-tuned formula with a learned one.

**API contract:**
```
POST /ml/dispatch/score
{ order_id, candidate_shop_ids[] }
→ { ranked_shops: [{ shop_id, score }] }
```

---

# 6. Cross-Cutting Concerns

- **Environments:** dev/staging/prod, `.env` per environment, never commit secrets.
- **Deployment:** target the existing DigitalOcean droplet setup. Dockerize `backend` and `ml_service` as separate containers; `docker-compose` for local development.
- **Logging/monitoring:** structured logs at minimum; a lightweight error tracker (self-hosted or Sentry free tier) before any real users touch the system.
- **Testing:** unit tests are non-negotiable for the dispatch engine (Part D.4) and every ML service endpoint — this is the logic a bug in would directly cause the stockout/ghosting problem this entire platform exists to fix.

# 7. Build Order — Do Not Skip Ahead

1. Backend: data model + auth + core CRUD.
2. In parallel: Customer app redesign (Part A).
3. Shopkeeper app MVP (onboarding + stock toggle + accept/reject) — needed before dispatch can be tested end-to-end.
4. Driver app MVP (batch view + pickup/drop confirmation).
5. ML service, **Phase 0/1 only**: OSRM/Google ETA passthrough (E.3), OR-Tools batching (E.4), simple weighted dispatch score (E.6). Skip the residual-correction ETA model and demand forecasting until real order data exists to train on.
6. Wire the dispatch engine end-to-end; test against the Phase-0 pilot-cluster plan from the strategy document.
7. Only after live data accumulates: train the LightGBM residual-ETA model (E.3, Phase 1.5) and the demand-forecasting model (E.5).

# 8. Final Note to the Agent

Ask Bishal before making an irreversible architectural choice not covered here (swapping Postgres for something else, choosing a specific push-notification vendor, etc.). Otherwise proceed end-to-end without pausing for confirmation at each step — this document is meant to be sufficient on its own.

---

### Research basis for Part E (for your reference, not part of the prompt)

- Google/DeepMind — "ETA Prediction with Graph Neural Networks in Google Maps," arXiv:2108.11482; DeepMind blog on traffic prediction with GNNs.
- project44 — residual-error correction layered on base drive-time models for ETA prediction.
- DoorDash engineering blog — deep learning / multi-task ETA model architectures (context on what large-scale players do, useful to know is *not* required at your stage).
- Google for Developers — OR-Tools "Vehicle Routing with Pickups and Deliveries" documentation.
- Multiple retail-forecasting comparative studies (2025–2026) showing LightGBM/XGBoost matching or beating deep learning architectures (N-BEATS, Temporal Fusion Transformer) on realistic retail SKU data volumes.
