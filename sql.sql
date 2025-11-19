CREATE TABLE staging.stg_sales_test (
  transaction_id VARCHAR PRIMARY KEY,
  transaction_date TIMESTAMP,
  store_id INT,
  product_id INT,
  customer_id INT,
  quantity INT,
  unit_price NUMERIC(12,2),
  discount_amt NUMERIC(12,2)
);

SELECT * FROM information_schema.tables
WHERE table_schema='staging';

INSERT INTO staging.stg_sales_test 
VALUES ('T001', NOW(), 1, 10, 100, 2, 299.99, 0);

SELECT * FROM staging.stg_sales_test;

CREATE TABLE IF NOT EXISTS staging.stg_products (
  product_id INT PRIMARY KEY,
  product_name VARCHAR(255),
  category VARCHAR(50),
  brand VARCHAR(50),
  cost_price NUMERIC(10,2),
  list_price NUMERIC(10,2)
);

CREATE TABLE IF NOT EXISTS staging.stg_customers (
  customer_id INT PRIMARY KEY,
  first_name VARCHAR(100),
  last_name VARCHAR(100),
  email VARCHAR(255),
  city VARCHAR(100),
  state VARCHAR(100),
  signup_date DATE,
  customer_segment VARCHAR(20)
);

CREATE TABLE IF NOT EXISTS staging.stg_stores (
  store_id INT PRIMARY KEY,
  store_name VARCHAR(255),
  city VARCHAR(100),
  state VARCHAR(100),
  region VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS staging.stg_date_dim (
  date_key INT PRIMARY KEY,
  date DATE,
  year INT,
  quarter INT,
  month INT,
  day INT,
  weekday INT,
  is_weekend INT
);

CREATE TABLE IF NOT EXISTS staging.stg_sales_transactions (
  transaction_id VARCHAR PRIMARY KEY,
  transaction_date TIMESTAMP,
  store_id INT,
  product_id INT,
  customer_id INT,
  quantity INT,
  unit_price NUMERIC(12,2),
  discount_amt NUMERIC(12,2),
  payment_type VARCHAR(20),
  sales_channel VARCHAR(20),
  line_total NUMERIC(14,2)
);

SELECT COUNT(*) FROM staging.stg_products;
SELECT COUNT(*) FROM staging.stg_customers;
SELECT COUNT(*) FROM staging.stg_stores;
SELECT COUNT(*) FROM staging.stg_date_dim;
SELECT COUNT(*) FROM staging.stg_sales_transactions;

SELECT * FROM staging.stg_products LIMIT 5;
SELECT * FROM staging.stg_sales_transactions ORDER BY transaction_date DESC LIMIT 5;

SELECT 'sales' AS table, COUNT(*) FROM staging.stg_sales_transactions;
SELECT 'products' AS table, COUNT(*) FROM staging.stg_products;
SELECT 'customers' AS table, COUNT(*) FROM staging.stg_customers;
SELECT 'stores' AS table, COUNT(*) FROM staging.stg_stores;
SELECT 'date_dim' AS table, COUNT(*) FROM staging.stg_date_dim;

-- create dimension & fact tables (warehouse schema)
CREATE SCHEMA IF NOT EXISTS warehouse;

CREATE TABLE IF NOT EXISTS warehouse.dim_date (
  date_key INT PRIMARY KEY,
  date DATE,
  year INT,
  quarter INT,
  month INT,
  day INT,
  weekday INT,
  is_weekend INT
);

CREATE TABLE IF NOT EXISTS warehouse.dim_product (
  product_id INT PRIMARY KEY,
  product_name VARCHAR(255),
  category VARCHAR(50),
  brand VARCHAR(50),
  cost_price NUMERIC(10,2),
  list_price NUMERIC(10,2)
);

CREATE TABLE IF NOT EXISTS warehouse.dim_customer (
  customer_id INT PRIMARY KEY,
  first_name VARCHAR(100),
  last_name VARCHAR(100),
  email VARCHAR(255),
  city VARCHAR(100),
  state VARCHAR(100),
  signup_date DATE,
  customer_segment VARCHAR(20)
);

CREATE TABLE IF NOT EXISTS warehouse.dim_store (
  store_id INT PRIMARY KEY,
  store_name VARCHAR(255),
  city VARCHAR(100),
  state VARCHAR(100),
  region VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS warehouse.fact_sales (
  transaction_id VARCHAR PRIMARY KEY,
  date_key INT REFERENCES warehouse.dim_date(date_key),
  store_id INT REFERENCES warehouse.dim_store(store_id),
  product_id INT REFERENCES warehouse.dim_product(product_id),
  customer_id INT REFERENCES warehouse.dim_customer(customer_id),
  quantity INT,
  unit_price NUMERIC(12,2),
  discount_amt NUMERIC(12,2),
  payment_type VARCHAR(20),
  sales_channel VARCHAR(20),
  line_total NUMERIC(14,2)
);

-- dim_date
INSERT INTO warehouse.dim_date (date_key, date, year, quarter, month, day, weekday, is_weekend)
SELECT date_key, date::date, year, quarter, month, day, weekday, is_weekend
FROM staging.stg_date_dim
ON CONFLICT (date_key) DO NOTHING;

-- dim_product
INSERT INTO warehouse.dim_product (product_id, product_name, category, brand, cost_price, list_price)
SELECT product_id, product_name, category, brand, cost_price, list_price
FROM staging.stg_products
ON CONFLICT (product_id) DO NOTHING;

-- dim_customer
INSERT INTO warehouse.dim_customer (customer_id, first_name, last_name, email, city, state, signup_date, customer_segment)
SELECT customer_id, first_name, last_name, email, city, state, signup_date::date, customer_segment
FROM staging.stg_customers
ON CONFLICT (customer_id) DO NOTHING;

-- dim_store
INSERT INTO warehouse.dim_store (store_id, store_name, city, state, region)
SELECT store_id, store_name, city, state, region
FROM staging.stg_stores
ON CONFLICT (store_id) DO NOTHING;

-- missing FK references in staging sales (should be 0 ideally)
SELECT 'missing_products' AS check, COUNT(*) FROM staging.stg_sales_transactions s
LEFT JOIN warehouse.dim_product p ON s.product_id = p.product_id
WHERE p.product_id IS NULL;

SELECT 'missing_customers' AS check, COUNT(*) FROM staging.stg_sales_transactions s
LEFT JOIN warehouse.dim_customer c ON s.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

SELECT 'missing_stores' AS check, COUNT(*) FROM staging.stg_sales_transactions s
LEFT JOIN warehouse.dim_store st ON s.store_id = st.store_id
WHERE st.store_id IS NULL;

-- basic sanity
SELECT 'null_tx' AS check, COUNT(*) FROM staging.stg_sales_transactions WHERE transaction_id IS NULL;
SELECT 'bad_qty_or_price' AS check, COUNT(*) FROM staging.stg_sales_transactions WHERE quantity <= 0 OR unit_price <= 0;

INSERT INTO warehouse.fact_sales (
  transaction_id, date_key, store_id, product_id, customer_id,
  quantity, unit_price, discount_amt, payment_type, sales_channel, line_total
)
SELECT
  s.transaction_id,
  to_char(s.transaction_date::timestamp, 'YYYYMMDD')::int AS date_key,
  s.store_id, s.product_id, s.customer_id,
  s.quantity, s.unit_price, s.discount_amt, s.payment_type, s.sales_channel, s.line_total
FROM staging.stg_sales_transactions s
JOIN warehouse.dim_product p ON s.product_id = p.product_id
JOIN warehouse.dim_customer c ON s.customer_id = c.customer_id
JOIN warehouse.dim_store st ON s.store_id = st.store_id
JOIN warehouse.dim_date d ON to_char(s.transaction_date::timestamp,'YYYYMMDD')::int = d.date_key
ON CONFLICT (transaction_id) DO NOTHING;

SELECT 'fact_rows' AS metric, COUNT(*) FROM warehouse.fact_sales;
SELECT 'distinct_products' AS metric, COUNT(DISTINCT product_id) FROM warehouse.dim_product;
SELECT 'distinct_customers' AS metric, COUNT(DISTINCT customer_id) FROM warehouse.dim_customer;
SELECT MIN(date_key) AS min_datekey, MAX(date_key) AS max_datekey FROM warehouse.dim_date;

SELECT COUNT(*) FROM warehouse.fact_sales;

SELECT COUNT(*) FROM warehouse.dim_product;

SELECT COUNT(*) FROM warehouse.dim_customer;

SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_schema = 'warehouse'
ORDER BY table_name;

-- allow user to use the schema and create/select objects if needed
GRANT USAGE ON SCHEMA warehouse TO divya_user;
GRANT SELECT ON ALL TABLES IN SCHEMA warehouse TO divya_user;

-- also set default for any future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA warehouse GRANT SELECT ON TABLES TO divya_user;












