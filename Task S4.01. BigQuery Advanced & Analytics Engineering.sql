-- Level 1: Hybrid Environment and Ingestion (Code-First)
-- Exercise 1: Query on Non-Optimized Table (Diagnostic)
-- The Country Manager for Germany urgently needs to review the transactions of March 12, 2022 .
-- 1. Write the query that joins ( JOIN) transactions and companies.
-- 2. Filter the results by the indicated date and the country "Germany".
--» 3. Without executing the query, perform a "Dry Run" (cost audit).
select *
from `sprint3-analytics-mahnaz.sprint3_silver.transactions_clean` AS tr
join `sprint3-analytics-mahnaz.sprint3_silver.companies_clean` AS co
on tr.business_id=co.company_id
where co.country= 'Germany' AND date(tr.timestamp)= '2022-03-12';


-- Exercise 2: Re-architecture and Storage Optimization (Partition & Cluster)
-- Step 1:  Generating Recent Data (  Mocking  Data)  
-- Create an intermediate  table  called   sprint3_ silver.transactions _recent  from   the  sprint3_ silver.transactions _clean table .
--  Your goal is to keep  all the  columns ,  but replace the  original timestamp  with a new one,  randomly generated so that it falls  within the  last  50 days . 

create or replace table `sprint3-analytics-mahnaz.sprint3_silver.transactions_recent` AS
select * 
       except(timestamp),
       TIMESTAMP_SUB(
       CURRENT_TIMESTAMP(),
       INTERVAL CAST(FLOOR(RAND() * 50) AS INT64) DAY
       ) AS timestamp
from `sprint3-analytics-mahnaz.sprint3_silver.transactions_clean`;


-- Step 2:  Creating  the  Optimized Table  (Partitioning & Clustering) 
-- Now,  create your  final  table sprint3_ gold.fact _transactions_optimized from  the  recent data  you  just generated in  transactions_recent.
-- You need to  construct  the DDL statement to configure the table  with thenfollowing physical storage strategies    
--Partitioning : Divides the table by the date in the DATE(timestamp) field. This will allow queries that filter by day ( WHERE date = ...) to only read the necessary partition.
-- Clustering : Sorts the data within each partition by business_id. This will dramatically speed up filters by company and intersections ( JOINs) with the companies dimension.
create or replace table `sprint3-analytics-mahnaz.sprint3_gold.fact_transactions_optimized` 
partition by date(timestamp)
cluster by business_id
AS 
select *
from `sprint3-analytics-mahnaz.sprint3_silver.transactions_recent`;



-- Exercise 3: The Cotton Test (Benchmark)
--Step 1 (Non-optimized table): Point your query to the table sprint3_silver.transactions_recent.
-- Observe the validator and take a screenshot of the bytes it would process.

select *
from `sprint3-analytics-mahnaz.sprint3_silver.transactions_recent`
where date(timestamp) >= date_sub(current_date(), interval 30 day);



--Step 2 (Optimized table): Without changing anything in your query logic,
-- just modify it FROMso that it now points to the partitioned table sprint3_gold.fact_transactions_optimized.
-- Observe how the validator changes and take the second capture.
select *
from `sprint3-analytics-mahnaz.sprint3_gold.fact_transactions_optimized`
where date(timestamp) >= date_sub(current_date(), interval 30 day);



-- Exercise 4: Smart Caching (Materialized Views)
--  Create a Materialized View named sprint3_gold.mv_daily_salesthat displays Total Sales by Day .


create materialized view `sprint3-analytics-mahnaz.sprint3_gold.mv_daily_sales`
AS
select date(timestamp) AS date, sum(amount) AS total_sales_per_day
from `sprint3-analytics-mahnaz.sprint3_gold.fact_transactions_optimized`
group by date(timestamp);

select *
from `sprint3-analytics-mahnaz.sprint3_gold.mv_daily_sales`
order by date;



--Level 2: Advanced Analytical SQL
--Exercise 1: VIP Customer Profiling (Aggregated Metrics with CTEs)
--1. Create a CTE called VIP_Stats that groups by user and calculates :
--Total Expense (SUM).
--The Quantity of Transactions (COUNT).
--The Average Ticket (AVG), rounded to 2 decimal places.
--The Maximum Purchase (MAX).
--Filter: Keep only those whose Total Expense is > 500.
with VIP_Stats AS (
  select user_id,
         sum (amount) AS Total_Expense,
         count(transaction_id) AS num_purchases,
         round(avg(amount), 2) AS Average_Ticket,
         max(amount) AS Maximum_Purchase
  from `sprint3-analytics-mahnaz.sprint3_gold.fact_transactions_optimized`
  group by user_id
  having Total_Expense>500
)
-- Cross the CTE with users_combined to obtain the personal data.
--Columns: user_id, full_name, email, num_purchases, average_ticket, max_purchase, total_spent.
-- Sorted by total_spent descending.
select us.user_id, concat(us.name, ' ', us.surname) AS full_name, us.email,
      vi.num_purchases, vi.Average_Ticket, vi.Maximum_Purchase, vi.Total_Expense  

from `sprint3-analytics-mahnaz.sprint3_silver.users_combined` as us
join VIP_Stats as vi 
on us.user_id =vi.user_id
order by vi.Total_Expense desc;


-- Exercise 2: Trend Analysis (Window Functions on Views)
-- Create a query on the materialized view that generates a report with the following 4 columns:
--» 1. Date : The date of sale.
--» 2. Sales_Today : The total sold that day.
--» 3. Sales_Yesterday : The total sold the previous day (using window functions).
--» 4. Diff_Percentual : The percentage of growth or decrease compared to the previous day, rounded to 2 decimal places.

WITH Sales_Trend AS
(
    SELECT
        date,
        total_sales_per_day AS Sales_Today,
        LAG(total_sales_per_day) OVER(ORDER BY date) AS Sales_Yesterday
    FROM `sprint3-analytics-mahnaz.sprint3_gold.mv_daily_sales`
)
SELECT
    date,
    Sales_Today,
    Sales_Yesterday,
    ROUND(
        SAFE_DIVIDE(
            Sales_Today - Sales_Yesterday,
            Sales_Yesterday
        ) * 100,
        2
    ) AS Diff_Percentual
FROM Sales_Trend
ORDER BY date;




--Exercise 3: Running Totals (Running Totals on Views)
--Using the materialized view mv_daily_sales(to avoid recalculating base aggregations), generate a report with three columns:
--» 1. Date .
--» 2. Sales of the Day : Rounded to 2 decimal places.
--» 3. Cumulative Sales YTD : A progressive sum of sales that must be restarted every January 1. The final result must be rounded to 2 decimal places.

 select date,
        round(total_sales_per_day, 2) AS Sales_of_the_Day,
        round (sum(total_sales_per_day) over(partition by extract(year from date)
                                       order by date
                                       rows between unbounded preceding AND current ROW), 2) AS Cumulative_Sales_YTD 
 from `sprint3-analytics-mahnaz.sprint3_gold.mv_daily_sales`
 order by date;

-- Exercise 4: Customer Loyalty and Value (Advanced Filtering)
-- Generates a list of users who have reached (or exceeded) their third purchase, showing:
--» 1. User data (user_id, full_name, email) .
--» 2. The date and exact amount of the 3rd purchase .
--» 3. Average of the first 3 : The average spend of your transactions 1, 2 and 3.

with Customer_third_purchase AS 
(
  select user_id, timestamp, amount,
         row_number() over(
                           partition by user_id
                           order by timestamp
                           ) AS purchase_rank
  from `sprint3-analytics-mahnaz.sprint3_silver.transactions_clean`
  qualify row_number() over(
                           partition by user_id
                           order by timestamp
                           ) <=3
)
select us.user_id, concat(us.name, ' ', us.surname) AS full_name, us.email,
       ctp.timestamp, ctp.amount,
       round(avg(ctp.amount) over(partition by ctp.user_id), 2)  AS avrage_3_purches
       
from `sprint3-analytics-mahnaz.sprint3_silver.users_combined` AS us
join Customer_third_purchase AS ctp
on us.user_id=ctp.user_id
qualify purchase_rank=3;


--Level 3: Analytics Engineering (Arrays & Automation)
--Exercise 1: Unnesting and Flattening Data (Unnesting)
-- Create the table dim_transactions_flatby denormalizing the information. You need to "explode" the product array and cross-reference it with the master catalog to get the individual names and prices.
--» 1. Use CROSS JOIN UNNEST(product_ids)to transform the Array into individual rows.
--» 2. Perform a query JOINon the products table to obtain the name and price of each item.
--» 3. Don't group the result. We want to see the breakdown line by line.


create or replace table `sprint3-analytics-mahnaz.sprint3_gold.dim_transactions_flat` AS 
(
  select tr.transaction_id, tr.timestamp, tr.amount, p.product_id As product_sku, p.name as product_name, p.price as product_price
  from `sprint3-analytics-mahnaz.sprint3_silver.transactions_clean` AS tr
  cross join unnest(tr.product_ids) AS product_id
  join `sprint3-analytics-mahnaz.sprint3_silver.products_clean` as p
  on product_id = SAFE_CAST(p.product_id AS INT64)
);

select *
from `sprint3-analytics-mahnaz.sprint3_gold.dim_transactions_flat`
order by transaction_id;


--Exercise 2: Sales Ranking (Simple Aggregation)
--Generates the Top 5 best-selling products in the company's history.
--Consulta directament la teva nova taula desnormalitzada (dim_transactions_flat).
--» En ser la taula plana, simplement necessites una agrupació estàndard (GROUP BY) pel nom del producte i un compte (COUNT) de les files.

select dt.product_name, count(*) as units_sold
from `sprint3-analytics-mahnaz.sprint3_gold.dim_transactions_flat` as dt
group by dt.product_name
order by units_sold desc
limit 5;


--Exercise 3: Pipeline Automation and Visualization
--You must evolve your table dim_transactions_flatto include tax calculation and automate its regeneration.
--1. User Defined Functions (UDF) : Create a persistent SQL function called calculate_tax(amount) that receives a numeric value and returns the result applying 21% tax.
create or replace function `sprint3-analytics-mahnaz.sprint3_gold.calculate_tax`(amount float64)
returns float64
As(
  round(
    (amount* 1.21),2
  )
);



--2. Integration and Orchestration :
--Modify the table creation code (from Exercise 1) to use your new calculate_tax function and generate a new column: product_price_tax_inc.
--Configure a Scheduled Query in BigQuery so that this statement (CTAS) runs automatically every day at 07:00 AM.
create or replace table `sprint3-analytics-mahnaz.sprint3_gold.dim_transactions_flat` AS 
(
  select tr.transaction_id, tr.timestamp, tr.amount, p.product_id As product_sku, p.name as product_name, p.price as product_price, 
`sprint3-analytics-mahnaz.sprint3_gold.calculate_tax`(p.price)  AS product_price_tax_inc

  from `sprint3-analytics-mahnaz.sprint3_silver.transactions_clean` AS tr
  cross join unnest(tr.product_ids) AS product_id
  join `sprint3-analytics-mahnaz.sprint3_silver.products_clean` as p
  on product_id = SAFE_CAST(p.product_id AS INT64)
);


