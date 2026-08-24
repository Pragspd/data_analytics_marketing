/*row count*/

SELECT 'meta_ads_campaigns' AS table_name, COUNT(*) AS row_count
FROM dbo.meta_ads_campaigns

UNION ALL

SELECT 'orders_clean', COUNT(*)
FROM dbo.orders_clean

UNION ALL

SELECT 'customers', COUNT(*)
FROM dbo.customers

UNION ALL

SELECT 'order_line_items', COUNT(*)
FROM dbo.order_line_items

UNION ALL

SELECT 'website_sessions_clean', COUNT(*)
FROM dbo.website_sessions_clean;

/*duplicate keys*/
-- Orders
SELECT Order_ID, COUNT(*) AS cnt
FROM dbo.orders_clean
GROUP BY Order_ID
HAVING COUNT(*) > 1;

-- Customers
SELECT Customer_ID, COUNT(*) AS cnt
FROM dbo.customers
GROUP BY Customer_ID
HAVING COUNT(*) > 1;

/*date ranges*/
SELECT
    'Meta Ads' AS dataset,
    MIN(date) AS min_date,
    MAX(date) AS max_date
FROM dbo.meta_ads_campaigns

UNION ALL

SELECT
    'Orders',
    MIN(Order_date_time),
    MAX(Order_date_time)
FROM dbo.orders_clean

UNION ALL

SELECT
    'Customers',
    MIN(First_order_date),
    MAX(Last_purchase_date)
FROM dbo.customers

UNION ALL

SELECT
    'Website Sessions',
    MIN(date),
    MAX(date)
FROM dbo.website_sessions_clean;

/*customer to order*/
SELECT COUNT(*) AS unmatched_orders
FROM dbo.orders_clean o
LEFT JOIN dbo.customers c
    ON o.Customer_ID = c.Customer_ID
WHERE c.Customer_ID IS NULL;

/*order to campaign*/
SELECT
    Channel_source_last_touch,
    COUNT(*) AS order_count
FROM dbo.orders_clean
GROUP BY Channel_source_last_touch
ORDER BY order_count DESC;

/*check for ks_alwayson*/
SELECT
    campaign_name,
    date,
    Amount_spent_INR
FROM dbo.meta_ads_campaigns
WHERE campaign_name LIKE '%Always%';
