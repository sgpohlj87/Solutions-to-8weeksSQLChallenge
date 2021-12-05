--Case Study #1 - Danny's Diner

/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
-- 2. How many days has each customer visited the restaurant?
-- 3. What was the first item from the menu purchased by each customer?
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
-- 5. Which item was the most popular for each customer?
-- 6. Which item was purchased first by the customer after they became a member?
-- 7. Which item was purchased just before the customer became a member?
-- 8. What is the total items and amount spent for each member before they became a member?
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

/* --------------------
   Bonus Questions
   --------------------*/

--Join All The Things
---The following questions are related creating basic data tables that Danny and his team can use to quickly derive insights without needing to join the underlying tables using SQL.

--Recreate the following table output using the available data:

/* --------------------
customer_id	order_date	product_name	price	member
A	2021-01-01	curry	15	N
A	2021-01-01	sushi	10	N
A	2021-01-07	curry	15	Y
A	2021-01-10	ramen	12	Y
A	2021-01-11	ramen	12	Y
A	2021-01-11	ramen	12	Y
B	2021-01-01	curry	15	N
B	2021-01-02	curry	15	N
B	2021-01-04	sushi	10	N
B	2021-01-11	sushi	10	Y
B	2021-01-16	ramen	12	Y
B	2021-02-01	ramen	12	Y
C	2021-01-01	ramen	12	N
C	2021-01-01	ramen	12	N
C	2021-01-07	ramen	12	N
------------ */

---Rank All The Things
---Danny also requires further information about the ranking of customer products, but he purposely does not need the ranking for non-member purchases so he expects null ranking values for the records when customers are not yet part of the loyalty program.

/*-----
customer_id	order_date	product_name	price	member	ranking
A	2021-01-01	curry	15	N	null
A	2021-01-01	sushi	10	N	null
A	2021-01-07	curry	15	Y	1
A	2021-01-10	ramen	12	Y	2
A	2021-01-11	ramen	12	Y	3
A	2021-01-11	ramen	12	Y	3
B	2021-01-01	curry	15	N	null
B	2021-01-02	curry	15	N	null
B	2021-01-04	sushi	10	N	null
B	2021-01-11	sushi	10	Y	1
B	2021-01-16	ramen	12	Y	2
B	2021-02-01	ramen	12	Y	3
C	2021-01-01	ramen	12	N	null
C	2021-01-01	ramen	12	N	null
C	2021-01-07	ramen	12	N	null
---*/

/* --------------------
   Solutions
   --------------------*/

--Question1:
SELECT customer_id,  SUM(price) FROM dannys_diner.menu as M
LEFT JOIN dannys_diner.sales as S
ON M.product_id = S.product_id 
GROUP BY customer_id
ORDER BY customer_id;

--Question2:
SELECT customer_id, COUNT(DISTINCT order_date) as days FROM dannys_diner.sales
GROUP BY customer_id;

--Question3:
SELECT C.customer_id, product_name, order_date from (
SELECT * FROM dannys_diner.sales as A
INNER JOIN (SELECT customer_id as cust_id, MIN(order_date) as mindate FROM dannys_diner.sales GROUP BY customer_id) as B
ON A.customer_id=B.cust_id and A.order_date = B.mindate) as C
LEFT JOIN dannys_diner.menu as M
ON C.product_id=M.product_id
ORDER BY customer_id;

--Question4:
SELECT product_name, count(order_date) from dannys_diner.sales as S
LEFT JOIN dannys_diner.menu as M
ON S.product_id = M.product_id
GROUP BY product_name;

--Question5:
SELECT customer_id, product_name
FROM (
SELECT DISTINCT customer_id, FIRST_VALUE(product_id) OVER (PARTITION BY customer_id ORDER BY COUNT(order_date)) AS pdt_id,
MAX(COUNT(order_date)) OVER (PARTITION BY customer_id) AS max_count
FROM dannys_diner.sales
GROUP BY customer_id,product_id
ORDER BY customer_id) AS A
LEFT JOIN dannys_diner.menu AS B
ON A.pdt_id = B.product_id
ORDER BY customer_id;

--Question6: **
SELECT S.customer_id, product_id, order_date
FROM dannys_diner.sales AS S
LEFT JOIN dannys_diner.members AS M
ON S.customer_id  = M.customer_id
WHERE order_date >= join_date
ORDER BY customer_id, order_date;

--Question7:
SELECT s.customer_id, product_name FROM dannys_diner.sales AS s
LEFT JOIN dannys_diner.members AS m
ON s.customer_id = m.customer_id
LEFT JOIN dannys_diner.menu as u
ON s.product_id = u.product_id
INNER JOIN 
(SELECT s.customer_id,  MIN(order_date - join_date) as min_date_diff FROM dannys_diner.sales AS s
LEFT JOIN dannys_diner.members AS m
ON s.customer_id = m.customer_id
WHERE order_date - join_date >=0
GROUP BY s.customer_id) AS subquery
ON s.customer_id = subquery.customer_id and order_date - join_date = min_date_diff
WHERE order_date - join_date >=0
ORDER BY customer_id 
;

--Question8:
SELECT s.customer_id, COUNT(s.product_id) AS count_product, SUM(price) AS total_price
FROM dannys_diner.sales AS s
LEFT JOIN dannys_diner.members AS m
ON s.customer_id = m.customer_id
LEFT JOIN dannys_diner.menu AS u
ON s.product_id = u.product_id
WHERE order_date - join_date < 0
GROUP BY s.customer_id
ORDER BY s.customer_id
;