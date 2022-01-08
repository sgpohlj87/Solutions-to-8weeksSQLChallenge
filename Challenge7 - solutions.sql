--Case Study #7 - Balanced Tree Clothing Co.

--High Level Sales Analysis
--1.What was the total quantity sold for all products?
SELECT SUM(qty) AS total_quantity
FROM balanced_tree.sales;

--2.What is the total generated revenue for all products before discounts?
SELECT SUM(qty*price) AS total_revenue
FROM balanced_tree.sales;
--3.What was the total discount amount for all products?
SELECT SUM(qty*discount/100) AS total_discount
FROM balanced_tree.sales;

--Transaction Analysis
--1.How many unique transactions were there?
SELECT COUNT(DISTINCT txn_id) AS txn_count
FROM balanced_tree.sales;

--2.What is the average unique products purchased in each transaction?
SELECT COUNT(DISTINCT CONCAT(prod_id,txn_id))::NUMERIC/COUNT(DISTINCT txn_id) AS avg_unique_pdt_per_txn
FROM balanced_tree.sales;

--3.What are the 25th, 50th and 75th percentile values for the revenue per transaction?
WITH sales_revenue AS (
SELECT *, SUM(qty*price)*(100-qty)/100 AS revenue
FROM balanced_tree.sales
GROUP BY prod_id,qty, price,discount,member,txn_id,start_txn_time)

SELECT
 PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY revenue) AS q1_revenue,
 PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY revenue) AS median_revenue,
 PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY revenue) AS q3_revenue
 FROM sales_revenue;

--4.What is the average discount value per transaction?
SELECT ROUND(AVG(discount),1) AS avg_discount
FROM balanced_tree.sales;

--5.What is the percentage split of all transactions for members vs non-members?
SELECT member, ROUND(COUNT(prod_id)/ SUM(COUNT(prod_id)) OVER()*100,1) AS pct
FROM balanced_tree.sales
GROUP BY member;

--6.What is the average revenue for member transactions and non-member transactions?
WITH sales_revenue AS (
SELECT prod_id, member,
CASE WHEN member='t' THEN SUM(qty*price)*(100-discount)/100 ELSE NULL END AS member_revenue,
CASE WHEN member='f' THEN SUM(qty*price)*(100-discount)/100 ELSE NULL END AS non_member_revenue
FROM balanced_tree.sales 
GROUP BY prod_id, member, qty, price, discount)

SELECT ROUND(AVG(member_revenue),1) AS avg_member_revenue, ROUND(AVG(non_member_revenue),1)  AS avg_non_member_revenue
FROM sales_revenue;

--Product Analysis
--1.What are the top 3 products by total revenue before discount?
SELECT product_name, SUM(s.qty*s.price)*(100-s.discount)/100 AS revenue
FROM balanced_tree.sales AS s
LEFT JOIN balanced_tree.product_details AS d
ON s.prod_id = d.product_id
GROUP BY product_name, s.qty, s.price, s.discount
ORDER BY SUM(s.qty*s.price)*(100-s.discount)/100 DESC
LIMIT 3;

--2.What is the total quantity, revenue and discount for each segment?
SELECT segment_name, SUM(qty) AS sum_qty, SUM(revenue) AS sum_revenue, SUM(discount_amount) AS sum_discount
FROM (
SELECT segment_name, qty,  SUM(s.qty*s.price)*(100-s.discount)/100 AS revenue, SUM(s.qty*s.price*s.discount)/100 AS discount_amount
FROM balanced_tree.sales AS s
LEFT JOIN balanced_tree.product_details AS d
ON s.prod_id = d.product_id
GROUP BY segment_name, qty, s.price, s.discount) AS subquery
GROUP BY segment_name;

--3.What is the top selling product for each segment?
SELECT segment_name, product_name 
FROM (
SELECT segment_name, product_name, SUM(qty) AS sum_qty, ROW_NUMBER() OVER (PARTITION BY segment_name ORDER BY SUM(qty) DESC) AS rn
FROM balanced_tree.sales AS s
LEFT JOIN balanced_tree.product_details AS d
ON s.prod_id = d.product_id
GROUP BY segment_name, product_name) AS subquery
WHERE rn=1;

--4.What is the total quantity, revenue and discount for each category?
SELECT category_name, SUM(qty) AS sum_qty, SUM(revenue) AS sum_revenue, SUM(discount_amount) AS sum_discount
FROM (
SELECT category_name, qty,  SUM(s.qty*s.price)*(100-s.discount)/100 AS revenue, SUM(s.qty*s.price*s.discount)/100 AS discount_amount
FROM balanced_tree.sales AS s
LEFT JOIN balanced_tree.product_details AS d
ON s.prod_id = d.product_id
GROUP BY category_name, qty, s.price, s.discount) AS subquery
GROUP BY category_name;

--5.What is the top selling product for each category?
SELECT category_name, product_name 
FROM (
SELECT category_name, product_name, SUM(qty) AS sum_qty, ROW_NUMBER() OVER (PARTITION BY category_name ORDER BY SUM(qty) DESC) AS rn
FROM balanced_tree.sales AS s
LEFT JOIN balanced_tree.product_details AS d
ON s.prod_id = d.product_id
GROUP BY category_name, product_name) AS subquery
WHERE rn=1;

--6.What is the percentage split of revenue by product for each segment
SELECT segment_name, product_name, 
ROUND(SUM(revenue)/SUM(SUM(revenue)) OVER (PARTITION BY segment_name)*100,1)  AS pct
FROM (
SELECT s.prod_id, d.segment_name, d.product_name, SUM(s.qty*s.price)*(100-s.discount)/100 AS revenue
FROM balanced_tree.sales AS s
LEFT JOIN balanced_tree.product_details AS d
ON s.prod_id = d.product_id
GROUP BY s.prod_id, d.segment_name,d.product_name,s.qty, s.price, s.discount
) AS subquery
GROUP BY segment_name, product_name;

--7.What is the percentage split of revenue by segment for each category?
SELECT category_name, segment_name, 
ROUND(SUM(revenue)/SUM(SUM(revenue)) OVER (PARTITION BY category_name)*100,1)  AS pct
FROM (
SELECT s.prod_id, d.segment_name, d.category_name, SUM(s.qty*s.price)*(100-s.discount)/100 AS revenue
FROM balanced_tree.sales AS s
LEFT JOIN balanced_tree.product_details AS d
ON s.prod_id = d.product_id
GROUP BY s.prod_id, d.segment_name,d.category_name,s.qty, s.price, s.discount
) AS subquery
GROUP BY category_name, segment_name;

--8.What is the percentage split of total revenue by category?
SELECT category_name, ROUND(SUM(revenue)/SUM(SUM(revenue)) OVER()*100,1)  AS pct
FROM (
SELECT s.prod_id, d.category_name, SUM(s.qty*s.price)*(100-s.discount)/100 AS revenue
FROM balanced_tree.sales AS s
LEFT JOIN balanced_tree.product_details AS d
ON s.prod_id = d.product_id
GROUP BY s.prod_id, d.category_name,s.qty, s.price, s.discount
) AS subquery
GROUP BY category_name;

--9.What is the total transaction “penetration” for each product? 
--(hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)
--10.What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?

--Reporting Challenge
--Write a single SQL script that combines all of the previous questions into a scheduled report that the Balanced Tree team can run at the beginning of each month to calculate the previous month’s values.
--Imagine that the Chief Financial Officer (which is also Danny) has asked for all of these questions at the end of every month.
--He first wants you to generate the data for January only - but then he also wants you to demonstrate that you can easily run the samne analysis for February without many changes (if at all).
--Feel free to split up your final outputs into as many tables as you need - but be sure to explicitly reference which table outputs relate to which question for full marks :)

--Bonus Challenge
--Use a single SQL query to transform the product_hierarchy and product_prices datasets to the product_details table.
--Hint: you may want to consider using a recursive CTE to solve this problem! ---*/