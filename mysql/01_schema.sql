-- Olist source database (OLTP layer)
CREATE DATABASE IF NOT EXISTS olist_source
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE olist_source;

-- Children first, so the foreign keys don't block the drops
DROP TABLE IF EXISTS order_reviews, order_payments, order_items, orders,
                     products, sellers, customers, geolocation,
                     product_category_name_translation;

CREATE TABLE product_category_name_translation (
  product_category_name         VARCHAR(100) NOT NULL PRIMARY KEY,
  product_category_name_english VARCHAR(100) NOT NULL
);

CREATE TABLE customers (
  customer_id              VARCHAR(32) NOT NULL PRIMARY KEY,
  customer_unique_id       VARCHAR(32) NOT NULL,
  customer_zip_code_prefix CHAR(5),
  customer_city            VARCHAR(100),
  customer_state           CHAR(2),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
             ON UPDATE CURRENT_TIMESTAMP(6),
  INDEX idx_customers_unique (customer_unique_id),
  INDEX idx_customers_state (customer_state),
  INDEX idx_customers_updated (updated_at)
);

CREATE TABLE sellers (
  seller_id              VARCHAR(32) NOT NULL PRIMARY KEY,
  seller_zip_code_prefix CHAR(5),
  seller_city            VARCHAR(100),
  seller_state           CHAR(2),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
             ON UPDATE CURRENT_TIMESTAMP(6),
  INDEX idx_sellers_updated (updated_at)
);

CREATE TABLE products (
  product_id                 VARCHAR(32) NOT NULL PRIMARY KEY,
  product_category_name      VARCHAR(100),
  product_name_length        INT,
  product_description_length INT,
  product_photos_qty         INT,
  product_weight_g           INT,
  product_length_cm          INT,
  product_height_cm          INT,
  product_width_cm           INT,
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
             ON UPDATE CURRENT_TIMESTAMP(6),
  INDEX idx_products_category (product_category_name),
  INDEX idx_products_updated (updated_at)
);

-- No natural key and many repeated rows in the source, so we use a surrogate key.
CREATE TABLE geolocation (
  geolocation_id              BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  geolocation_zip_code_prefix CHAR(5) NOT NULL,
  geolocation_lat             DOUBLE,
  geolocation_lng             DOUBLE,
  geolocation_city            VARCHAR(100),
  geolocation_state           CHAR(2),
  INDEX idx_geo_zip (geolocation_zip_code_prefix)
);

CREATE TABLE orders (
  order_id                      VARCHAR(32) NOT NULL PRIMARY KEY,
  customer_id                   VARCHAR(32) NOT NULL,
  order_status                  VARCHAR(20) NOT NULL,
  order_purchase_timestamp      DATETIME NOT NULL,
  order_approved_at             DATETIME NULL,
  order_delivered_carrier_date  DATETIME NULL,
  order_delivered_customer_date DATETIME NULL,
  order_estimated_delivery_date DATETIME NULL,
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
             ON UPDATE CURRENT_TIMESTAMP(6),
  CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id)
    REFERENCES customers (customer_id),
  INDEX idx_orders_purchase (order_purchase_timestamp),
  INDEX idx_orders_status (order_status),
  INDEX idx_orders_customer (customer_id),
  INDEX idx_orders_updated (updated_at)
);

CREATE TABLE order_items (
  order_id            VARCHAR(32) NOT NULL,
  order_item_id       INT NOT NULL,
  product_id          VARCHAR(32) NOT NULL,
  seller_id           VARCHAR(32) NOT NULL,
  shipping_limit_date DATETIME NULL,
  price               DECIMAL(10,2) NOT NULL,
  freight_value       DECIMAL(10,2) NOT NULL,
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
             ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (order_id, order_item_id),
  CONSTRAINT fk_items_order   FOREIGN KEY (order_id)   REFERENCES orders (order_id),
  CONSTRAINT fk_items_product FOREIGN KEY (product_id) REFERENCES products (product_id),
  CONSTRAINT fk_items_seller  FOREIGN KEY (seller_id)  REFERENCES sellers (seller_id),
  INDEX idx_items_product (product_id),
  INDEX idx_items_seller (seller_id),
  INDEX idx_items_updated (updated_at)
);

CREATE TABLE order_payments (
  order_id             VARCHAR(32) NOT NULL,
  payment_sequential   INT NOT NULL,
  payment_type         VARCHAR(20) NOT NULL,
  payment_installments INT NOT NULL,
  payment_value        DECIMAL(10,2) NOT NULL,
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
             ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (order_id, payment_sequential),
  CONSTRAINT fk_payments_order FOREIGN KEY (order_id) REFERENCES orders (order_id),
  INDEX idx_payments_updated (updated_at)
);

-- review_id is NOT unique in the source data, so we add a surrogate key.
-- (dbt will dedupe and test this in the staging layer.)
CREATE TABLE order_reviews (
  review_pk               BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  review_id               VARCHAR(32) NOT NULL,
  order_id                VARCHAR(32) NOT NULL,
  review_score            TINYINT NOT NULL,
  review_comment_title    VARCHAR(255),
  review_comment_message  TEXT,
  review_creation_date    DATETIME,
  review_answer_timestamp DATETIME,
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
             ON UPDATE CURRENT_TIMESTAMP(6),
  CONSTRAINT fk_reviews_order FOREIGN KEY (order_id) REFERENCES orders (order_id),
  INDEX idx_reviews_review_id (review_id),
  INDEX idx_reviews_order (order_id),
  INDEX idx_reviews_updated (updated_at)
);