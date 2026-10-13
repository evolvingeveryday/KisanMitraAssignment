# CS543 — Assignment 5: HTTP Methods & Headers

## Team Members
- **Dipesh Mishra** — 20251651036
- **Suraj Ku. Saw** — 20251651092
- **Sandeep Parmar** — 20251651081
- **Vivek Kumar** — 20251651104

## Deliverables in this Folder
- `openapi.yaml`: Updated OpenAPI 3.0.3 contract documenting HTTP methods, headers, and status codes.
- `NOTES.md`: Contains Part A Method Map (A1), Safe & Idempotent Matrix (A3), Full Exchange Sample (A6), Safe-Retry Plan (C4), Headers Table (D2), and the eight reflection answers.
- `curl-transcript.txt`: Real `curl -v` transcript captured against the live running service showing 201 + Location, idempotent repeat, conditional GET 304, conditional write 412, 400, 404, 401, cancel, delete, and OPTIONS.
- Implementation source code: `D:\Kisan-Mitra\orders-service\` including `etag.js`, `rateLimit.js`, `auth.js`, `cors.js`, `negotiate.js`, and `security.js`.
