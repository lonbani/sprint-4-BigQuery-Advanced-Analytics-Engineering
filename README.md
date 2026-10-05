# Sprint 4 - BigQuery Advanced & Analytics Engineering

This repository contains my **Sprint 4 project** for the Data Analytics specialization at IT Academy Barcelona.

The project focuses on advanced SQL, BigQuery performance optimization, analytics engineering, automation, and business intelligence visualization.

## Project Objectives

The main goal of this sprint was to improve the performance and cost efficiency of an analytical environment while building reusable and automated data pipelines for business reporting.

The project covers:

- BigQuery query optimization
- Partitioning and clustering
- Query cost analysis using Dry Run
- Materialized Views
- Common Table Expressions (CTEs)
- Window Functions
- Running totals and trend analysis
- Advanced filtering with `QUALIFY`
- Array processing with `UNNEST`
- User Defined Functions (UDFs)
- Scheduled Queries
- Looker Studio dashboards

## Technologies Used

- Google BigQuery
- SQL
- Looker Studio
- GitHub

## Main Exercises

### 1. BigQuery Optimization

Analyzed the computational cost of non-optimized queries and created an optimized transaction table using:

- Partitioning by transaction date
- Clustering by `business_id`
- BigQuery Dry Run for cost comparison

The optimization reduced the amount of data processed from approximately **21.56 MB to 6.9 MB**, representing about **68% savings**.

### 2. Materialized Views

Created a Materialized View to store daily sales aggregations and avoid repeatedly calculating the same metrics from the base transaction table.

This view was later reused for financial trend analysis.

### 3. Advanced Analytical SQL

Implemented advanced SQL techniques including:

- VIP customer profiling using CTEs
- Day-over-Day sales growth using `LAG()`
- Year-to-Date cumulative sales using window functions
- Customer purchase ranking using `ROW_NUMBER()`
- Filtering window function results with `QUALIFY`

### 4. Data Flattening with UNNEST

Created a flattened transaction table by expanding the `product_ids` array with:

`CROSS JOIN UNNEST()`

The flattened model provides one row per product sold and enriches transaction data with product information.

### 5. User Defined Function (UDF)

Created a persistent BigQuery UDF:

`calculate_tax(amount)`

The function centralizes the VAT calculation and is used to generate the product price including VAT.

### 6. Pipeline Automation

Configured a BigQuery Scheduled Query to automatically regenerate the analytical table every day at **07:00**.

This provides refreshed data for downstream reporting without requiring manual execution.

### 7. Looker Studio Dashboard

Created a **Sales Performance Monitor** dashboard connected to the final BigQuery table.

The dashboard includes:

- Total Revenue including VAT
- Number of unique transactions
- Average transaction value
- Daily revenue evolution
- Top-selling products
- Revenue by product
- VAT collected

## Repository Contents

- `SQL` - SQL queries used throughout the project
- `PDF` - Project documentation, query results, and screenshots
- `README.md` - Project overview

## Key Skills Demonstrated

`BigQuery` `SQL` `Analytics Engineering` `Data Modeling` `Query Optimization` `Window Functions` `CTEs` `UNNEST` `UDF` `Scheduled Queries` `Looker Studio` `Data Visualization`

---

**Author:** Mahnaz Lonbani  
**Data Analytics - IT Academy Barcelona**
