# Kissan Mitra - Service API Contracts

## 1. User Management Service

| Operation | Input | Output | Possible errors |
|---|---|---|---|
| `registerUser` | Name, email, phone, password, role | User ID, account status | Invalid input, duplicate email |
| `getUser` | User ID | Permitted user profile | User not found, forbidden |
| `updateUserStatus` | User ID, new status | Updated status | User not found, forbidden |

Security: Passwords must be securely hashed. Password hashes must never appear in API responses.

## 2. Catalogue Service

| Operation | Input | Output | Possible errors |
|---|---|---|---|
| `createProduct` | Farmer ID, name, category, price, quantity, unit | Product ID, product status | Invalid input, unauthorized |
| `getProduct` | Product ID | Product details | Product not found |
| `searchProducts` | Search term, category, page, page size | Matching products and pagination details | Invalid query |
| `updateProduct` | Product ID, permitted changes | Updated product | Product not found, forbidden |
| `checkAvailability` | Product IDs and requested quantities | Availability and current prices | Product not found, insufficient stock |

## 3. Orders Service

| Operation | Input | Output | Possible errors |
|---|---|---|---|
| `placeOrder` | Buyer ID, items, delivery address, idempotency key | Order ID, items, total, status | Invalid input, unauthorized, product unavailable, downstream failure |
| `getOrder` | Order ID, authenticated caller | Order details | Order not found, forbidden |
| `cancelOrder` | Order ID, authenticated caller, cancellation reason | Updated order status | Order not found, forbidden, illegal state |
| `updateOrderStatus` | Order ID, new status, authorized actor | Updated order | Order not found, invalid transition |

## 4. Payments Service

| Operation | Input | Output | Possible errors |
|---|---|---|---|
| `createPayment` | Order ID, amount, payment method token, idempotency key | Payment ID, payment status | Invalid amount, payment declined, duplicate request |
| `getPaymentStatus` | Payment ID or order ID | Payment status | Payment not found, forbidden |
| `refundPayment` | Payment ID, refund amount, authorized request | Refund status | Payment not found, refund not permitted, provider failure |

Sensitive payment details must not be stored or returned unnecessarily. Payment provider credentials must remain secret.

## 5. Delivery Service

| Operation | Input | Output | Possible errors |
|---|---|---|---|
| `createDelivery` | Order ID, delivery address, package details | Delivery ID, tracking number, status | Invalid input, duplicate delivery |
| `getDeliveryStatus` | Delivery ID or tracking number | Delivery status and latest tracking event | Delivery not found |
| `addTrackingEvent` | Delivery ID, location, description, event time | Created tracking event | Delivery not found, invalid event |

## 6. Administration Service

| Operation | Input | Output | Possible errors |
|---|---|---|---|
| `getPlatformReport` | Authorized admin identity, date range | Aggregated platform report | Unauthorized, invalid date range |
| `recordAdminAction` | Admin ID, action type, target reference, details | Audit record ID | Unauthorized, invalid action |

Administrative actions must be restricted to authorized administrators and recorded for audit purposes.

## 7. Cross-Service Rules

1. Each service owns its own data.
2. Services communicate through documented API contracts.
3. A service must not directly modify another service's database tables.
4. Errors returned by a downstream service must be mapped into the calling service's documented error format.
5. APIs must authenticate callers and enforce role-based permissions.
6. Retried order and payment requests must be handled safely to avoid unintended duplicates.

## 8. Contract Validation

The contracts define operations, input data, successful outputs, and expected failures. Detailed HTTP paths, JSON schemas, and exact status-code mappings can be specified in the service's OpenAPI document when that service is implemented.