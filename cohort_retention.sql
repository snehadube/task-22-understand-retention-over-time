-- =====================================================================
-- Task   : Cohort Retention Basics (Veda Technology - Data Analytics)
-- Dataset: Online Retail II (online_retail_II.csv)
-- DB     : PostgreSQL (run in pgAdmin Query Tool)
-- =====================================================================

-- STEP 1: Raw table (InvoiceDate is imported as TEXT first, converted later)
DROP TABLE IF EXISTS retail_raw CASCADE;
CREATE TABLE retail_raw (
    invoice      VARCHAR(20),
    stockcode    VARCHAR(30),
    description  TEXT,
    quantity     INT,
    invoicedate  VARCHAR(30),      -- e.g. 12/1/10 8:26
    price        NUMERIC(10,2),
    customer_id  NUMERIC,          -- CSV has 17850.0 (decimal), blank = NULL
    country      VARCHAR(60)
);

-- STEP 2: Import the CSV (pgAdmin: right-click table > Import/Export Data...)
--   Filename: online_retail_II.csv | Format: csv | Header: ON
--   Delimiter: , | Quote: " | Escape: " | Encoding: LATIN1 (WIN1252)
-- Check:
SELECT COUNT(*) AS total_rows FROM retail_raw;          -- expect 541910

-- STEP 3: Clean data (drop NULL customers, cancellations, bad qty/price)
DROP VIEW IF EXISTS retail_clean CASCADE;
CREATE VIEW retail_clean AS
SELECT
    invoice,
    customer_id::INT                                        AS customer_id,
    quantity,
    price,
    to_timestamp(invoicedate, 'MM/DD/YY HH24:MI')::DATE     AS invoice_date,
    DATE_TRUNC('month', to_timestamp(invoicedate, 'MM/DD/YY HH24:MI'))::DATE AS order_month
FROM retail_raw
WHERE customer_id IS NOT NULL
  AND invoice NOT LIKE 'C%'
  AND quantity > 0
  AND price > 0
  AND to_timestamp(invoicedate, 'MM/DD/YY HH24:MI') < TIMESTAMP '2011-12-01';
  -- ^ data ends 9-Dec-2011, so December 2011 is an incomplete month: excluded

SELECT COUNT(*) AS clean_rows, COUNT(DISTINCT customer_id) AS customers
FROM retail_clean;                                       -- expect see Python output (same numbers)

-- STEP 4: Cohort = month of the customer's FIRST purchase
DROP VIEW IF EXISTS customer_cohort CASCADE;
CREATE VIEW customer_cohort AS
SELECT customer_id, MIN(order_month) AS cohort_month
FROM retail_clean
GROUP BY customer_id;

-- STEP 5: Activity table with cohort_index (months since first purchase)
DROP VIEW IF EXISTS cohort_activity CASCADE;
CREATE VIEW cohort_activity AS
SELECT DISTINCT
    c.cohort_month,
    r.customer_id,
    (EXTRACT(YEAR  FROM r.order_month) - EXTRACT(YEAR  FROM c.cohort_month)) * 12
  + (EXTRACT(MONTH FROM r.order_month) - EXTRACT(MONTH FROM c.cohort_month)) AS cohort_index
FROM retail_clean r
JOIN customer_cohort c USING (customer_id);

-- STEP 6: Cohort table (unique active customers) - long format
DROP VIEW IF EXISTS cohort_counts CASCADE;
CREATE VIEW cohort_counts AS
SELECT cohort_month, cohort_index::INT AS cohort_index,
       COUNT(DISTINCT customer_id) AS active_customers
FROM cohort_activity
GROUP BY cohort_month, cohort_index;

-- STEP 7: Retention % = active customers / cohort size
DROP VIEW IF EXISTS cohort_retention CASCADE;
CREATE VIEW cohort_retention AS
SELECT cc.cohort_month,
       cc.cohort_index,
       cc.active_customers,
       s.cohort_size,
       ROUND(100.0 * cc.active_customers / s.cohort_size, 1) AS retention_pct
FROM cohort_counts cc
JOIN (SELECT cohort_month, active_customers AS cohort_size
      FROM cohort_counts WHERE cohort_index = 0) s USING (cohort_month);

-- STEP 8: Final cohort table (wide format, retention %) -> use for heatmap
SELECT TO_CHAR(cohort_month, 'YYYY-MM') AS cohort,
       MAX(cohort_size) AS cohort_size,
       MAX(CASE WHEN cohort_index = 0  THEN retention_pct END) AS m0,
       MAX(CASE WHEN cohort_index = 1  THEN retention_pct END) AS m1,
       MAX(CASE WHEN cohort_index = 2  THEN retention_pct END) AS m2,
       MAX(CASE WHEN cohort_index = 3  THEN retention_pct END) AS m3,
       MAX(CASE WHEN cohort_index = 4  THEN retention_pct END) AS m4,
       MAX(CASE WHEN cohort_index = 5  THEN retention_pct END) AS m5,
       MAX(CASE WHEN cohort_index = 6  THEN retention_pct END) AS m6,
       MAX(CASE WHEN cohort_index = 7  THEN retention_pct END) AS m7,
       MAX(CASE WHEN cohort_index = 8  THEN retention_pct END) AS m8,
       MAX(CASE WHEN cohort_index = 9  THEN retention_pct END) AS m9,
       MAX(CASE WHEN cohort_index = 10 THEN retention_pct END) AS m10,
       MAX(CASE WHEN cohort_index = 11 THEN retention_pct END) AS m11
FROM cohort_retention
GROUP BY cohort_month
ORDER BY cohort_month;

-- STEP 9: Average retention per month index (insight query)
SELECT cohort_index AS month_n,
       ROUND(AVG(retention_pct), 1) AS avg_retention_pct
FROM cohort_retention
WHERE cohort_index > 0
GROUP BY cohort_index
ORDER BY cohort_index;

-- STEP 10: Export result (pgAdmin: run STEP 8 > Save results to file icon > CSV)
