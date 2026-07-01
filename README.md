# SajiloKirana 🛒

Nepal-based local-shop quick-commerce platform — Blinkit-style delivery from neighbourhood kiranas.

## Architecture

```
/sajilokirana
  /customer_app      Flutter — customer-facing app (Android/iOS)
  /driver_app        Flutter — driver app
  /shopkeeper_app    Flutter — shopkeeper portal
  /backend           Node.js/Express/TypeScript + Prisma + PostgreSQL + Redis
  /ml_service        Python/FastAPI — dispatch scoring, routing, ETA, demand forecast
  /docs              AUDIT.md, COMPONENT_SPEC.md
```

## Quick Start

### Prerequisites
- Docker + Docker Compose
- Flutter ≥ 3.22
- Node.js ≥ 22

### 1. Start infrastructure
```bash
docker compose up -d          # Postgres + Redis + ML service
```

### 2. Backend
```bash
cd backend
cp .env.example .env          # edit DATABASE_URL, JWT_SECRET, etc.
npm install
npx prisma migrate dev
npx prisma db seed            # optional sample data
npm run dev
```

### 3. Customer app (Android emulator)
```bash
cd customer_app
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:4000
```

### 4. ML service
```bash
# Runs in Docker (docker compose up -d)
# Or locally:
cd ml_service
pip install -r requirements.txt
uvicorn main:app --reload --port 8001
```

## Tech Stack

| Layer | Technology |
|---|---|
| Customer/Driver/Shopkeeper apps | Flutter + Provider |
| Backend API | Node.js · Express 5 · TypeScript |
| ORM | Prisma 7 + PostgreSQL 16 |
| Cache / realtime timers | Redis 7 |
| WebSockets | Socket.io |
| ML service | FastAPI · OSRM · OR-Tools (upgrade path) |
| Auth | OTP (phone) + JWT |
| Payments (wired) | eSewa · Khalti · Fonepay |
| SMS (Tier-1 shops) | Sparrow SMS / Twilio |
| Push notifications | Firebase Cloud Messaging |
| Deployment | Docker · DigitalOcean |

## Design System

| Token | Value | Use |
|---|---|---|
| `primary` | `#A8442C` terracotta | Buttons, active states |
| `primaryDark` | `#2B2D3D` charcoal | Headers, primary text |
| `accent` | `#E8A33D` gold | Badges, highlights |
| `surface` | `#FFFFFF` | Backgrounds |
| `surfaceTint` | `#FBEEE8` | Cards |

Typography: **Lora** (headings) + **Inter** (body) via `google_fonts`.

## API Reference (backend)

```
POST /auth/otp/request         { phone }
POST /auth/otp/verify          { phone, code } → { token }

GET  /catalog                  ?category&q&limit
GET  /catalog/categories
GET  /shops/nearby             ?lat&lng&radiusKm

POST /orders                   { items[], deliveryAddress }
GET  /orders                   (customer's order list)
GET  /orders/:id
PATCH /orders/:id/status

GET  /me
PATCH /me
GET  /me/addresses
POST /me/addresses
PATCH /me/addresses/:id/default
DELETE /me/addresses/:id

GET  /shop/orders/incoming
POST /shop/orders/:id/accept
POST /shop/orders/:id/reject
PATCH /shop/inventory/:productId   { inStock, price? }

GET  /driver/batches/current
POST /driver/orders/:id/pickup
POST /driver/orders/:id/deliver
POST /driver/location          { lat, lng }
```

## ML Service Endpoints

```
POST /ml/dispatch/score         rank candidate shops for an order
POST /ml/routing/optimize       greedy nearest-neighbour batch routing
POST /ml/eta/predict            OSRM ETA passthrough
GET  /ml/forecast/shop/{id}/sku/{id}  demand forecast (Phase 0 stub)
GET  /healthz
```

### 5. Web app (Next.js)
```bash
cd web
npm install
npm run dev
# Open http://localhost:3000
# Set NEXT_PUBLIC_API_URL=http://localhost:4000 in .env.local if needed
```

## License

MIT
