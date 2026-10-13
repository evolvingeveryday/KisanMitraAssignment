# Kissan Mitra - Assignment 02
## Service Design, Contracts and Database Schema

## 1. System Overview

Kissan Mitra is a farmer-to-buyer marketplace. Farmers can publish agricultural products, buyers can browse products and place orders, and administrators can supervise users and platform activity.

## 2. Main Capabilities

1. User registration and authentication
2. Farmer profile and product listing management
3. Product browsing and category management
4. Order creation and order status management
5. Payment processing and payment status tracking
6. Delivery creation and shipment tracking
7. Administrative user and activity management

## 3. Service Boundaries and Data Ownership

| Service | Responsibilities | Owned data |
|---|---|---|
| User Management | Manage farmer, buyer and admin accounts | Users, account status |
| Catalogue | Manage products, categories and listings | Products, categories |
| Orders | Create and manage customer orders | Orders, order items |
| Payments | Record payment attempts and results | Payments, transactions |
| Delivery | Manage delivery and tracking | Deliveries, tracking events |
| Administration | Review platform activity and administrative actions | Admin action audit records |

Each service owns its data. Other services must not directly read or modify its database tables. Cross-service communication uses defined API contracts.

## 4. Service Communication

- User Management provides identity and account information to authorized consumers.
- Catalogue provides product details and availability information.
- Orders requests product validation from Catalogue before confirming an order.
- Orders requests payment processing from Payments.
- After an order is accepted, Orders requests a delivery record from Delivery.
- Administration uses authorized service APIs to review or manage platform activity.

Service-to-service calls must have documented inputs, outputs, and error responses.

## 5. API Contract Summary

| Service | Operation | Purpose |
|---|---|---|
| User Management | `registerUser` | Create a user account |
| User Management | `getUser` | Retrieve permitted user information |
| User Management | `updateUserStatus` | Activate or suspend an account |
| Catalogue | `createProduct` | Publish a product listing |
| Catalogue | `getProduct` | Retrieve product details |
| Catalogue | `searchProducts` | Search available listings |
| Catalogue | `updateProduct` | Update a product listing |
| Orders | `placeOrder` | Create an order |
| Orders | `getOrder` | Retrieve order details |
| Orders | `cancelOrder` | Request order cancellation |
| Orders | `updateOrderStatus` | Update an order's status |
| Payments | `createPayment` | Initiate a payment |
| Payments | `getPaymentStatus` | Retrieve payment status |
| Payments | `refundPayment` | Request a refund when permitted |
| Delivery | `createDelivery` | Create a delivery record |
| Delivery | `getDeliveryStatus` | Retrieve delivery status |
| Delivery | `addTrackingEvent` | Record a tracking update |
| Administration | `getPlatformReport` | Review platform activity |
| Administration | `recordAdminAction` | Record an administrative action |

## 6. Detailed Contract: placeOrder

**Purpose:** Create an order for products selected by a buyer.

**Input:**
- `buyerId`: identifier of the authenticated buyer
- `items`: list of product IDs and requested quantities
- `deliveryAddress`: destination address
- `idempotencyKey`: unique key to prevent duplicate orders on safe retries

**Processing:**
1. Authenticate the caller and verify buyer permissions.
2. Validate the item list and requested quantities.
3. Ask Catalogue to verify product availability and current prices.
4. Calculate the order total using validated prices.
5. Create the order and its order items.
6. Request payment processing through Payments.
7. Update the order according to the payment result.
8. Request delivery creation when the order reaches the appropriate state.

**Successful output:**
- `orderId`
- `buyerId`
- `items`
- `totalAmount`
- `status`
- `createdAt`

**Possible errors:**
- `400 Bad Request`: invalid input
- `401 Unauthorized`: authentication is missing or invalid
- `403 Forbidden`: caller is not allowed to place this order
- `404 Not Found`: a requested product does not exist
- `409 Conflict`: product is unavailable or the request conflicts with current state
- `502 Bad Gateway` or `503 Service Unavailable`: a required downstream service is unavailable

The implementation must define how failed payment or downstream requests affect order state. It must not create duplicate orders when the same idempotency key is retried.

## 7. Database Design Principles

- Every table has a primary key.
- Foreign keys are used for relationships within a database boundary.
- Separate services do not share database tables.
- Cross-service identifiers are validated through APIs rather than cross-database foreign keys.
- Passwords are stored as secure hashes, never as plain text.
- Administrative actions are recorded for auditability.

## 8. Validation Checklist

- Every service has a clear responsibility.
- Each service owns its data.
- Service operations have documented contracts.
- Cross-service communication uses APIs.
- Database entities have defined columns and keys.
- `placeOrder` includes input, processing, output, and failure cases.
- Service boundaries are reviewed to minimize coupling.