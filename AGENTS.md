# Project: Student Marketplace

A mobile app (Flutter/Dart) where students post services and items, others contact them or book appointments, and item search returns the seller or "Item not in market".

## Architecture (never violate)
- mobile/  = Flutter app. It only talks to the backend over HTTP. It NEVER touches SQLite and must not use sqflite.
- backend/ = Node.js + Express REST API. The ONLY code that touches the database.
- Database = SQLite file at backend/data/market.db via the better-sqlite3 package. Plain SQL, no ORM.

## Rules for the agent
1. Only do the work described in the current prompt. Do not add features, screens, routes, or files beyond it.
2. Do not install any package that is not named in the prompt.
3. Do not modify files that are not needed for the current prompt.
4. Backend uses CommonJS (require / module.exports). Keep code simple and put a short comment above each function.
5. All backend errors are JSON: { "error": "message" } with a correct HTTP status code.
6. Never hardcode secrets. Read them from backend/.env. Never print or commit secrets.
7. Never store or return plain passwords or password_hash.
8. Do not start long-running servers yourself unless told to. Tell me the command instead.
9. When finished, reply with: (a) list of files created/changed, (b) the exact commands I should run to verify.
10. If something in the prompt is ambiguous, ask me one question instead of guessing.