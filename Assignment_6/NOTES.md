# CS543 — Assignment 6: Honest Responses, Status Codes & Validation
## Kisan Mitra Orders Service

**Team Members:**
- **Dipesh Mishra** — 20251651036
- **Suraj Ku. Saw** — 20251651092
- **Sandeep Parmar** — 20251651081
- **Vivek Kumar** — 20251651104

**Service:** Kisan Mitra Orders Service (`http://localhost:5000`)
Verified with live server outputs (see `transcript.txt` and passing automated Jest tests: 17/17 passing).

---

## 1. Status Map

| Endpoint | Success Status & Why | Failure Statuses & Why |
|---|---|---|
| `POST /orders` | `201 Created`: Returns newly created order with `Location: /orders/{id}`. | `400`: Malformed JSON syntax.<br>`401`: Missing or invalid Bearer token.<br>`409`: State conflict (produce out of stock).<br>`422`: Schema validation failure (bad fields).<br>`429`: Per-client rate budget exceeded (`Retry-After`). |
| `GET /orders` | `200 OK`: Pure idempotent read of order list filtered by status query string. | `406`: Client asked for unsupported media format. |
| `GET /orders/{id}` | `200 OK`: Returns order representation.<br>`304 Not Modified`: Cached ETag matches `If-None-Match`. | `404`: Order ID does not exist in store.<br>`406`: Requested Accept type cannot be produced. |
| `PATCH /orders/{id}` | `200 OK`: Partially updates delivery address or status with new ETag. | `401`: Unauthorized caller.<br>`404`: Order not found.<br>`409`: Cannot update cancelled or delivered order.<br>`412`: `If-Match` ETag mismatch (lost update prevented).<br>`422`: Validation failure on patch values.<br>`428`: Missing required `If-Match` header. |
| `POST /orders/{id}/cancel` | `202 Accepted`: First-time cancellation accepted for background processing.<br>`200 OK`: Repeated cancellation on already-cancelled order (safe retry). | `401`: Missing Bearer authorization.<br>`404`: Order ID not found.<br>`409`: Illegal state transition (cannot cancel shipped/delivered orders). |
| `DELETE /orders/{id}` | `204 No Content`: Resource deleted permanently; response body is strictly empty. | `401`: Missing Bearer authorization.<br>`404`: Order ID not found. |
| `OPTIONS /orders/{id}` | `204 No Content`: Returns supported methods via `Allow` header with no payload. | None (pure metadata endpoint). |

---

## 2. Type Catalogue

Stable type URIs used across all RFC 7807 error responses:

| Stable Type URI | Failure Trigger |
|---|---|
| `https://kisanmitra.in/errors/bad-request` | Malformed JSON syntax in request body (e.g. unclosed quotes, illegal braces). |
| `https://kisanmitra.in/errors/unauthorized` | Missing or malformed `Authorization: Bearer <token>` header on protected endpoints. |
| `https://kisanmitra.in/errors/order-not-found` | Client requested an order ID that does not exist in the database or store. |
| `https://kisanmitra.in/errors/validation-error` | Request body failed schema validation (e.g. empty address, empty items list, quantity $\le 0$). |
| `https://kisanmitra.in/errors/item-unavailable` | Requested farm produce is out of stock with local farmers or unavailable for dispatch. |
| `https://kisanmitra.in/errors/illegal-transition` | Requested lifecycle state change is illegal (e.g. cancelling an already-shipped consignment). |
| `https://kisanmitra.in/errors/precondition-required` | Mutation write attempted without mandatory concurrency control header (`If-Match`). |
| `https://kisanmitra.in/errors/precondition-failed` | Provided `If-Match` ETag does not match current resource version, indicating a concurrent update collision. |
| `https://kisanmitra.in/errors/rate-limit-exceeded` | Client sent more than 50 requests within a 60-second window. |
| `https://kisanmitra.in/errors/not-acceptable` | Client sent an unsupported `Accept` header (e.g. `image/png`). |
| `https://kisanmitra.in/errors/internal-server-error` | Unhandled server exception; masked to protect internals. |

---

## 3. Labeled Problem Details Body

Below is a live RFC 7807 response captured from `POST /orders` when out-of-stock produce is ordered:

```json
{
  "type": "https://kisanmitra.in/errors/item-unavailable",       // Stable URI identifying the error category
  "title": "Produce Unavailable",                               // Human-readable summary of problem type
  "status": 409,                                                // HTTP status code echoing response status
  "detail": "One or more selected farm items are out of stock with local farmers." // Specific explanation of this occurrence
}
```

---

## 4. Field-Level 422 Reporting Multiple Bad Fields

When a client submits an invalid order containing an empty address, an empty product ID, and an invalid negative quantity:

### Request:
```http
POST /orders HTTP/1.1
Host: localhost:5000
Authorization: Bearer km_buyer_token_789
Content-Type: application/json

{
  "deliveryAddress": "",
  "items": [
    {
      "productId": "",
      "quantity": 0
    }
  ]
}
```

### Live Response:
```http
HTTP/1.1 422 Unprocessable Entity
Content-Type: application/problem+json; charset=utf-8

{
  "type": "https://kisanmitra.in/errors/validation-error",
  "title": "Validation Failed",
  "status": 422,
  "detail": "The submitted order payload failed field-level schema validation.",
  "errors": [
    {
      "field": "deliveryAddress",
      "message": "Delivery address is required and cannot be empty."
    },
    {
      "field": "items[0].productId",
      "message": "Product ID is required."
    },
    {
      "field": "items[0].quantity",
      "message": "Quantity must be a positive integer greater than or equal to 1."
    }
  ]
}
```

---

## 5. Endpoints Safe to Retry & Status Codes

- **Safe to retry blindly:**
  - `GET /orders` and `GET /orders/{id}`: Pure read operations.
  - `POST /orders`: Made safe to retry by including the **`Idempotency-Key`** header.
  - `POST /orders/{id}/cancel`: Safe to retry because a second cancellation returns `200 OK` rather than an error.
  - `DELETE /orders/{id}`: Safe to retry because the resource is already gone on repeat calls.
  - `OPTIONS /orders/{id}`: Safe to retry (pure discovery).

- **Status codes telling a client to retry:**
  - **`429 Too Many Requests`** with **`Retry-After: 60`**: Explicitly tells the client that the failure is temporary due to rate budgeting, and states the exact seconds to wait before retrying.
  - **`503 Service Unavailable`** with **`Retry-After`**: Tells the client the downstream service or gateway is temporarily overloaded.
  - *Contrast:* A `4xx` error like `400`, `401`, or `422` indicates the request itself is malformed or invalid; retrying the identical payload will **never** succeed.

---

## 6. Internal Error Masking (Never Leaking Internals)

In `app.js`, all database lookups, JSON parsing, and external payments are wrapped in centralized error-handling middleware:

```javascript
app.use((err, req, res, next) => {
  console.error('[Internal Error]:', err.message); // Logged server-side for internal debugging
  problem(res, {
    status: 500,
    title: 'Internal Server Error',
    detail: 'An internal error occurred processing your request. Please contact support.',
    type: 'https://kisanmitra.in/errors/internal-server-error'
  });
});
```

**What was hidden from the caller:**
- Raw database connection strings (MongoDB URIs)
- Internal filesystem paths (`D:\Kisan-Mitra\orders-service\...`)
- SQL / NoSQL query syntax fragments
- Node.js runtime stack traces with line numbers and internal dependency versions
- Partner private API keys and merchant bank passwords

---

## 7. JSON and XML Content Negotiation

The same order (`ID: 104`) retrieved in two distinct serialization formats based on the `Accept` header:

### A. Format: JSON (`Accept: application/json` or default)
```http
GET /orders/104 HTTP/1.1
Host: localhost:5000
Accept: application/json

HTTP/1.1 200 OK
Content-Type: application/json; charset=utf-8
ETag: "9e1c2a8f3b4d5e6a"

{
  "id": "104",
  "buyerId": "BUYER-01",
  "items": [
    {
      "productId": "PROD-MUSTARD-01",
      "quantity": 20,
      "pricePerKg": 75,
      "itemTotal": "1500.00"
    }
  ],
  "totalAmount": 1500,
  "deliveryAddress": "Kisan Mandi Warehouse 2, Anand",
  "status": "pending",
  "createdAt": "2026-10-13T16:54:40.300Z",
  "updatedAt": "2026-10-13T16:54:40.300Z"
}
```

### B. Format: XML (`Accept: application/xml`)
```http
GET /orders/104 HTTP/1.1
Host: localhost:5000
Accept: application/xml

HTTP/1.1 200 OK
Content-Type: application/xml; charset=utf-8
ETag: "9e1c2a8f3b4d5e6a"

<?xml version="1.0" encoding="UTF-8"?>
<order>
  <id>104</id>
  <buyerId>BUYER-01</buyerId>
  <items>
    <item>
      <productId>PROD-MUSTARD-01</productId>
      <quantity>20</quantity>
      <pricePerKg>75</pricePerKg>
      <itemTotal>1500.00</itemTotal>
    </item>
  </items>
  <totalAmount>1500</totalAmount>
  <deliveryAddress>Kisan Mandi Warehouse 2, Anand</deliveryAddress>
  <status>pending</status>
  <createdAt>2026-10-13T16:54:40.300Z</createdAt>
  <updatedAt>2026-10-13T16:54:40.300Z</updatedAt>
</order>
```
