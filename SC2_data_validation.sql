create view vw_transaction_details as
select dt.*,
p.category,
round(dt.price * (1 - dt.discount/100), 2) as final_price,
round(dt.units_sold*dt.price*(1-dt.discount/100),2) as revenue
from daily_transactions dt
join products p
on p.product_id=dt.product_id;

create view vw_current_inventory as 
select dt.store_id,
dt.product_id,
p.category,
dt.region,
dt.inventory_level,
dt.transaction_date as last_updated
from daily_transactions dt
join products p
on p.product_id=dt.product_id
where dt.transaction_date=(select max(transaction_date) from daily_transactions);

# Noticed an anomaly of only 150 rows of data present in current inventory
# There are about 30 unique products, 5 stores and 4 regions of operations.
# Expected around 30*5*4=600 current inventory rows. A row for each product in each store present in each region
# Found out that a product is only available in a particular store present in a particular region
# Not every product can be found everywhere.
# An example of store S001 where total products add up to 30
SELECT region, COUNT(DISTINCT product_id) AS products_in_region
FROM daily_transactions
WHERE transaction_date = (SELECT MAX(transaction_date) FROM daily_transactions)
  AND store_id = 'S001'
GROUP BY region;


create view vw_product_performance as
select 
    dt.product_id,
    p.category,
    count(distinct dt.store_id) as stores_selling,
    count(distinct dt.region) as regions_active,
    sum(dt.units_sold) as total_units_sold,
    avg(dt.inventory_level) as avg_inventory_level,
    round(avg(dt.units_sold/nullif(dt.inventory_level,0))*365,2) as annual_turnover_ratio,
    round(avg(dt.price * (1 - dt.discount / 100)), 2) as avg_final_price,
    round(sum(dt.units_sold * dt.price * (1 - dt.discount / 100)), 2) as total_revenue,
    sum(case when dt.units_sold = 0 then 1 else 0 end) as days_with_zero_sales,
    sum(case when dt.units_sold > dt.inventory_level then 1 else 0 end) as stockout_days
from daily_transactions dt
join products p
    on p.product_id = dt.product_id
group by 
    dt.product_id,
    p.category;

# Noticed an anomaly of extremely high turnover rates.
# A typical store can only sell about ~20% of its inventory every day, thus having a turnover rate of 20%.
# Here stores are having an unsually high turnover rate of ~60% for the majority of them
# Will have to optimize inventory levels to save on transportation costs.
SELECT 
    CASE 
        WHEN units_sold / NULLIF(inventory_level, 0) < 0.2 THEN 'Under 20%'
        WHEN units_sold / NULLIF(inventory_level, 0) < 0.5 THEN '20-50%'
        WHEN units_sold / NULLIF(inventory_level, 0) < 0.8 THEN '50-80%'
        WHEN units_sold / NULLIF(inventory_level, 0) < 1.0 THEN '80-100%'
        ELSE 'Over 100%'
    END AS daily_turnover_bucket,
    COUNT(*) AS record_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM daily_transactions), 1) AS percentage
FROM daily_transactions
GROUP BY daily_turnover_bucket
ORDER BY daily_turnover_bucket;

# Further digging of high turnover rates
# Anomalies of synthetic data and one of them being extremely similar turnover rates for all categories
SELECT p.category,
       ROUND(AVG(dt.units_sold / NULLIF(dt.inventory_level, 0)) * 365, 2) AS turnover
FROM daily_transactions dt
JOIN products p ON dt.product_id = p.product_id
GROUP BY p.category;