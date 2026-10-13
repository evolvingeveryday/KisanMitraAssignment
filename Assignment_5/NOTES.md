# CS543 — Assignment 5: HTTP Methods & Headers
## Kisan Mitra Orders Service

**Team Members:**
- **Dipesh Mishra** — 20251651036
- **Suraj Ku. Saw** — 20251651092
- **Sandeep Parmar** — 20251651081
- **Vivek Kumar** — 20251651104

**Service:** Kisan Mitra Orders Service (`http://localhost:5000`)
All behavior below was verified against live running instances of `orders-service/server.js` (see `curl-transcript.txt` and passing Jest test suite: 17/17 passing).

---

## Part A — Kisan Mitra Method Map (A1)

| Action | Method | URL | Success | Failure |
|---|---|---|---|---|
| Place produce order | `POST` | `/orders` | `201 Created` | `400`, `401`, `409`, `422`, `429` |
| List & filter orders | `GET` | `/orders?status=pending` | `200 OK` | `406` |
| Read single order | `GET` | `/orders/{id}` | `200 OK` / `304 Not Modified` | `404`, `406` |
| Partially modify order | `PATCH` | `/orders/{id}` | `200 OK` | `401`, `404`, `409`, `412`, `422`, `428` |
| Cancel order (non-CRUD) | `POST` | `/orders/{id}/cancel` | `202 Accepted` / `200 OK` | `401`, `404`, `409` |
| Remove order | `DELETE`| `/orders/{id}` | `204 No Content` | `401`, `404` |
| Discover allowed methods | `OPTIONS`| `/orders/{id}` | `204 No Content` (`Allow`) | — |

**Verb Audit:** Zero verbs exist in collection or resource URL paths (no `/getOrder`, `/createOrder`, `/deleteOrder`). The state transition action is modeled as a sub-resource `POST /orders/{id}/cancel`.

---

## Safe & Idempotent Matrix (A3)

| Endpoint | Safe? | Idempotent? | Architectural Notes |
|---|---|---|---|
| `GET /orders` | **Yes** | **Yes** | Read-only; mutates no state on the server. |
| `GET /orders/{id}` | **Yes** | **Yes** | Read-only; cacheable via ETag. |
| `POST /orders` | **No** | **No** (by nature) | Creates a new order; made **retry-safe via `Idempotency-Key`**. |
| `PATCH /orders/{id}` | **No** | **Yes** | Applying the same patch to the same state yields the identical final state. Guarded by `If-Match`. |
| `POST /orders/{id}/cancel` | **No** | **Yes** (by design) | First invocation transitions state (`202 Accepted`); repeats detect `cancelled` and return `200 OK`. |
| `DELETE /orders/{id}` | **No** | **Yes** | First call removes record (`204`); repeats return `404`. End state (resource absent) is identical. |
| `OPTIONS /orders/{id}` | **Yes** | **Yes** | Pure metadata discovery; sets `Allow` header. |

**The one that is neither, and how we made it retry-safe:**
`POST /orders` is neither safe nor naturally idempotent. Without safeguards, retrying a dropped network request creates duplicate orders, double-charges the buyer, and creates duplicate farmer dispatch tickets. We made it retry-safe using the **`Idempotency-Key`** header: on the first request, `store.js` saves the generated order alongside the key; any subsequent request carrying that identical key immediately retrieves and returns the exact cached response (`201` + `Location` + cached body) without creating duplicate orders.

---

## Full HTTP Exchange Sample (A6)

### Request:
```http
POST /orders HTTP/1.1
Host: localhost:5000
User-Agent: curl/8.4.0
Accept: application/json
Authorization: Bearer km_buyer_token_456
Content-Type: application/json
Idempotency-Key: km-key-a5-101
Content-Length: 145

{"deliveryAddress": "APMC Market Gate 1, Surat, Gujarat", "items": [{"productId": "PROD-RICE-02", "quantity": 10, "pricePerKg": 60}]}
```

### Response:
```http
HTTP/1.1 201 Created
X-Powered-By: Express
X-Content-Type-Options: nosniff
Strict-Transport-Security: max-age=31536000; includeSubDomains
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, POST, PATCH, DELETE, OPTIONS
Access-Control-Allow-Headers: Content-Type, Authorization, Idempotency-Key, If-Match, If-None-Match, X-HTTP-Method-Override, Accept
Access-Control-Expose-Headers: Location, ETag, X-RateLimit-Limit, X-RateLimit-Remaining, Retry-After
X-RateLimit-Limit: 50
X-RateLimit-Remaining: 49
Location: /orders/102
ETag: "8dbd7454044eb896"
Content-Type: application/json; charset=utf-8
Content-Length: 282
Date: Tue, 13 Oct 2026 16:48:14 GMT
Connection: keep-alive
Keep-Alive: timeout=5

{"id":"102","buyerId":"BUYER-01","items":[{"productId":"PROD-RICE-02","quantity":10,"pricePerKg":60,"itemTotal":"600.00"}],"totalAmount":600,"deliveryAddress":"APMC Market Gate 1, Surat, Gujarat","status":"pending","createdAt":"2026-10-13T16:48:14.210Z","updatedAt":"2026-10-13T16:48:14.210Z"}
```

---

## Safe-Retry Plan (C4)

| Risky Endpoint | Failure Risk | Applied Mechanism | Why this Mechanism Applies |
|---|---|---|---|
| `POST /orders` | Duplicate order placed; farmer dispatches twice; buyer charged twice. | `Idempotency-Key` | Since `POST` creates resources, caching the transaction record by client key allows the client to retry blindly without risk of duplicate execution. |
| `GET /orders/{id}` | Redundant bandwidth consumption; slow network over rural 3G. | `If-None-Match` + ETag | Caching allows client to validate local copy; server replies with zero-body `304 Not Modified`, saving round-trip time and bytes. |
| `PATCH /orders/{id}` | Lost update / mid-air collision (e.g., admin updates status while buyer updates address). | `If-Match` + ETag | Rejects writes with `412 Precondition Failed` if the resource was altered concurrently by another party. |

---

## Headers Table (D2)

| Endpoint | Request Headers Needed | Response Headers Set |
|---|---|---|
| `POST /orders` | `Authorization: Bearer <token>`, `Content-Type: application/json`, `Idempotency-Key: <key>`, `Accept` | `Location`, `ETag`, `Content-Type`, `X-RateLimit-*`, `X-Content-Type-Options`, `Strict-Transport-Security` |
| `GET /orders` | `Accept` | `Content-Type`, `X-RateLimit-*`, `Access-Control-*` |
| `GET /orders/{id}` | `If-None-Match`, `Accept` | `ETag`, `Cache-Control`, `Content-Type`, `X-RateLimit-*` |
| `PATCH /orders/{id}` | `Authorization: Bearer <token>`, `If-Match: <etag>`, `Content-Type: application/json`, `Accept` | `ETag`, `Content-Type`, `X-RateLimit-*` |
| `POST /orders/{id}/cancel` | `Authorization: Bearer <token>`, `Content-Type: application/json` | `Content-Type`, `X-RateLimit-*` |
| `DELETE /orders/{id}` | `Authorization: Bearer <token>` | `X-RateLimit-*`, `X-Content-Type-Options` |
| `OPTIONS /orders/{id}` | — | `Allow`, `Access-Control-Allow-Methods`, `Access-Control-Allow-Headers` |

---

## Eight Reflection Answers (D3)

### 1. Three Endpoints and the Single Most Critical Response Header
1. `POST /orders` $\to$ **`Location: /orders/102`**: This is the single most important header because REST creates resources with server-assigned URIs. The client needs the exact canonical address of the new order to bookmark, track, or cancel it later.
2. `GET /orders/{id}` $\to$ **`ETag: "8dbd7454044eb896"`**: Critical because it unlocks HTTP conditional reads (`304`) and safe conditional concurrency controls (`If-Match` $\to$ `412`), preventing lost updates in multi-user environments.
3. `POST (with rate limit exceeded)` $\to$ **`Retry-After: 60`**: Tells constrained clients exactly how many seconds to pause before retrying, preventing automated scripts from hammering a struggling server.

### 2. Safe & Idempotent Breakdown
- **Safe:** `GET /orders`, `GET /orders/{id}`, `OPTIONS /orders/{id}` (they perform pure reads without server-side mutation).
- **Idempotent:** `GET`, `PATCH /orders/{id}`, `DELETE /orders/{id}`, `POST /orders/{id}/cancel`.
- **Neither:** `POST /orders` is neither safe nor idempotent by definition. We made it retry-safe by attaching an `Idempotency-Key` header; the server caches the first response against that key and returns it verbatim on any retry.

### 3. ETag, 304, and 412 in Practice
- **ETag generated:** `"8dbd7454044eb896"`
- **Request returning 304:**
  `curl -i http://localhost:5000/orders/102 -H 'If-None-Match: "8dbd7454044eb896"'`
  $\to$ **Saves bandwidth and latency** by avoiding re-sending the order payload when the client already has the freshest version.
- **Request returning 412:**
  `curl -i -X PATCH http://localhost:5000/orders/102 -H 'Authorization: Bearer token' -H 'If-Match: "stale_etag_9999"' -d '{"deliveryAddress": "New Warehouse"}'`
  $\to$ **Prevents lost updates (mid-air collisions)** where two users modify the same order concurrently and one silently overwrites the other.

### 4. 422 vs 400: Exact Requests and Differences
- **400 Bad Request:** Occurs when the payload cannot be parsed as valid JSON.
  `curl -i -X POST http://localhost:5000/orders -H "Authorization: Bearer token" -H "Content-Type: application/json" -d "{malformed_json: true,"`
  - *Trigger:* JSON parser syntax error.
- **422 Unprocessable Entity:** Occurs when the body is well-formed syntactically, but semantically invalid according to domain rules.
  `curl -i -X POST http://localhost:5000/orders -H "Authorization: Bearer token" -H "Content-Type: application/json" -d '{"deliveryAddress": "", "items": []}'`
  - *Trigger:* Syntactically valid JSON, but violates business validation (empty address, empty items list).

### 5. CORS Block on Another Origin
When a browser on origin `http://farmer-portal.org` calls `http://localhost:5000/orders`, the **browser itself** blocks the response from the page's JavaScript (even if the server processed the request and logged a 200). 
- *Fix:* The server must send the **`Access-Control-Allow-Origin: *`** (or `Access-Control-Allow-Origin: http://farmer-portal.org`) header and correctly handle the preflight `OPTIONS` request.

### 6. Cache-Control: Allow Caching vs No-Store
- **Allow Caching (`public, max-age=60, must-revalidate`):** Set on `GET /orders/{id}` or `GET /catalog/products` where commodity produce prices and details are stable and caching reduces load on backend databases.
- **No-Store (`no-store`):** Set on sensitive or payment endpoints like `POST /orders` or `GET /payments/receipt`. Storing financial records or one-time payment tokens in shared proxy caches violates financial security and data privacy.

### 7. Search Endpoint: GET vs POST
- Our search endpoint `GET /orders?status=pending` is a GET.
- **When POST is justified:** If a search query involves hundreds of complex multi-criteria filters, spatial polygons (farmer GPS field boundaries), or sensitive criteria that exceed URL length limits (~2048 chars) or should not leak into browser history and proxy access logs.
- **What is given up by switching to POST:** You lose browser bookmarkability, URL shareability, and HTTP proxy caching.

### 8. Location Header: 201 vs 3xx
- **On `201 Created`:** Points to the **newly created resource** (e.g. `/orders/102`), informing the client where the durable entity lives.
- **On `3xx Redirect` (e.g., 301/303):** Points to the **target redirection URL** where the client should look next (e.g., following `303 See Other` after form processing).
