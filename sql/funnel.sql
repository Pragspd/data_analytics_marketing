SELECT
    campaign_name,
    SUM(sessions) AS sessions,
    SUM(product_views) AS product_views,

    SUM(CAST(add_to_cart AS int)) AS add_to_cart,
    SUM(CAST(begin_checkout AS int)) AS checkout,
    SUM(CAST(purchased AS int)) AS purchases,

    CAST(
        SUM(product_views) * 100.0 /
        NULLIF(SUM(sessions), 0)
        AS DECIMAL(5,2)
    ) AS view_rate,

    CAST(
        SUM(CAST(add_to_cart AS int)) * 100.0 /
        NULLIF(SUM(product_views), 0)
        AS DECIMAL(5,2)
    ) AS cart_rate,

    CAST(
        SUM(CAST(begin_checkout AS int)) * 100.0 /
        NULLIF(SUM(CAST(add_to_cart AS int)), 0)
        AS DECIMAL(5,2)
    ) AS checkout_rate,

    CAST(
        SUM(CAST(purchased AS int)) * 100.0 /
        NULLIF(SUM(CAST(begin_checkout AS int)), 0)
        AS DECIMAL(5,2)
    ) AS purchase_rate

FROM dbo.website_sessions_clean
WHERE campaign_name IS NOT NULL
GROUP BY campaign_name
ORDER BY sessions DESC;


/*Product Views ≥ Add to Cart ≥ Checkout ≥ Purchases*/
SELECT
    campaign_name,
    SUM(product_views) AS product_views,
    SUM(CAST(add_to_cart AS int)) AS add_to_cart,
    SUM(CAST(begin_checkout AS int)) AS checkout,
    SUM(CAST(purchased AS int)) AS purchases
FROM dbo.website_sessions_clean
WHERE campaign_name IS NOT NULL
GROUP BY campaign_name
HAVING
       SUM(CAST(add_to_cart AS int)) > SUM(product_views)
    OR SUM(CAST(begin_checkout AS int)) > SUM(CAST(add_to_cart AS int))
    OR SUM(CAST(purchased AS int)) > SUM(CAST(begin_checkout AS int));
