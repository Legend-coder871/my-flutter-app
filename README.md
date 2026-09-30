# Student Marketplace

A mobile app where students post services and items, others contact them or book
appointments, and searching for an item returns the seller or "Item not in market".

## Architecture

```
+-------------------+        HTTP / JSON         +-------------------+        SQL          +-------------------+
|      mobile/      |  -----------------------> |      backend/     |  --------------->  |      SQLite       |
|   Flutter app     |   http://10.0.2.2:3000/api |  Node + Express   |  better-sqlite3     | backend/data/     |
| (Android device/  |  <----------------------- |   REST API        |  <---------------  | market.db         |
|     emulator)     |                           +-------------------+                    +-------------------+
+-------------------+
```

- `mobile/` only talks to the backend over HTTP. It never touches SQLite.
- `backend/` is the only code that touches the database.
- The database is a single SQLite file at `backend/data/market.db`.

## Prerequisites

- Node.js 18+ (backend + tests)
- Flutter SDK (mobile app)
- Android Studio with an Android emulator (or a real device)
- Optional: DB Browser for SQLite (to inspect `backend/data/market.db`)

## How to run

### 1. Backend

```powershell
cd backend
npm install
copy .env.example .env
# edit .env and set JWT_SECRET to a long random string, e.g.:
#   node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
npm run seed
npm run dev
```

The API runs on `http://localhost:3000` (`Server running on port 3000`).

### 2. Emulator

Start the emulator in Android Studio (Device Manager -> Play) and wait until it
is fully booted.

### 3. Mobile app

```powershell
cd mobile
flutter pub get
flutter run
```

Pick the emulator when asked for a device. The first build takes a few minutes.

> **Note:** `10.0.2.2` is how the Android emulator reaches the laptop host, so
> the app calls the backend at `http://10.0.2.2:3000/api` (see
> `mobile/lib/config.dart`). On a real phone, replace it with your computer's
> LAN IP address.

## Demo accounts (from `npm run seed`)

| Email | Password |
|---|---|
| amina@demo.com | password123 |
| bob@demo.com | password123 |
| carol@demo.com | password123 |

The seed script only inserts data when the `users` table is empty and never
deletes anything.

## API routes

Base URL: `http://localhost:3000/api`

| Method | Route | Auth | Description |
|---|---|---|---|
| GET | `/health` | - | Health check, returns `{ "status": "ok" }` |
| POST | `/auth/register` | - | Create an account, returns `{ token, user }` |
| POST | `/auth/login` | - | Log in, returns `{ token, user }` |
| GET | `/auth/me` | Bearer | Current user |
| GET | `/services` | - | Active services (`?q=`, `?category=`) with provider info |
| GET | `/services/mine` | Bearer | My services (active or not) |
| GET | `/services/:id` | - | One service with provider info |
| POST | `/services` | Bearer | Create a service |
| PUT | `/services/:id` | Bearer | Update my service (owner only) |
| DELETE | `/services/:id` | Bearer | Delete my service (owner only) |
| GET | `/items` | - | Available items with seller info |
| GET | `/items/search?q=` | - | Search items -> `{ found, message, results }` |
| GET | `/items/mine` | Bearer | My items |
| GET | `/items/:id` | - | One item with seller info |
| POST | `/items` | Bearer | Create an item |
| PUT | `/items/:id` | Bearer | Update my item (owner only) |
| DELETE | `/items/:id` | Bearer | Delete my item (owner only) |
| POST | `/bookings` | Bearer | Book a service (409 if the slot is taken) |
| GET | `/bookings/mine` | Bearer | Bookings I made |
| GET | `/bookings/received` | Bearer | Bookings on my services |
| PATCH | `/bookings/:id/status` | Bearer | Confirm / decline / cancel |

Errors are JSON: `{ "error": "message" }` with the appropriate HTTP status.

## Backend tests

```powershell
cd backend
npm test
```

Runs `node --test` with `node:test` + `node:assert` against an in-memory
database (`DB_FILE=:memory:`). All 16 tests should pass.

## Useful scripts (backend)

| Script | Purpose |
|---|---|
| `npm run dev` | Start the API with auto-reload |
| `npm start` | Start the API |
| `npm run db:init` | Create the database file and schema |
| `npm run seed` | Insert demo data (only if the DB is empty) |
| `npm test` | Run the automated tests |
