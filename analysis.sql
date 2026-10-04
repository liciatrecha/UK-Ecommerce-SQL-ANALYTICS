/*
UK E-COMMERCE CUSTOMER & SALES ANALYTICS
Advanced PostgreSQL analysis

Business questions:
1. What are monthly revenue and order trends?
2. Which regions generate the most revenue?
3. Which products drive revenue and gross profit?
4. Which customers are high-value?
5. What is customer RFM status?
6. What is monthly customer retention?
7. What is cohort retention?
8. Which customers appear at risk of churn?
9. Which acquisition/sign-up cohorts have the strongest LTV?
10. Which channel has the best AOV and repeat purchase rate?
11. What is return rate by category?
12. Which products have high revenue but weak margins?
*/

-- 1) Monthly revenue, orders, AOV and gross profit
WITH order_profit AS (
    SELECT
        o.order_id,
        DATE_TRUNC('month', o.order_date)::date AS month,
        o.order_total,
        SUM(oi.quantity * (oi.unit_price * (1 - oi.discount_pct)) - oi.quantity * p.cost_price) AS gross_profit
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    JOIN products p ON p.product_id = oi.product_id
    WHERE o.status = 'Completed'
    GROUP BY o.order_id, o.order_date, o.order_total
)
SELECT
    month,
    COUNT(*) AS orders,
    ROUND(SUM(order_total), 2) AS revenue,
    ROUND(AVG(order_total), 2) AS aov,
    ROUND(SUM(gross_profit), 2) AS gross_profit,
    ROUND(100.0 * SUM(gross_profit) / NULLIF(SUM(order_total),0), 2) AS gross_margin_pct
FROM order_profit
GROUP BY month
ORDER BY month;


-- 2) Regional performance ranking
WITH region_sales AS (
    SELECT
        c.region,
        COUNT(DISTINCT o.order_id) AS orders,
        COUNT(DISTINCT o.customer_id) AS customers,
        SUM(o.order_total) AS revenue
    FROM orders o
    JOIN customers c ON c.customer_id = o.customer_id
    WHERE o.status = 'Completed'
    GROUP BY c.region
)
SELECT
    region,
    orders,
    customers,
    ROUND(revenue, 2) AS revenue,
    ROUND(revenue / NULLIF(customers,0), 2) AS revenue_per_customer,
    DENSE_RANK() OVER (ORDER BY revenue DESC) AS revenue_rank
FROM region_sales
ORDER BY revenue DESC;


-- 3) Product revenue, units, profit and Pareto contribution
WITH product_perf AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        SUM(oi.quantity) AS units_sold,
        SUM(oi.line_total) AS revenue,
        SUM(oi.line_total - (oi.quantity * p.cost_price)) AS gross_profit
    FROM order_items oi
    JOIN orders o ON o.order_id = oi.order_id
    JOIN products p ON p.product_id = oi.product_id
    WHERE o.status = 'Completed'
    GROUP BY p.product_id, p.product_name, p.category
),
ranked AS (
    SELECT *,
           SUM(revenue) OVER () AS total_revenue,
           SUM(revenue) OVER (
               ORDER BY revenue DESC
               ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
           ) AS cumulative_revenue
    FROM product_perf
)
SELECT
    product_id,
    product_name,
    category,
    units_sold,
    ROUND(revenue,2) AS revenue,
    ROUND(gross_profit,2) AS gross_profit,
    ROUND(100.0 * gross_profit / NULLIF(revenue,0),2) AS margin_pct,
    ROUND(100.0 * cumulative_revenue / NULLIF(total_revenue,0),2) AS cumulative_revenue_pct
FROM ranked
ORDER BY revenue DESC;


-- 4) Customer lifetime value and rank
WITH customer_value AS (
    SELECT
        c.customer_id,
        c.region,
        c.customer_segment,
        COUNT(DISTINCT o.order_id) AS orders,
        MIN(o.order_date) AS first_order,
        MAX(o.order_date) AS last_order,
        SUM(o.order_total) AS revenue
    FROM customers c
    JOIN orders o ON o.customer_id = c.customer_id
    WHERE o.status = 'Completed'
    GROUP BY c.customer_id, c.region, c.customer_segment
)
SELECT
    *,
    ROUND(revenue / NULLIF(orders,0),2) AS avg_order_value,
    DENSE_RANK() OVER (ORDER BY revenue DESC) AS customer_value_rank
FROM customer_value
ORDER BY revenue DESC
LIMIT 100;


-- 5) RFM segmentation using quintiles
WITH base AS (
    SELECT
        c.customer_id,
        CURRENT_DATE - MAX(o.order_date) AS recency_days,
        COUNT(DISTINCT o.order_id) AS frequency,
        SUM(o.order_total) AS monetary
    FROM customers c
    JOIN orders o ON o.customer_id = c.customer_id
    WHERE o.status = 'Completed'
    GROUP BY c.customer_id
),
scores AS (
    SELECT *,
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency) AS f_score,
        NTILE(5) OVER (ORDER BY monetary) AS m_score
    FROM base
)
SELECT
    customer_id,
    recency_days,
    frequency,
    ROUND(monetary,2) AS monetary,
    r_score,
    f_score,
    m_score,
    CASE
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
        WHEN r_score >= 4 AND f_score >= 3 THEN 'Loyal Customers'
        WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
        WHEN r_score <= 2 AND f_score <= 2 THEN 'Hibernating'
        ELSE 'Potential Loyalists'
    END AS rfm_segment
FROM scores
ORDER BY monetary DESC;


-- 6) Customer churn-risk flag
WITH customer_dates AS (
    SELECT
        customer_id,
        MAX(order_date) AS last_order_date,
        COUNT(*) AS completed_orders,
        SUM(order_total) AS lifetime_revenue
    FROM orders
    WHERE status = 'Completed'
    GROUP BY customer_id
)
SELECT
    c.customer_id,
    c.region,
    cd.last_order_date,
    CURRENT_DATE - cd.last_order_date AS days_since_last_order,
    cd.completed_orders,
    ROUND(cd.lifetime_revenue,2) AS lifetime_revenue,
    CASE
        WHEN CURRENT_DATE - cd.last_order_date > 180 THEN 'High Risk'
        WHEN CURRENT_DATE - cd.last_order_date > 90 THEN 'Medium Risk'
        ELSE 'Active'
    END AS churn_risk
FROM customer_dates cd
JOIN customers c ON c.customer_id = cd.customer_id
ORDER BY days_since_last_order DESC;


-- 7) Monthly repeat-customer rate
WITH customer_months AS (
    SELECT DISTINCT
        customer_id,
        DATE_TRUNC('month', order_date)::date AS month
    FROM orders
    WHERE status = 'Completed'
),
with_previous AS (
    SELECT
        customer_id,
        month,
        LAG(month) OVER (PARTITION BY customer_id ORDER BY month) AS previous_active_month
    FROM customer_months
)
SELECT
    month,
    COUNT(*) AS active_customers,
    COUNT(*) FILTER (
        WHERE previous_active_month = (month - INTERVAL '1 month')::date
    ) AS returning_customers,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE previous_active_month = (month - INTERVAL '1 month')::date
        ) / NULLIF(COUNT(*),0), 2
    ) AS monthly_retention_pct
FROM with_previous
GROUP BY month
ORDER BY month;


-- 8) Cohort retention matrix
WITH first_order AS (
    SELECT customer_id, DATE_TRUNC('month', MIN(order_date))::date AS cohort_month
    FROM orders
    WHERE status = 'Completed'
    GROUP BY customer_id
),
activity AS (
    SELECT DISTINCT
        o.customer_id,
        f.cohort_month,
        DATE_TRUNC('month', o.order_date)::date AS activity_month
    FROM orders o
    JOIN first_order f ON f.customer_id = o.customer_id
    WHERE o.status = 'Completed'
),
cohort AS (
    SELECT
        cohort_month,
        ((EXTRACT(YEAR FROM activity_month) - EXTRACT(YEAR FROM cohort_month)) * 12
          + EXTRACT(MONTH FROM activity_month) - EXTRACT(MONTH FROM cohort_month))::int AS month_number,
        COUNT(DISTINCT customer_id) AS active_customers
    FROM activity
    GROUP BY cohort_month, month_number
),
cohort_sizes AS (
    SELECT cohort_month, MAX(active_customers) FILTER (WHERE month_number = 0) AS cohort_size
    FROM cohort
    GROUP BY cohort_month
)
SELECT
    c.cohort_month,
    c.month_number,
    c.active_customers,
    ROUND(100.0 * c.active_customers / NULLIF(s.cohort_size,0),2) AS retention_pct
FROM cohort c
JOIN cohort_sizes s USING (cohort_month)
ORDER BY c.cohort_month, c.month_number;


-- 9) Channel performance with repeat-purchase rate
WITH customer_channel AS (
    SELECT
        customer_id,
        channel,
        COUNT(*) AS orders
    FROM orders
    WHERE status = 'Completed'
    GROUP BY customer_id, channel
),
channel_summary AS (
    SELECT
        channel,
        COUNT(*) AS customers,
        SUM(orders) AS orders,
        COUNT(*) FILTER (WHERE orders >= 2) AS repeat_customers
    FROM customer_channel
    GROUP BY channel
)
SELECT
    channel,
    customers,
    orders,
    ROUND(100.0 * repeat_customers / NULLIF(customers,0),2) AS repeat_customer_pct
FROM channel_summary
ORDER BY repeat_customer_pct DESC;


-- 10) Return rate by category
WITH sold AS (
    SELECT
        p.category,
        COUNT(DISTINCT o.order_id) AS completed_orders
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    JOIN products p ON p.product_id = oi.product_id
    WHERE o.status = 'Completed'
    GROUP BY p.category
),
returned AS (
    SELECT
        p.category,
        COUNT(DISTINCT r.order_id) AS returned_orders
    FROM returns r
    JOIN order_items oi ON oi.order_id = r.order_id
    JOIN products p ON p.product_id = oi.product_id
    GROUP BY p.category
)
SELECT
    s.category,
    s.completed_orders,
    COALESCE(r.returned_orders,0) AS returned_orders,
    ROUND(100.0 * COALESCE(r.returned_orders,0) / NULLIF(s.completed_orders,0),2) AS return_rate_pct
FROM sold s
LEFT JOIN returned r USING (category)
ORDER BY return_rate_pct DESC;


-- 11) High-revenue / low-margin products: management watchlist
WITH product_metrics AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        SUM(oi.line_total) AS revenue,
        SUM(oi.line_total - oi.quantity * p.cost_price) AS gross_profit
    FROM products p
    JOIN order_items oi ON oi.product_id = p.product_id
    JOIN orders o ON o.order_id = oi.order_id
    WHERE o.status = 'Completed'
    GROUP BY p.product_id, p.product_name, p.category
),
benchmarked AS (
    SELECT *,
        PERCENT_RANK() OVER (ORDER BY revenue) AS revenue_percentile,
        100.0 * gross_profit / NULLIF(revenue,0) AS margin_pct
    FROM product_metrics
)
SELECT
    product_id,
    product_name,
    category,
    ROUND(revenue,2) AS revenue,
    ROUND(margin_pct,2) AS margin_pct
FROM benchmarked
WHERE revenue_percentile >= 0.75
  AND margin_pct < 25
ORDER BY revenue DESC;


-- 12) Customer-level month-over-month revenue movement
WITH monthly_customer AS (
    SELECT
        customer_id,
        DATE_TRUNC('month', order_date)::date AS month,
        SUM(order_total) AS revenue
    FROM orders
    WHERE status = 'Completed'
    GROUP BY customer_id, DATE_TRUNC('month', order_date)
),
movement AS (
    SELECT
        customer_id,
        month,
        revenue,
        LAG(revenue) OVER (PARTITION BY customer_id ORDER BY month) AS previous_month_revenue
    FROM monthly_customer
)
SELECT
    customer_id,
    month,
    ROUND(revenue,2) AS revenue,
    ROUND(COALESCE(previous_month_revenue,0),2) AS previous_month_revenue,
    ROUND(revenue - COALESCE(previous_month_revenue,0),2) AS revenue_change,
    CASE
        WHEN previous_month_revenue IS NULL THEN 'New'
        WHEN revenue > previous_month_revenue THEN 'Growing'
        WHEN revenue < previous_month_revenue THEN 'Declining'
        ELSE 'Stable'
    END AS customer_status
FROM movement
ORDER BY month, customer_id;
