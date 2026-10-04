-- UK E-commerce Customer & Sales Analytics
-- PostgreSQL 14+

DROP TABLE IF EXISTS returns CASCADE;
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS customers CASCADE;

CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    signup_date DATE NOT NULL,
    region VARCHAR(50) NOT NULL,
    customer_segment VARCHAR(30) NOT NULL
);

CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(150) NOT NULL,
    category VARCHAR(50) NOT NULL,
    brand VARCHAR(50) NOT NULL,
    unit_price NUMERIC(10,2) NOT NULL CHECK (unit_price >= 0),
    cost_price NUMERIC(10,2) NOT NULL CHECK (cost_price >= 0)
);

CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT NOT NULL REFERENCES customers(customer_id),
    order_date DATE NOT NULL,
    channel VARCHAR(30) NOT NULL,
    payment_method VARCHAR(30) NOT NULL,
    status VARCHAR(30) NOT NULL,
    shipping_fee NUMERIC(10,2) NOT NULL DEFAULT 0,
    order_total NUMERIC(12,2) NOT NULL CHECK (order_total >= 0)
);

CREATE TABLE order_items (
    order_item_id INT PRIMARY KEY,
    order_id INT NOT NULL REFERENCES orders(order_id),
    product_id INT NOT NULL REFERENCES products(product_id),
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(10,2) NOT NULL,
    discount_pct NUMERIC(5,2) NOT NULL DEFAULT 0,
    line_total NUMERIC(12,2) NOT NULL
);

CREATE TABLE returns (
    return_id INT PRIMARY KEY,
    order_id INT NOT NULL REFERENCES orders(order_id),
    return_date DATE NOT NULL,
    reason VARCHAR(100) NOT NULL,
    refund_amount NUMERIC(12,2) NOT NULL CHECK (refund_amount >= 0)
);

CREATE INDEX idx_orders_customer_date ON orders(customer_id, order_date);
CREATE INDEX idx_orders_date_status ON orders(order_date, status);
CREATE INDEX idx_items_order ON order_items(order_id);
CREATE INDEX idx_items_product ON order_items(product_id);
CREATE INDEX idx_returns_order ON returns(order_id);
