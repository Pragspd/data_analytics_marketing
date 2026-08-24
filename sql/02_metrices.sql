/*check for multiple campaign*/

SELECT
    order_id,
    COUNT(DISTINCT campaign_name) AS campaign_count
FROM dbo.website_sessions_clean
WHERE order_id IS NOT NULL
GROUP BY order_id
HAVING COUNT(DISTINCT campaign_name) > 1;

SELECT
    campaign_count,
    COUNT(*) AS order_count
FROM (
    SELECT
        order_id,
        COUNT(DISTINCT campaign_name) AS campaign_count
    FROM dbo.website_sessions_clean
    WHERE order_id IS NOT NULL
    GROUP BY order_id
) x
WHERE campaign_count > 1
GROUP BY campaign_count
ORDER BY campaign_count;

/*cac and roas*/
WITH SingleCampaignOrders AS (
    SELECT
        order_id,
        MAX(campaign_name) AS campaign_name
    FROM dbo.website_sessions_clean
    WHERE order_id IS NOT NULL
      AND campaign_name IS NOT NULL
    GROUP BY order_id
    HAVING COUNT(DISTINCT campaign_name) = 1
),

CampaignPerformance AS (
    SELECT
        s.campaign_name,
        COUNT(DISTINCT o.Order_ID) AS total_orders,
        COUNT(DISTINCT CASE
            WHEN o.First_order_vs_repeat = 'First'
            THEN o.Customer_ID
        END) AS new_customers,
        SUM(o.Order_value_net) AS revenue
    FROM SingleCampaignOrders s
    INNER JOIN dbo.orders_clean o
        ON s.order_id = o.Order_ID
    GROUP BY s.campaign_name
)

SELECT
    m.campaign_name,
    m.Amount_spent_INR AS ad_spend,
    p.total_orders,
    p.new_customers,
    p.revenue,

    CAST(
        m.Amount_spent_INR * 1.0 /
        NULLIF(p.new_customers, 0)
        AS DECIMAL(10,2)
    ) AS CAC,

    CAST(
        p.revenue * 1.0 /
        NULLIF(m.Amount_spent_INR, 0)
        AS DECIMAL(10,2)
    ) AS ROAS

FROM dbo.meta_ads_campaigns m
INNER JOIN CampaignPerformance p
    ON m.campaign_name = p.campaign_name
ORDER BY ROAS DESC;
/*repeat rate*/
WITH SingleCampaignOrders AS (
    SELECT
        order_id,
        MAX(campaign_name) AS campaign_name
    FROM dbo.website_sessions_clean
    WHERE order_id IS NOT NULL
      AND campaign_name IS NOT NULL
    GROUP BY order_id
    HAVING COUNT(DISTINCT campaign_name) = 1
),
CampaignCustomers AS (
    SELECT DISTINCT
        s.campaign_name,
        o.Customer_ID
    FROM SingleCampaignOrders s
    INNER JOIN dbo.orders_clean o
        ON s.order_id = o.Order_ID
    WHERE o.First_order_vs_repeat = 'First'
)
SELECT
    cc.campaign_name,
    COUNT(DISTINCT cc.Customer_ID) AS acquired_customers,
    COUNT(DISTINCT CASE
        WHEN c.RePurchased = 'Y'
        THEN cc.Customer_ID
    END) AS repeat_customers,
    CAST(
        COUNT(DISTINCT CASE
            WHEN c.RePurchased = 'Y'
            THEN cc.Customer_ID
        END) * 100.0
        / NULLIF(COUNT(DISTINCT cc.Customer_ID), 0)
        AS DECIMAL(5,2)
    ) AS repeat_rate
FROM CampaignCustomers cc
INNER JOIN dbo.customers c
    ON cc.Customer_ID = c.Customer_ID
GROUP BY cc.campaign_name
ORDER BY repeat_rate DESC;

/*return rate*/
WITH SingleCampaignOrders AS (
    SELECT
        order_id,
        MAX(campaign_name) AS campaign_name
    FROM dbo.website_sessions_clean
    WHERE order_id IS NOT NULL
      AND campaign_name IS NOT NULL
    GROUP BY order_id
    HAVING COUNT(DISTINCT campaign_name) = 1
)
SELECT
    s.campaign_name,
    COUNT(*) AS total_items,
    SUM(
        CASE
            WHEN oli.Returned_Y_N = 'Y' THEN 1
            ELSE 0
        END
    ) AS returned_items,
    CAST(
        SUM(
            CASE
                WHEN oli.Returned_Y_N = 'Y' THEN 1
                ELSE 0
            END
        ) * 100.0 / NULLIF(COUNT(*), 0)
        AS DECIMAL(5,2)
    ) AS return_rate
FROM SingleCampaignOrders s
INNER JOIN dbo.order_line_items oli
    ON s.order_id = oli.Order_ID
GROUP BY s.campaign_name
ORDER BY return_rate DESC;
