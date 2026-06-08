-- 1. Membuat Database
CREATE DATABASE supermarket_db;
USE supermarket_db;

SET SQL_SAFE_UPDATES = 0;

-- 2. Pembersihan dan Standarisasi Data
-- Tabel Retail Customers
UPDATE retail_customers
SET email = CONCAT('user', id_customer, '@gmail.com')
WHERE email IS NULL OR email = '';

UPDATE retail_customers
SET no_hp = '0000000000'
WHERE no_hp IS NULL OR no_hp = '';

UPDATE retail_customers
SET kota = 'Tidak Diketahui'
WHERE kota IS NULL;

UPDATE retail_customers
SET email = LOWER(email);

UPDATE retail_customers
SET email = CONCAT('user', id_customer, '@gmail.com')
WHERE email NOT LIKE '%@%';

UPDATE retail_customers
SET no_hp = REGEXP_REPLACE(no_hp,'[^0-9]','');

-- Tabel Retail Products
UPDATE retail_products p
JOIN (
    -- Subquery untuk mencari rata-rata harga berdasarkan kategori
    SELECT kategori, AVG(harga) AS avg_harga
    FROM retail_products
    WHERE harga IS NOT NULL
    GROUP BY kategori
) sub ON p.kategori = sub.kategori
SET p.harga = sub.avg_harga
WHERE p.harga IS NULL;

-- Tabel Retail Transaction Items
UPDATE retail_transaction_items
SET quantity =(SELECT avg_qty
				FROM(SELECT ROUND(AVG(quantity)) AS avg_qty
					FROM retail_transaction_items)x)
WHERE quantity IS NULL;

-- Tabel Retail Transactions
DELETE FROM retail_transactions
WHERE id_customer IS NULL;

-- 3. Validasi Data dengan Regex
-- Tabel Retail Customers
SELECT *
FROM retail_customers
WHERE email NOT REGEXP
'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$';

SELECT *
FROM retail_customers
WHERE no_hp NOT REGEXP '^[0-9]{10,13}$';

-- 4. Membuat View
-- view customer_spending
CREATE VIEW view_customer_spending AS
SELECT
    c.id_customer,
    c.nama,
    COUNT(DISTINCT t.id_transaction) AS frekuensi_transaksi,
    SUM(p.harga * ti.quantity) AS total_belanja
FROM retail_customers c
JOIN retail_transactions t
    ON c.id_customer = t.id_customer
JOIN retail_transaction_items ti
    ON t.id_transaction = ti.id_transaction
JOIN retail_products p
    ON ti.id_product = p.id_product
GROUP BY c.id_customer, c.nama;

SELECT * FROM view_customer_spending;

-- view product_copurchase
CREATE VIEW view_product_copurchase AS
SELECT
    p1.nama_produk AS produk_1,
    p2.nama_produk AS produk_2,
    COUNT(*) AS jumlah_dibeli_bersama
FROM retail_transaction_items a
JOIN retail_transaction_items b
    ON a.id_transaction = b.id_transaction
    AND a.id_product < b.id_product
JOIN retail_products p1
    ON a.id_product = p1.id_product
JOIN retail_products p2
    ON b.id_product = p2.id_product
GROUP BY p1.nama_produk, p2.nama_produk;

SELECT *
FROM view_product_copurchase
ORDER BY jumlah_dibeli_bersama DESC;

-- view payment_behaviour
CREATE VIEW view_payment_behavior AS
SELECT
    metode,
    COUNT(*) AS jumlah_transaksi
FROM retail_transactions
GROUP BY metode;

SELECT * FROM view_payment_behavior;

-- view customer segmentation
CREATE VIEW view_customer_segmentation AS
SELECT
    c.id_customer,
    c.nama,
    SUM(p.harga * ti.quantity) AS total_belanja,
    CASE
        WHEN SUM(p.harga * ti.quantity) >= 5000000 THEN 'Platinum'
        WHEN SUM(p.harga * ti.quantity) >= 2000000 THEN 'Gold'
        ELSE 'Silver'
    END AS segmentasi
FROM retail_customers c
JOIN retail_transactions t
    ON c.id_customer = t.id_customer
JOIN retail_transaction_items ti
    ON t.id_transaction = ti.id_transaction
JOIN retail_products p
    ON ti.id_product = p.id_product
GROUP BY c.id_customer, c.nama;

SELECT * FROM view_customer_segmentation;


-- tambahan
DROP DATABASE supermarket_db;
DROP VIEW view_customer_spending;
DROP VIEW view_product_copurchase;
DROP VIEW view_payment_behavior;
DROP VIEW view_customer_segmentation;

