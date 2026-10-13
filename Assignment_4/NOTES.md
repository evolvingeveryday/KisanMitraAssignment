# CS543 — Assignment 4: Rebuilding a Kisan Mitra Service in REST
## Notes & Technical Reflection

**Team Members:**
- **Dipesh Mishra** — 20251651036
- **Suraj Ku. Saw** — 20251651092
- **Sandeep Parmar** — 20251651081
- **Vivek Kumar** — 20251651104

**Service Chosen:** Kisan Mitra **Orders Service** (rebuilt from scratch in REST).

---

## Part A — Resource Table (A4)

| Method | URL | What it does | Success Code | Failure Codes |
|---|---|---|---|---|
| `POST` | `/orders` | Places a new produce order for a buyer (retry-safe via `Idempotency-Key`) | `201 Created` (+ `Location`) | `400`, `401`, `409`, `422`, `429` |
| `GET` | `/orders` | Lists and filters produce orders using query parameters (e.g. `?status=pending`) | `200 OK` | `406` |
| `GET` | `/orders/{id}` | Reads a single order representation (cacheable with `ETag`) | `200 OK` / `304 Not Modified` | `404`, `406` |
| `PATCH` | `/orders/{id}` | Partially updates order delivery address or status (guarded by `If-Match`) | `200 OK` | `401`, `404`, `409`, `412`, `422`, `428` |
| `POST` | `/orders/{id}/cancel` | Sub-resource state action: cancels an active order | `202 Accepted` (1st time) / `200 OK` (repeat) | `401`, `404`, `409` |
| `DELETE`| `/orders/{id}` | Permanently removes an order record | `204 No Content` | `401`, `404` |
| `OPTIONS`| `/orders/{id}` | Discovers supported HTTP methods via `Allow` header | `204 No Content` | — |

---

## Hard Choice Justification (A5)

**Operation:** Order Cancellation (`cancelOrder`).

In our Assignment 2 capability analysis and Assignment 3 SOAP thinking, cancellation was conceived as an RPC-style function call: `cancelOrder(orderId, reason)`. Mapping this cleanly onto REST was difficult because cancellation is a discrete state-transition event with side effects (alerting the farmer, halting transport dispatch, voiding payment authorizations) rather than a simple database attribute update. 

We considered two competing designs:
1. `DELETE /orders/{id}`: We rejected this because in e-commerce, deleting a resource means removing its record entirely (`204 No Content`). An order that was placed, paid for, and cancelled must remain auditable for accounting and farmer payout records.
2. `PATCH /orders/{id}` with `{"status": "cancelled"}`: We rejected relying solely on generic PATCH because cancellation triggers multi-step asynchronous workflow processing (releasing inventory holds, issuing refund intents). A client could also attempt to patch forbidden state transitions (e.g., trying to set `delivered` directly).

**Resolution:** We modeled cancellation as a dedicated action sub-resource: `POST /orders/{id}/cancel`. This follows REST best practices for non-CRUD business actions, returns `202 Accepted` initially to signal background processing, and returns `200 OK` if retried on an already-cancelled order, making it naturally safe to retry.

---

## Outbound Network Call Hardening & Fallback (Part D / D3)

Our Orders Service makes an outbound HTTP settlement call to the external **KisanPay Gateway** service. The endpoint address is resolved from an environment variable (`process.env.PAYMENT_GATEWAY_URL`), never hard-coded.

To survive network instability:
1. **Timeout & Retries:** Outbound calls have a strict 3000ms socket timeout. Retries use exponential backoff (initial delay 500ms, factor 2.0) with random jitter ($\pm 100$ms) to prevent the "thundering herd" problem against the payment switch.
2. **Safe Retry Rules:** We **never** retry any `4xx` response (e.g., `400 Bad Request` or `401 Unauthorized`), as these represent deterministic client or credential errors. Any retried payment create always transmits an `Idempotency-Key` header.
3. **Fallback Choice:** If the payment gateway remains unreachable after 3 attempts, we deliberately chose to **fail cleanly with `503 Service Unavailable`** (or `502 Bad Gateway`) rather than silently degrading into an unverified "offline promised" order state. 
   - *Justification:* In agricultural trading, produce represents perishable, high-value physical goods. Allowing a buyer's order to transition into "confirmed" when the farmer has not received payment settlement guarantees financial loss for the farmer if the buyer defaults. Therefore, failing fast and preserving order status as `PENDING_PAYMENT` is domain-critical.

---

## Reflection Answers

### 1. WSDL vs OpenAPI Line Count & Differences
- `partner.wsdl` line count: **117 lines**
- `openapi.yaml` line count: **258 lines**
- *What is the difference made of?* The OpenAPI document is substantially more descriptive regarding application-level behavior: it specifies explicit HTTP status codes (`201`, `304`, `400`, `401`, `404`, `409`, `412`, `422`, `428`, `429`), request query parameters, header declarations (`Idempotency-Key`, `If-Match`, `If-None-Match`), and concrete request/response JSON schemas with field-level constraints.
- *Two things WSDL declared that OpenAPI does not need to:*
  1. **Transport Binding Plumbing:** WSDL explicitly declares `<soap:binding transport="http://schemas.xmlsoap.org/soap/http" style="document"/>`, message parts, and envelope wrapping protocols. OpenAPI operates directly over HTTP natively and does not require re-specifying transport-layer mechanics.
  2. **Abstract vs Concrete Separation:** WSDL separates `<wsdl:portType>` (abstract operations) from `<wsdl:binding>` (SOAP wire encoding) and `<wsdl:port>` (network endpoint). In OpenAPI, path templates and HTTP verbs directly unite the interface contract with HTTP semantics.

### 2. SOAP Fault Replacement & Network Intermediate Hazards
- *Quoted SOAP Fault:*
  ```xml
  <soapenv:Fault>
    <faultcode>soapenv:Client.PaymentDeclined</faultcode>
    <faultstring>Agricultural bank transaction declined: insufficient wallet balance</faultstring>
  </soapenv:Fault>
  ```
- *Replaced REST Status & Problem Body:*
  - Status: `409 Conflict` (or `422 Unprocessable Entity`)
  - Body:
    ```json
    {
      "type": "https://kisanmitra.in/errors/payment-declined",
      "title": "Payment Declined",
      "status": 409,
      "detail": "The payment provider declined the transaction due to insufficient funds."
    }
    ```
- *Why returning an error inside 200 OK is a problem for the network in between:*
  When a SOAP service packages a business fault inside an `HTTP 200 OK` header, every intermediate network device (reverse proxies, CDNs, API gateways, load balancers, and monitoring tools like Datadog or Prometheus) treats the transaction as a successful exchange. As a result:
  - Cache layers may cache the failure response and serve the error message to subsequent legitimate users.
  - Circuit breakers fail to trip because the error rate appears as 0%.
  - Distributed tracing cannot detect anomalies without deep packet inspection of the XML payload.

### 3. UDDI's Moves (Publish, Find, Bind) in Modern REST
- **Publish:** UDDI's manual publication to an operator node has disappeared. It has been replaced by OpenAPI specifications committed directly to Git repositories, published to developer portals (SwaggerHub, Redocly), or exposed dynamically via `GET /openapi.yaml`.
- **Find:** Dynamic UDDI taxonomic lookups have disappeared. They are replaced by cloud service discovery registries (Consul, Kubernetes DNS, AWS Cloud Map) or developer-driven documentation search.
- **Bind:** Dynamic run-time binding from UDDI tModels has been replaced by static compile-time client SDK generation (OpenAPI Generator) and declarative environment-based routing (`process.env.SERVICE_URL`).
- *Summary:* Dynamic runtime negotiation between unknown parties proved fragile in production; static, auditable contracts with declarative infrastructure took over.

### 4. Validation Responsibility: XML Schema vs Code
- *Function carrying responsibility:* `validateOrderCreation(req.body)` inside `validator.js`.
- *Failure that would get through without it:* If a client sent a request with an empty items array `{"deliveryAddress": "Anand Mandi", "items": []}`, or an item with negative quantity `{"quantity": -10}`, without `validateOrderCreation()` the code would execute, calculate negative farmer payouts, decrement inventory improperly, and corrupt billing databases.

### 5. Where to Choose SOAP over REST
- *Edge chosen:* Inter-bank settlements with the Reserve Bank / NABARD agricultural clearing switch (**KisanPay**).
- *Exact guarantee bought:* **WS-Security End-to-End Encryption and Non-Repudiation.** In banking networks where transaction packets route through multiple intermediary clearinghouses, TLS only secures hop-by-hop transport links. WS-Security allows the agricultural bank to cryptographically sign the XML payload itself with an X.509 hardware certificate, providing non-repudiation in legal court if a transaction is contested.
