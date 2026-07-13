CREATE TABLE orders (
    id          UUID PRIMARY KEY,
    customer_id UUID        NOT NULL REFERENCES customers (id),
    status      VARCHAR(20) NOT NULL,
    total_cents BIGINT      NOT NULL
);

CREATE INDEX idx_orders_customer_id ON orders (customer_id);

CREATE TABLE order_items (
    order_id    UUID   NOT NULL REFERENCES orders (id),
    product_id  UUID   NOT NULL,
    quantity    INT    NOT NULL,
    price_cents BIGINT NOT NULL
);

CREATE INDEX idx_order_items_order_id ON order_items (order_id);
