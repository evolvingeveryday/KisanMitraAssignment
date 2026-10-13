# CS543 — Assignment 6: Honest Responses, Status Codes & Validation

## Team Members
- **Dipesh Mishra** — 20251651036
- **Suraj Ku. Saw** — 20251651092
- **Sandeep Parmar** — 20251651081
- **Vivek Kumar** — 20251651104

## Deliverables in this Folder
- `openapi.yaml`: OpenAPI 3.0.3 specification reflecting RFC 7807 Problem Details schemas and explicit failure codes.
- `NOTES.md`: Contains Status Map (Question 1), Type Catalogue (Question 2), Labeled Problem Details Body (Question 3), Field-Level 422 Sample (Question 4), Safe Retries Analysis (Question 5), Internal Error Masking (Question 6), and XML/JSON Content Negotiation representations (Question 7).
- `transcript.txt`: Real live curl transcript demonstrating the success path (201 + Location + JSON), all failure paths (field-level 422, empty cart 422, produce out of stock 409, 404, illegal transition 409, rate limit 429), and content negotiation (`Accept: application/xml` and 406 on `Accept: image/png`).
- Implementation source code: `D:\Kisan-Mitra\orders-service\` featuring `errors.js` (RFC 7807), `validator.js` (multi-field error collector), and `negotiate.js` (XML/JSON serializer).
