# Browser Network Analysis

## Project
Kissan Mitra — CS543 Assignment 01

## Objective
To inspect an HTTP request using Chrome Developer Tools and analyze its request headers, response status, caching behavior, and server information.

## 1. Request Details

- **Request URL:** https://jsonplaceholder.typicode.com/posts/1
- **Request Method:** GET
- **Status Code:** 304 Not Modified
- **Protocol:** HTTPS
- **Remote Address:** [2606:4700:3033::6815:3b13]:443
- **Referrer Policy:** strict-origin-when-cross-origin

## 2. Request Headers

| Header | Observed value | Purpose |
|---|---|---|
| `:method` | GET | Retrieves the requested resource |
| `:scheme` | https | Indicates a secure HTTPS request |
| `:authority` | jsonplaceholder.typicode.com | Identifies the target host |
| `:path` | /posts/1 | Identifies the requested resource path |
| `if-none-match` | W/"124-yiKdLzqO5gfBrJFrcdJ8Yq0LGnU" | Allows conditional cache validation |
| `accept` | Browser-supported content types | Indicates acceptable response formats |
| `accept-encoding` | gzip, deflate, br, zstd | Lists supported response compression formats |
| `user-agent` | Chrome on Windows | Identifies the browser client |

## 3. Response Headers

| Header | Observed value | Purpose |
|---|---|---|
| `cache-control` | max-age=43200 | Specifies a cache freshness period |
| `etag` | W/"124-yiKdLzqO5gfBrJFrcdJ8Yq0LGnU" | Identifies a version of the resource |
| `cf-cache-status` | HIT | Indicates a cache hit at Cloudflare |
| `server` | cloudflare | Identifies the responding server infrastructure |
| `x-content-type-options` | nosniff | Helps prevent MIME-type sniffing |
| `x-powered-by` | Express | Indicates the server framework header |
| `x-ratelimit-limit` | 3600000 | Reports the configured rate limit |
| `x-ratelimit-remaining` | 3599999 | Reports the remaining rate-limit allowance |

## 4. Status Code Analysis

The browser received `304 Not Modified`.

This is a conditional HTTP response. The request included an `If-None-Match` header with an ETag previously associated with the resource. The server determined that the resource had not changed for that validator, so it did not need to send the full response body again.

The browser can reuse its stored representation when the applicable cache rules permit it. A 304 response is not an error.

## 5. Caching Analysis

- The `ETag` header identifies a version of the resource.
- The browser sent `If-None-Match` to validate its cached representation.
- The `304 Not Modified` response avoids transferring the complete representation again.
- `cf-cache-status: HIT` indicates that Cloudflare served the request from its cache.

## 6. Security and Transport Observations

- The request uses HTTPS.
- `strict-origin-when-cross-origin` is the browser's referrer policy.
- `x-content-type-options: nosniff` is present in the response.
- The observed request uses HTTP/2-style pseudo-headers such as `:method` and `:path`; these are protocol metadata, not ordinary application headers.

## 7. Conclusion

Chrome Developer Tools showed a GET request to the JSONPlaceholder API returning `304 Not Modified`. The `ETag` and `If-None-Match` headers demonstrate conditional cache validation. The response illustrates how HTTP caching can reduce unnecessary data transfer.

## Evidence

The observations in this report were captured from Chrome Developer Tools under the Network tab. A screenshot of the request Headers panel should be included with the assignment submission.

## 8. Network Timing Analysis

The request timing information was inspected using Chrome Developer Tools under the Network tab.

### Observed Timing

| Phase | Duration |
|---|---:|
| Queueing | 2.42 ms |
| Stalled | 3.66 ms |
| Request sent | 0.87 ms |
| Waiting for server response | 453.75 ms |
| Content download | 4.84 ms |
| **Total duration shown** | **465.53 ms** |

### Interpretation

- **Queueing (2.42 ms):** Time the request spent waiting before it could begin.
- **Stalled (3.66 ms):** Time spent waiting before the request was sent, including possible connection or scheduling delays.
- **Request sent (0.87 ms):** Time required to transmit the request.
- **Waiting for server (453.75 ms):** The largest reported phase. It represents the wait until the first response data arrives, commonly associated with Time to First Byte (TTFB).
- **Content download (4.84 ms):** Time spent receiving the response content.

### Conclusion

The displayed total duration was 465.53 ms. Waiting for the server response accounted for the largest reported phase, at 453.75 ms. This indicates that most of the measured time was spent waiting for the response rather than transmitting or downloading data.
