-- Active: 1727863492809@@127.0.0.1@3307@orders

USE orders;
--What are the top 10 products by sales volume, and how do their profit margins compare?
SELECT 
    product_id,
    product_name,
    SUM(sales) as sales_volume,
    SUM(profit) as total_profits
FROM orders
GROUP BY product_id
ORDER BY 3 DESC
LIMIT 10;

--What is the average profit margin for each sub-category?
SELECT 
    sub_category,
    AVG(profit_margin) as `profit margin (%)`
FROM orders
GROUP BY sub_category
ORDER BY 2 DESC;

--How does profit vary across different regions or states?
SELECT 
    `state`,
    SUM(profit) as profits
FROM orders
GROUP BY `state`
ORDER BY 2 DESC;

--What is the total sales and profit for each salesperson, and who are the top performers?
SELECT 
    salesperson,
    SUM(sales) as total_sales,
    SUM(profit) as total_profits,
    RANK() OVER(PARTITION BY salesperson ORDER BY SUM(sales) DESC) as sales_rank,
    RANK() OVER(PARTITION BY salesperson ORDER BY SUM(profit) DESC) as profits_rank
FROM orders
GROUP BY salesperson
ORDER BY 4 DESC;

--Which customer segments have the highest purchase volume, and what is their average discount?
SELECT 
    segment,
    SUM(sales) as total_purchase,
    AVG(discount) as average_discount
FROM orders
GROUP BY segment
ORDER BY 2 DESC;


--What is the return rate by customer segment?
WITH returned_orders(seg, order_cnt) as(
    SELECT 
        segment,
        COUNT(order_id)
    FROM orders
    WHERE return_reason IN ('Wrong Color', 'Wrong Item', 'Not Needed')
    GROUP BY segment
), all_orders(seg, order_cnt) AS (
    SELECT 
        segment,
        COUNT(order_id)
    FROM orders
    GROUP BY segment
)
SELECT 
    all_orders.seg as segment,
    all_orders.order_cnt as `all orders`,
    returned_orders.order_cnt as `returned orders`,
    ROUND(returned_orders.order_cnt / all_orders.order_cnt * 100, 1) as `return rate %`
FROM returned_orders JOIN all_orders ON returned_orders.seg = all_orders.seg

--Which customers have the highest lifetime value (total sales amount), 
SELECT 
    customer_id,
    customer_name,
    segment,
    CONCAT(city, ', ', state) as location,
    COUNT(order_id) as `number of orders`,
    SUM(sales) as `total purchase`
FROM orders 
GROUP BY customer_id
ORDER BY 6 DESC
LIMIT 20;

--What is the average time to ship for each ship mode, 
--and how does it correlate with customer satisfaction or returns?
WITH shipping as(
    SELECT 
        ship_mode,
        segment,
        COUNT(order_id) as orders_cnt,
        ROUND(AVG(days_to_ship),1) as avg_shipping
    FROM orders
    GROUP BY ship_mode,segment
), returned_orders AS (
    SELECT 
        ship_mode,
        segment,
        COUNT(order_id) as orders_cnt
    FROM orders
    WHERE return_reason IN ('Wrong Color', 'Wrong Item', 'Not Needed')
    GROUP BY ship_mode, segment
)
SELECT 
    shipping.ship_mode,
    shipping.segment,
    shipping.orders_cnt as `# of orders`,
    shipping.avg_shipping as `avg shipping days`,
    returned_orders.orders_cnt as `# of returned orders`,
    returned_orders.orders_cnt / shipping.orders_cnt * 100 as `% return rate`
FROM shipping LEFT JOIN returned_orders 
ON shipping.ship_mode = returned_orders.ship_mode AND shipping.segment = returned_orders.segment
ORDER BY 6 DESC
;


--How does the month of order placement affect order volume and profit?(
WITH month_sales(mon, sales) AS (
    SELECT 
        order_date,
        SUM(sales)
    FROM orders
    GROUP BY MONTH(order_date)
), month_diff AS (
SELECT 
    DATE_FORMAT(mon, '%M') as mon,
    sales,
    LAG(sales) OVER(ORDER BY MONTH(mon) ASC) as sales_prev_month
FROM month_sales
)
SELECT 
    mon,
    sales,
    sales_prev_month,
    (sales - sales_prev_month) as sales_diff,
    ROUND((sales - sales_prev_month) / sales_prev_month * 100, 1) as `% change`
FROM month_diff
;

--What are the most common return reasons, and which products are returned most frequently?
WITH returns_by_product AS (
    SELECT 
        product_id,
        product_name,
        COUNT(return_reason) as orders_returned,
        DENSE_RANK() OVER(ORDER BY COUNT(return_reason) DESC) as product_return_rank
    FROM orders
    WHERE return_reason NOT IN ('Not Returned', 'Not Given')
    GROUP BY product_id
), returns_by_reason AS (
    SELECT 
        product_id,
        return_reason,
        COUNT(return_reason) as orders_returned,
        ROW_NUMBER() OVER(PARTITION BY product_id ORDER BY COUNT(return_reason) DESC) as return_reason_rank
    FROM orders
    WHERE return_reason NOT IN ('Not Returned', 'Not Given')
    GROUP BY product_id,return_reason
)
SELECT 
    top_returns_by_product.product_id,
    top_returns_by_product.product_name,
    top_returns_by_product.orders_returned,
    top_return_reasons.return_reason  as `top return reason`,
    top_return_reasons.orders_returned as `top reason returns`
FROM (SELECT * FROM returns_by_product WHERE product_return_rank <= 5) as top_returns_by_product
    LEFT JOIN (SELECT * FROM returns_by_reason WHERE return_reason_rank = 1) as top_return_reasons 
    ON top_returns_by_product.product_id = top_return_reasons.product_id
ORDER BY 3 DESC;


--Which products have a discount over 30% most often, and does this lead to increased sales volume?
with discount_sales as (
    SELECT 
        sub_category,
        SUM(sales) as total_sales,
        SUM(profit) as total_profits
    FROM orders
    WHERE discount_over_30 = 1
    GROUP BY sub_category
), full_sale as (
    SELECT 
        sub_category,
        SUM(sales) as total_sales,
        SUM(profit) as total_profits
    FROM orders 
    WHERE discount_over_30 = 0
    GROUP BY sub_category
)
SELECT 
    discount_sales.sub_category,
    discount_sales.total_sales as `>30% discount price sales`,
    full_sale.total_sales as `<=30% discount price sales`,
    discount_sales.total_sales - full_sale.total_sales as `sales difference`
FROM
    discount_sales INNER JOIN full_sale ON discount_sales.sub_category = full_sale.sub_category
ORDER BY 4 DESC;


--What are the average unit costs for products in each category, and how does this impact the profit margin?
SELECT 
    sub_category,
    AVG(unit_cost) as avg_unit_cost,
    AVG(profit_margin) * 100 as `avg % profit margin`
FROM orders
GROUP BY sub_category
ORDER BY 2 ASC;

--Which regions experience the longest shipping delays, and how do these delays impact return rates?
with orders_by_city AS (
    SELECT  
        city, 
        ROUND(AVG(days_to_ship), 1) as avg_ship_days,
        COUNT(order_id) as order_cnt
    FROM orders
    GROUP BY city
), returns_by_city AS (
    SELECT 
        city,
        COUNT(order_id) as return_cnt
    FROM orders
    WHERE return_reason NOT IN ('Not Returned', 'Not Given')
    GROUP BY city
)
SELECT 
    orders_by_city.*,
    returns_by_city.return_cnt,
    ROUND(returns_by_city.return_cnt / orders_by_city.order_cnt * 100, 1) as `% returned`
FROM orders_by_city LEFT JOIN returns_by_city ON orders_by_city.city = returns_by_city.city
ORDER BY 2 DESC

