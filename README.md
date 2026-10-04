#  UK E-commerce Customer & Sales Analytics — SQL

## Project overview

An advanced SQL portfolio project designed to answer realistic business questions for a UK e-commerce company.

The project analyses customer behaviour, sales performance, product profitability, regional performance, retention, RFM segments, churn risk and returns.

**Database:** PostgreSQL  
**Focus:** Advanced SQL + business analysis  
**Dataset:** Synthetic data created for portfolio/learning purposes

## Business questions

Which months and regions generate the most revenue?

 Which products drive revenue and gross profit?
 
Who are the highest-value customers?

Which customers are Champions, Loyal, At Risk or Hibernating?
 What is monthly and cohort customer retention?
 Which sales channel has stronger repeat purchasing?
 Which product categories have the highest return rates?
Which high-revenue products have weak margins?
Which customers are growing or declining month over month?

## Advanced SQL demonstrated

This project uses:

Multi-table JOINs
CTEs
 Window functions
 `LAG()` and `NTILE()`
 Ranking with `DENSE_RANK()`
 Cohort analysis
RFM segmentation
 Conditional aggregation with `FILTER`
 Percentile ranking with `PERCENT_RANK()`
 Date/time analysis
Customer retention analysis
 Churn-risk classification
 Profit and margin calculations

## Project structure

```text
sql-customer-sales-analytics/
├── data/
│   ├── customers.csv
│   ├── products.csv
│   ├── orders.csv
│   ├── order_items.csv
│   └── returns.csv
├── sql/
│   ├── schema.sql
│   ├── load_data.sql
│   └── analysis.sql
└── README.md
```

## How to run

1. Install PostgreSQL.
2. Create a database, for example `ecommerce_analytics`.
3. Run `sql/schema.sql`.
4. Run `sql/load_data.sql` from `psql`.
5. Open `sql/analysis.sql` and run the queries individually.

Example:

```sql
CREATE DATABASE ecommerce_analytics;
```

Then:

```bash
psql -d ecommerce_analytics -f sql/schema.sql
psql -d ecommerce_analytics -f sql/load_data.sql
```

## What this project demonstrates

This project goes beyond basic `SELECT`, `WHERE` and `GROUP BY` queries. It demonstrates how SQL can be used to solve practical commercial problems and turn transactional data into management insights.

### Portfolio highlights

**Customer analytics:** RFM segmentation, lifetime value and churn-risk analysis.

**Retention analytics:** monthly retention and cohort retention matrices.

**Commercial analytics:** revenue, AOV, gross profit and margin analysis.

**Product analytics:** Pareto contribution, product profitability and return rates.

**Advanced SQL:** CTEs, window functions, ranking, conditional aggregation and date-based analysis.

## Data note

All data is synthetic and created specifically for this portfolio project. It is not presented as real company or live UK e-commerce data.

## Future improvements

 Connect the SQL model to Power BI
 Add an automated ETL pipeline
Add customer acquisition cost and marketing data
Add forecasting
Add an interactive executive dashboard
 Rebuild the analysis in a cloud warehouse such as BigQuery or Snowflake

## Author

Computer Science student building a portfolio for **Data Analyst / Business Analyst / BI internship opportunities**.

Skills: **SQL • Python • Data Analysis • Data Visualisation • Business Intelligence**
