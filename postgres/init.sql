-- ShopFast E-commerce Database Schema

-- Products table
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    stock_level INTEGER NOT NULL DEFAULT 0,
    low_stock_threshold INTEGER NOT NULL DEFAULT 10,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Orders table
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    product_id INTEGER REFERENCES products(id),
    quantity INTEGER NOT NULL,
    total_amount DECIMAL(10, 2) NOT NULL,
    order_status VARCHAR(50) NOT NULL,
    order_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Customers table
CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    email VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Failed login attempts (for security alerting)
CREATE TABLE login_attempts (
    id SERIAL PRIMARY KEY,
    email VARCHAR(100) NOT NULL,
    ip_address VARCHAR(50),
    success BOOLEAN NOT NULL,
    attempt_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample products
INSERT INTO products (name, description, price, stock_level, low_stock_threshold) VALUES
('Gaming Laptop', 'High-performance gaming laptop', 1299.99, 50, 10),
('Wireless Mouse', 'Ergonomic wireless mouse', 29.99, 150, 20),
('Mechanical Keyboard', 'RGB mechanical keyboard', 89.99, 75, 15),
('USB-C Hub', '7-in-1 USB-C hub', 49.99, 200, 30),
('External SSD 1TB', 'Portable external SSD', 119.99, 30, 8),
('Webcam 4K', '4K webcam for streaming', 149.99, 25, 5),
('Noise-Canceling Headphones', 'Premium wireless headphones', 299.99, 40, 10),
('Monitor 27"', '27-inch 4K monitor', 399.99, 20, 5),
('Laptop Stand', 'Adjustable aluminum laptop stand', 39.99, 100, 15),
('Phone Charger', 'Fast charging USB-C charger', 24.99, 300, 50);

-- Insert sample customers
INSERT INTO customers (email, name) VALUES
('john.doe@example.com', 'John Doe'),
('jane.smith@example.com', 'Jane Smith'),
('bob.wilson@example.com', 'Bob Wilson'),
('alice.brown@example.com', 'Alice Brown'),
('charlie.davis@example.com', 'Charlie Davis');

-- Create index for faster queries
CREATE INDEX idx_products_stock_level ON products(stock_level);
CREATE INDEX idx_orders_order_time ON orders(order_time);
CREATE INDEX idx_login_attempts_time ON login_attempts(attempt_time);

-- View for low stock products (useful for Grafana queries)
CREATE VIEW low_stock_products AS
SELECT id, name, stock_level, low_stock_threshold, 
       (low_stock_threshold - stock_level) as units_below_threshold
FROM products
WHERE stock_level <= low_stock_threshold
ORDER BY stock_level ASC;

-- View for recent order stats
CREATE VIEW order_stats_hourly AS
SELECT 
    date_trunc('hour', order_time) as hour,
    COUNT(*) as order_count,
    SUM(total_amount) as total_revenue,
    AVG(total_amount) as avg_order_value
FROM orders
GROUP BY date_trunc('hour', order_time)
ORDER BY hour DESC;

