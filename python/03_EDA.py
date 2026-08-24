orders["order_month"] = orders["Order_date_time"].dt.to_period("M")

monthly_orders = (
    orders.groupby("order_month")
    .agg(
        orders=("Order_ID", "nunique"),
        revenue=("Order_value_net", "sum")
    )
    .reset_index()
)

display(monthly_orders.head())

import matplotlib.pyplot as plt

plt.figure(figsize=(12, 5))
plt.plot(monthly_orders["order_month"].astype(str), monthly_orders["revenue"])
plt.xticks(rotation=45)
plt.title("Monthly Revenue Trend")
plt.xlabel("Month")
plt.ylabel("Revenue (INR)")
plt.tight_layout()
plt.show()

campaign_spend = (
    meta_ads.groupby("campaign_name")["Amount_spent_INR"]
    .sum()
    .sort_values(ascending=False)
    .head(10)
)

campaign_spend

plt.figure(figsize=(10, 5))
campaign_spend.sort_values().plot(kind="barh")
plt.title("Top 10 Campaigns by Ad Spend")
plt.xlabel("Ad Spend (INR)")
plt.ylabel("Campaign")
plt.tight_layout()
plt.show()
