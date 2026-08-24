/*for export*/
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
    JOIN dbo.orders_clean o
        ON s.order_id = o.Order_ID
    GROUP BY s.campaign_name
),

RepeatQuality AS (
    SELECT
        s.campaign_name,
        COUNT(DISTINCT o.Customer_ID) AS acquired_customers,
        COUNT(DISTINCT CASE
            WHEN c.RePurchased = 'Y'
            THEN o.Customer_ID
        END) AS repeat_customers
    FROM SingleCampaignOrders s
    JOIN dbo.orders_clean o
        ON s.order_id = o.Order_ID
    JOIN dbo.customers c
        ON o.Customer_ID = c.Customer_ID
    WHERE o.First_order_vs_repeat = 'First'
    GROUP BY s.campaign_name
),

ReturnQuality AS (
    SELECT
        s.campaign_name,
        COUNT(*) AS total_items,
        SUM(CASE
            WHEN oli.Returned_Y_N = 'Y' THEN 1
            ELSE 0
        END) AS returned_items
    FROM SingleCampaignOrders s
    JOIN dbo.order_line_items oli
        ON s.order_id = oli.Order_ID
    GROUP BY s.campaign_name
),

Funnel AS (
    SELECT
        campaign_name,
        SUM(sessions) AS sessions,
        SUM(product_views) AS product_views,
        SUM(CAST(add_to_cart AS int)) AS add_to_cart,
        SUM(CAST(begin_checkout AS int)) AS checkout,
        SUM(CAST(purchased AS int)) AS purchases
    FROM dbo.website_sessions_clean
    WHERE campaign_name IS NOT NULL
    GROUP BY campaign_name
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
    ) AS ROAS,

    r.acquired_customers,
    r.repeat_customers,

    CAST(
        r.repeat_customers * 100.0 /
        NULLIF(r.acquired_customers, 0)
        AS DECIMAL(5,2)
    ) AS repeat_rate,

    rq.total_items,
    rq.returned_items,

    CAST(
        rq.returned_items * 100.0 /
        NULLIF(rq.total_items, 0)
        AS DECIMAL(5,2)
    ) AS return_rate,

    CAST(
        (
            r.repeat_customers * 100.0 /
            NULLIF(r.acquired_customers, 0)
        )
        -
        (
            rq.returned_items * 100.0 /
            NULLIF(rq.total_items, 0)
        )
        AS DECIMAL(5,2)
    ) AS customer_quality_score,

    f.sessions,
    f.product_views,
    f.add_to_cart,
    f.checkout,
    f.purchases,

    CAST(
        f.add_to_cart * 100.0 /
        NULLIF(f.product_views, 0)
        AS DECIMAL(5,2)
    ) AS cart_rate,

    CAST(
        f.checkout * 100.0 /
        NULLIF(f.add_to_cart, 0)
        AS DECIMAL(5,2)
    ) AS checkout_rate,

    CAST(
        f.purchases * 100.0 /
        NULLIF(f.checkout, 0)
        AS DECIMAL(5,2)
    ) AS purchase_rate

FROM dbo.meta_ads_campaigns m
JOIN CampaignPerformance p
    ON m.campaign_name = p.campaign_name
JOIN RepeatQuality r
    ON m.campaign_name = r.campaign_name
JOIN ReturnQuality rq
    ON m.campaign_name = rq.campaign_name
JOIN Funnel f
    ON m.campaign_name = f.campaign_name

ORDER BY ROAS DESC;
