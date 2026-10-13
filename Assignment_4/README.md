# CS543 — Assignment 4: Rebuilding a Kisan Mitra Service in REST

## Team Members
- **Dipesh Mishra** — 20251651036
- **Suraj Ku. Saw** — 20251651092
- **Sandeep Parmar** — 20251651081
- **Vivek Kumar** — 20251651104

## Deliverables in this Folder
- `openapi.yaml`: Canonical OpenAPI 3.0.3 specification for the Kisan Mitra Orders Service with `$ref` schemas and failure status codes.
- `NOTES.md`: Contains Part A Resource Table, A5 Hard Choice Justification, D3 Fallback Reasoning, and the five reflection answers.
- `curl-transcript.txt`: Real `curl -i` transcript captured against the live running service showing 201 + Location, idempotent repeat with same key, 400 malformed JSON, 404 missing resource, and 409 produce unavailable.
- Implementation source code: `D:\Kisan-Mitra\orders-service\` (`models.js`, `store.js`, `errors.js`, `validator.js`, `app.js`, `server.js`, and `tests/orders.test.js`).
