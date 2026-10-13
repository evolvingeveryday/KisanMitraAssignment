
-- Kissan Mitra - Assignment 02
-- PostgreSQL-compatible logical service schemas
-- Cross-service IDs are validated through APIs, not foreign keys.

-- =====================================================
-- SERVICE 1: USER MANAGEMENT
-- Owns: users
-- =====================================================

CREATE TABLE users (
    user_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone VARCHAR(20),
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL
        CHECK (role IN ('FARMER', 'BUYER', 'ADMIN')),
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE'
        CHECK (status IN ('ACTIVE', 'SUSPENDED', 'PENDING')),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- SERVICE 2: CATALOGUE
-- Owns: categories, products
-- farmer_id is a User Management service ID.
-- =====================================================

CREATE TABLE categories (
    category_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT
);

CREATE TABLE products (
    product_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    farmer_id BIGINT NOT NULL,
    category_id BIGINT REFERENCES categories(category_id),
    name VARCHAR(150) NOT NULL,
    description TEXT,
    price NUMERIC(12, 2) NOT NULL CHECK (price >= 0),
    quantity NUMERIC(12, 3) NOT NULL CHECK (quantity >= 0),
    unit VARCHAR(30) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE'
        CHECK (status IN ('ACTIVE', 'INACTIVE', 'REVIEW')),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- SERVICE 3: ORDERS
-- Owns: orders, order_items
-- buyer_id belongs to User Management.
-- product_id belongs to Catalogue.
-- =====================================================

CREATE TABLE orders (
    order_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    buyer_id BIGINT NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'PLACED'
        CHECK (status IN (
            'PLACED', 'CONFIRMED', 'PROCESSING',
            'SHIPPED', 'DELIVERED', 'CANCELLED',
            'PAYMENT_FAILED'
        )),
    total_amount NUMERIC(12, 2) NOT NULL
        CHECK (total_amount >= 0),
    delivery_address TEXT NOT NULL,
    idempotency_key VARCHAR(150) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (buyer_id, idempotency_key)
);

CREATE TABLE order_items (
    order_item_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES orders(order_id),
    product_id BIGINT NOT NULL,
    quantity NUMERIC(12, 3) NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(12, 2) NOT NULL CHECK (unit_price >= 0)
);

-- =====================================================
-- SERVICE 4: PAYMENTS
-- Owns: payments
-- order_id belongs to the Orders service.
-- =====================================================

CREATE TABLE payments (
    payment_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id BIGINT NOT NULL,
    amount NUMERIC(12, 2) NOT NULL CHECK (amount >= 0),
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING'
        CHECK (status IN (
            'PENDING', 'SUCCESS', 'FAILED', 'REFUNDED'
        )),
    transaction_ref VARCHAR(150) UNIQUE,
    idempotency_key VARCHAR(150) NOT NULL UNIQUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- SERVICE 5: DELIVERY
-- Owns: deliveries, tracking_events
-- order_id belongs to the Orders service.
-- =====================================================

CREATE TABLE deliveries (
    delivery_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id BIGINT NOT NULL UNIQUE,
    status VARCHAR(30) NOT NULL DEFAULT 'PENDING'
        CHECK (status IN (
            'PENDING', 'ASSIGNED', 'IN_TRANSIT',
            'DELIVERED', 'FAILED'
        )),
    tracking_number VARCHAR(100) UNIQUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE tracking_events (
    event_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    delivery_id BIGINT NOT NULL REFERENCES deliveries(delivery_id),
    location VARCHAR(255),
    description TEXT NOT NULL,
    event_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- SERVICE 6: ADMINISTRATION
-- Owns: admin_actions
-- admin_user_id belongs to User Management.
-- =====================================================

CREATE TABLE admin_actions (
    action_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    admin_user_id BIGINT NOT NULL,
    action_type VARCHAR(100) NOT NULL,
    target_type VARCHAR(50) NOT NULL,
    target_id BIGINT,
    details TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- INDEXES
-- =====================================================

CREATE INDEX idx_products_farmer_id
    ON products(farmer_id);

CREATE INDEX idx_products_category_id
    ON products(category_id);

CREATE INDEX idx_products_status
    ON products(status);

CREATE INDEX idx_orders_buyer_id
    ON orders(buyer_id);

CREATE INDEX idx_orders_status
    ON orders(status);

CREATE INDEX idx_order_items_order_id
    ON order_items(order_id);

CREATE INDEX idx_payments_order_id
    ON payments(order_id);

CREATE INDEX idx_deliveries_order_id
    ON deliveries(order_id);

CREATE INDEX idx_tracking_events_delivery_id
    ON tracking_events(delivery_id);

CREATE INDEX idx_admin_actions_admin_user_id
    ON admin_actions(admin_user_id);
