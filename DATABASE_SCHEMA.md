# ShopFast Database Schema Documentation

This document describes the PostgreSQL database schema used in the Grafana alerting demo.

## Database Overview

**Database Name**: `shopfast`  
**User**: `shopfast`  
**Port**: 5432 (inside Docker: `postgres:5432`)

## Tables

### 1. `products` - Product Inventory

The main table for inventory management and low stock alerts.

#### Schema
```sql
CREATE TABLE products (
    id SERIAL PRIMARY KEY,                    -- Unique product ID
    name VARCHAR(100) NOT NULL,               -- Product name
    description TEXT,                         -- Product description
    price DECIMAL(10, 2) NOT NULL,            -- Product price
    stock_level INTEGER NOT NULL DEFAULT 0,   -- Current stock level ⚠️
    low_stock_threshold INTEGER NOT NULL DEFAULT 10,  -- Alert threshold ⚠️
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP  -- Last stock update
);
```

#### Sample Data
| id | name | stock_level | low_stock_threshold | price |
|----|------|-------------|---------------------|-------|
| 1 | Gaming Laptop | 50 | 10 | 1299.99 |
| 2 | Wireless Mouse | 150 | 20 | 29.99 |
| 3 | Mechanical Keyboard | 75 | 15 | 89.99 |
| 4 | USB-C Hub | 200 | 30 | 49.99 |
| 5 | External SSD 1TB | 30 | 8 | 119.99 |
| 6 | Webcam 4K | 25 | 5 | 149.99 |
| 7 | Noise-Canceling Headphones | 40 | 10 | 299.99 |
| 8 | Monitor 27" | 20 | 5 | 399.99 |
| 9 | Laptop Stand | 100 | 15 | 39.99 |
| 10 | Phone Charger | 300 | 50 | 24.99 |

#### Key concepts
- **`stock_level`**: Current inventory (decreases with orders)
- **`low_stock_threshold`**: When to trigger low inventory alert
- **Alert fires when**: `stock_level <= low_stock_threshold`

#### Useful Queries
```sql
-- Products currently low on stock
SELECT name, stock_level, low_stock_threshold 
FROM products 
WHERE stock_level <= low_stock_threshold;

-- Products ordered by stock level (lowest first)
SELECT name, stock_level, low_stock_threshold,
       (stock_level - low_stock_threshold) as buffer
FROM products 
ORDER BY stock_level ASC;

-- Inventory value
SELECT 
  SUM(stock_level * price) as total_inventory_value,
  SUM(stock_level) as total_units
FROM products;
```

---

### 2. `orders` - Order History

Tracks customer orders and inventory changes.

#### Schema
```sql
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,                    -- Order ID
    product_id INTEGER REFERENCES products(id), -- Which product
    quantity INTEGER NOT NULL,                -- How many ordered
    total_amount DECIMAL(10, 2) NOT NULL,    -- Order value
    order_status VARCHAR(50) NOT NULL,        -- Status (completed, pending, failed)
    order_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP  -- When ordered
);
```

#### Key Concepts
- Each order **decrements** the `stock_level` in the `products` table
- Used for revenue tracking and order analysis
- Shows customer demand patterns

#### Useful Queries
```sql
-- Recent orders
SELECT 
  o.id,
  p.name as product_name,
  o.quantity,
  o.total_amount,
  o.order_status,
  o.order_time
FROM orders o
JOIN products p ON o.product_id = p.id
ORDER BY o.order_time DESC
LIMIT 10;

-- Orders per hour (for traffic analysis)
SELECT 
  date_trunc('hour', order_time) as hour,
  COUNT(*) as order_count,
  SUM(total_amount) as revenue
FROM orders
GROUP BY date_trunc('hour', order_time)
ORDER BY hour DESC;

-- Most popular products
SELECT 
  p.name,
  COUNT(*) as times_ordered,
  SUM(o.quantity) as total_units_sold,
  SUM(o.total_amount) as total_revenue
FROM orders o
JOIN products p ON o.product_id = p.id
GROUP BY p.name
ORDER BY total_revenue DESC;
```

---

### 3. `customers` - Customer Information

Sample customer data for the e-commerce platform.

#### Schema
```sql
CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    email VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### Sample Data
| id | email | name |
|----|-------|------|
| 1 | john.doe@example.com | John Doe |
| 2 | jane.smith@example.com | Jane Smith |
| 3 | bob.wilson@example.com | Bob Wilson |
| 4 | alice.brown@example.com | Alice Brown |
| 5 | charlie.davis@example.com | Charlie Davis |

---

### 4. `login_attempts` - Security Monitoring

Tracks login attempts for security alerting (brute force detection).

#### Schema
```sql
CREATE TABLE login_attempts (
    id SERIAL PRIMARY KEY,
    email VARCHAR(100) NOT NULL,              -- User attempting login
    ip_address VARCHAR(50),                   -- Source IP
    success BOOLEAN NOT NULL,                 -- Login succeeded?
    attempt_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP  -- When
);
```

#### Key concepts
- Used for **Security Alert**: "Multiple Failed Login Attempts"
- Alert fires when: ≥5 failed attempts in 5 minutes for same email
- Demonstrates **threat detection** and **security monitoring**

#### Useful Queries
```sql
-- Failed login attempts in last 5 minutes
SELECT 
  email,
  COUNT(*) as failed_attempts,
  MAX(attempt_time) as last_attempt
FROM login_attempts 
WHERE success = false 
  AND attempt_time > NOW() - INTERVAL '5 minutes'
GROUP BY email
HAVING COUNT(*) >= 5
ORDER BY failed_attempts DESC;

-- Login success rate by user
SELECT 
  email,
  COUNT(*) as total_attempts,
  SUM(CASE WHEN success THEN 1 ELSE 0 END) as successful,
  ROUND(100.0 * SUM(CASE WHEN success THEN 1 ELSE 0 END) / COUNT(*), 2) as success_rate
FROM login_attempts
GROUP BY email
ORDER BY success_rate ASC;

-- Recent login activity
SELECT 
  email,
  ip_address,
  success,
  attempt_time
FROM login_attempts
ORDER BY attempt_time DESC
LIMIT 20;
```

---

## Database Views

### `low_stock_products` - Pre-filtered Low Stock Items

Convenient view for quickly checking inventory alerts.

```sql
CREATE VIEW low_stock_products AS
SELECT 
  id, 
  name, 
  stock_level, 
  low_stock_threshold, 
  (low_stock_threshold - stock_level) as units_below_threshold
FROM products
WHERE stock_level <= low_stock_threshold
ORDER BY stock_level ASC;
```

**Usage:**
```sql
SELECT * FROM low_stock_products;
```

### `order_stats_hourly` - Aggregated Order Statistics

Pre-aggregated hourly order data.

```sql
CREATE VIEW order_stats_hourly AS
SELECT 
  date_trunc('hour', order_time) as hour,
  COUNT(*) as order_count,
  SUM(total_amount) as total_revenue,
  AVG(total_amount) as avg_order_value
FROM orders
GROUP BY date_trunc('hour', order_time)
ORDER BY hour DESC;
```

---

## Indexes

Performance optimizations for alert queries:

```sql
-- Fast inventory checks
CREATE INDEX idx_products_stock_level ON products(stock_level);

-- Fast order time queries
CREATE INDEX idx_orders_order_time ON orders(order_time);

-- Fast login attempt time queries
CREATE INDEX idx_login_attempts_time ON login_attempts(attempt_time);
```

---

## Alert Query Examples

### Low Inventory Alert (Warning)
```sql
SELECT 
  NOW() as time,
  COUNT(*) as value
FROM products
WHERE stock_level <= low_stock_threshold
```
**Fires when**: Any product is at or below its threshold

### Critical Inventory Alert
```sql
SELECT 
  NOW() as time,
  COUNT(*) as value
FROM products
WHERE stock_level <= 5
```
**Fires when**: Any product has ≤5 units remaining

### Security Alert - Brute Force Detection
```sql
SELECT 
  NOW() as time,
  COUNT(DISTINCT email) as value
FROM login_attempts 
WHERE success = false 
  AND attempt_time > NOW() - INTERVAL '5 minutes'
GROUP BY email
HAVING COUNT(*) >= 5
```
**Fires when**: 5+ failed logins for same user in 5 minutes

---

## Quick Reference Commands

### Explore Database in Grafana
1. Go to **Explore**
2. Select **PostgreSQL**
3. Run queries above

### Connect from Command Line
```bash
docker exec -it shopfast-postgres psql -U shopfast -d shopfast
```

### Useful One-Liners
```sql
-- Current inventory status
SELECT COUNT(*) as total_products,
       SUM(stock_level) as total_units,
       COUNT(*) FILTER (WHERE stock_level <= low_stock_threshold) as low_stock_count
FROM products;

-- System health check
SELECT 
  'products' as table_name, COUNT(*) as rows FROM products
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'customers', COUNT(*) FROM customers
UNION ALL
SELECT 'login_attempts', COUNT(*) FROM login_attempts;
```

---

## Data Relationships

```
customers
    ↓ (places)
orders ←→ products (updates stock_level)
    
login_attempts → monitors security for customers
```

