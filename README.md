# Kisan Mitra — CS543 Web Services Master Repository
## Assignments 1 through 6 Complete Implementation

**Course:** CS543 Web Services  
**Instructor:** Dr. Pramit Mazumdar, IIIT Vadodara  

### Team Members
- **Dipesh Mishra** — 20251651036
- **Suraj Ku. Saw** — 20251651092
- **Sandeep Parmar** — 20251651081
- **Vivek Kumar** — 20251651104

---

## Project Structure Overview

```
D:\Kisan-Mitra\
├── README.md                                 # Master repository overview and execution guide
├── orders-service\                           # Core REST Microservice (Assignments 4, 5, 6)
│   ├── package.json                          # Scripts & dependencies (Express, Jest, Supertest)
│   ├── server.js                             # Express HTTP server listening on port 5000
│   ├── app.js                                # Application router and middleware pipeline
│   ├── openapi.yaml                          # Canonical OpenAPI 3.0.3 Contract
│   ├── store.js                              # In-memory store with Idempotency-Key cache
│   ├── models.js                             # Order model (Record vs Representation separation)
│   ├── validator.js                          # Multi-field schema validation collecting errors for 422
│   ├── errors.js                             # RFC 7807 Problem Details (application/problem+json)
│   ├── etag.js                               # ETag hashing, If-None-Match (304), If-Match (412)
│   ├── rateLimit.js                          # Rate limiter (X-RateLimit-*, 429 Retry-After)
│   ├── auth.js                               # Bearer token authorization middleware (401)
│   ├── cors.js                               # CORS preflight handler & Access-Control headers
│   ├── negotiate.js                          # Content negotiation (JSON / XML, 406 Not Acceptable)
│   ├── security.js                           # Security headers (nosniff, HSTS)
│   └── tests\
│       └── orders.test.js                    # 17 Automated Jest/Supertest tests (100% passing)
│
└── assignments\
    ├── assignment-01\                        # A01: HTTP by Hand & Project Setup
    │   ├── brief.md                          # 1-page Kisan Mitra Brief (Nouns & Verbs)
    │   ├── http-log.md / http-log-raw.txt    # 5 curl calls + deliberate 404
    │   └── network-analysis.md               # DevTools waterfall inspection
    ├── assignment-02\                        # A02: Services, Contracts & Schema
    │   ├── design.md                         # Capabilities, PlaceOrder spec, validation
    │   ├── contracts.md                      # Cross-service API contracts table
    │   ├── services.drawio / services.png    # Service boundary diagram
    │   └── schema.drawio / schema.sql        # Database schema ERD and DDL
    ├── assignment-03\                        # A03: Integrate External SOAP Partner
    │   ├── integration.md                    # Context, SOAP justification, binding, discovery, fault mapping
    │   ├── partner.wsdl                      # Complete WSDL 1.1 for KisanPay Gateway
    │   ├── soap-request.xml                  # Hand-formed SOAP request envelope with credentials
    │   ├── soap-response.xml                 # Hand-formed SOAP response envelope
    │   └── soap-fault.xml                    # Hand-formed SOAP fault envelope
    ├── assignment-04\                        # A04: Rebuilding a Service in REST
    │   ├── openapi.yaml                      # OpenAPI 3.0 contract
    │   ├── NOTES.md                          # Resource table, A5 hard choice, D3 fallback, answers
    │   └── curl-transcript.txt               # Live curl transcript (201, idempotent repeat, 400, 404, 409)
    ├── assignment-05\                        # A05: HTTP Methods & Headers
    │   ├── openapi.yaml                      # Updated OpenAPI contract
    │   ├── NOTES.md                          # Method map, safe & idempotent matrix, headers table, answers
    │   └── curl-transcript.txt               # Live curl -v transcript (201, 304, 412, 401, cancel, delete, etc.)
    └── assignment-06\                        # A06: Honest Responses, Status Codes & Validation
        ├── openapi.yaml                      # OpenAPI contract with RFC 7807 error models
        ├── NOTES.md                          # Status map, type catalogue, multi-field 422, answers
        └── transcript.txt                    # Live curl transcript covering success, all failures, and XML
```

---

## How to Run & Verify on Windows

### 1. Run Automated Test Suite
From PowerShell:
```powershell
cd D:\Kisan-Mitra\orders-service
npm.cmd test
```
*Result:* Runs all 17 Jest/Supertest automated tests verifying authentication, multi-field 422 errors, idempotent creation, ETags, conditional requests (304 / 412), rate limiting (429), and XML negotiation.

### 2. Start Live Service
```powershell
cd D:\Kisan-Mitra\orders-service
npm.cmd start
```
*Result:* Service boots on `http://localhost:5000`.

### 3. Verify Live Endpoints with curl
```powershell
# Create an order (201 + Location):
curl -i -X POST http://localhost:5000/orders `
  -H "Authorization: Bearer km_token_123" `
  -H "Content-Type: application/json" `
  -d '{"deliveryAddress": "Anand APMC Mandi, Gujarat", "items": [{"productId": "PROD-WHEAT-01", "quantity": 5, "pricePerKg": 35}]}'

# Conditional read (304 Not Modified):
curl -i http://localhost:5000/orders/1 `
  -H 'If-None-Match: "c52c0f64c6db2492"'

# Multi-field validation failure (422 Unprocessable Entity):
curl -i -X POST http://localhost:5000/orders `
  -H "Authorization: Bearer km_token_123" `
  -H "Content-Type: application/json" `
  -d '{"deliveryAddress": "", "items": [{"productId": "", "quantity": 0}]}'

# Content negotiation for XML:
curl -i http://localhost:5000/orders/1 -H "Accept: application/xml"
```
