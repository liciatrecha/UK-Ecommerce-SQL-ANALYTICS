from pathlib import Path
import sqlite3
import pandas as pd

ROOT=Path(__file__).resolve().parent
DB=ROOT/"ecommerce.db"
DATA=ROOT/"data"
OUT=ROOT/"outputs"
OUT.mkdir(exist_ok=True)

if DB.exists(): DB.unlink()
conn=sqlite3.connect(DB)
conn.executescript((ROOT/"sql/schema.sql").read_text())

for name in ["customers","products","orders","order_items","returns"]:
    pd.read_csv(DATA/f"{name}.csv").to_sql(name,conn,if_exists="append",index=False)

kpi=pd.read_sql_query("""
WITH s AS (
 SELECT oi.order_id,SUM(oi.quantity*oi.unit_price*(1-oi.discount)) revenue
 FROM order_items oi JOIN orders o ON o.order_id=oi.order_id
 WHERE o.status='Completed' GROUP BY oi.order_id)
SELECT COUNT(*) completed_orders,ROUND(SUM(revenue),2) revenue,
       ROUND(AVG(revenue),2) avg_order_value FROM s;
""",conn)

segments=pd.read_sql_query("""
WITH cs AS (
 SELECT o.customer_id,MAX(o.order_date) last_order_date,
 COUNT(DISTINCT o.order_id) frequency,
 SUM(oi.quantity*oi.unit_price*(1-oi.discount)) monetary
 FROM orders o JOIN order_items oi ON oi.order_id=o.order_id
 WHERE o.status='Completed' GROUP BY o.customer_id),
rfm AS (
 SELECT *,NTILE(5) OVER(ORDER BY last_order_date) r,
 NTILE(5) OVER(ORDER BY frequency) f,NTILE(5) OVER(ORDER BY monetary) m
 FROM cs)
SELECT CASE
 WHEN r>=4 AND f>=4 AND m>=4 THEN 'Champions'
 WHEN r>=4 AND f>=3 THEN 'Loyal Customers'
 WHEN r>=4 AND f<=2 THEN 'New / Promising'
 WHEN r<=2 AND f>=3 THEN 'At Risk'
 ELSE 'Needs Attention' END segment,
 COUNT(*) customers,ROUND(AVG(monetary),2) avg_customer_value
FROM rfm GROUP BY segment ORDER BY avg_customer_value DESC;
""",conn)

category=pd.read_sql_query("""
SELECT p.category,SUM(oi.quantity) units_sold,
ROUND(SUM(oi.quantity*oi.unit_price*(1-oi.discount)),2) revenue
FROM products p JOIN order_items oi ON oi.product_id=p.product_id
JOIN orders o ON o.order_id=oi.order_id
WHERE o.status='Completed'
GROUP BY p.category ORDER BY revenue DESC;
""",conn)

monthly=pd.read_sql_query("""
SELECT substr(o.order_date,1,7) month,
ROUND(SUM(oi.quantity*oi.unit_price*(1-oi.discount)),2) revenue
FROM orders o JOIN order_items oi ON oi.order_id=o.order_id
WHERE o.status='Completed' GROUP BY month ORDER BY month;
""",conn)

kpi.to_csv(OUT/"executive_kpis.csv",index=False)
segments.to_csv(OUT/"customer_segments.csv",index=False)
category.to_csv(OUT/"category_performance.csv",index=False)
monthly.to_csv(OUT/"monthly_revenue.csv",index=False)

print("\n"+"="*70)
print("UK E-COMMERCE SQL ANALYTICS | RUN SUCCESSFUL")
print("="*70)
print("\nEXECUTIVE KPIs")
print(kpi.to_string(index=False))
print("\nCUSTOMER SEGMENTS")
print(segments.to_string(index=False))
print("\nCATEGORY PERFORMANCE")
print(category.to_string(index=False))
print("\nCreated: ecommerce.db")
print("Created: outputs/*.csv")
print("\nNext: open sql/analysis.sql to show the advanced SQL.")
conn.close()
