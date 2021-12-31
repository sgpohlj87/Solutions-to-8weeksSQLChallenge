---Case Study #6 - Clique Bait

--Case Study Questions
--1. Enterprise Relationship Diagram
--Using the following DDL schema details to create an ERD for all the Clique Bait datasets.

--Click here to access the DB Diagram tool to create the ERD. 

CREATE TABLE clique_bait.event_identifier (
  "event_type" INTEGER,
  "event_name" VARCHAR(13)
);

CREATE TABLE clique_bait.campaign_identifier (
  "campaign_id" INTEGER,
  "products" VARCHAR(3),
  "campaign_name" VARCHAR(33),
  "start_date" TIMESTAMP,
  "end_date" TIMESTAMP
);

CREATE TABLE clique_bait.page_hierarchy (
  "page_id" INTEGER,
  "page_name" VARCHAR(14),
  "product_category" VARCHAR(9),
  "product_id" INTEGER
);

CREATE TABLE clique_bait.users (
  "user_id" INTEGER,
  "cookie_id" VARCHAR(6),
  "start_date" TIMESTAMP
);

CREATE TABLE clique_bait.events (
  "visit_id" VARCHAR(6),
  "cookie_id" VARCHAR(6),
  "page_id" INTEGER,
  "event_type" INTEGER,
  "sequence_number" INTEGER,
  "event_time" TIMESTAMP
);

--2. Digital Analysis
--Using the available datasets - answer the following questions using a single query for each one:

--1. How many users are there?
SELECT COUNT(DISTINCT user_id) AS users
FROM clique_bait.users;

--2. How many cookies does each user have on average?
SELECT ROUND( COUNT(cookie_id)::NUMERIC/COUNT(DISTINCT user_id),0) AS avg_cookie
FROM clique_bait.users;

--3. What is the unique number of visits by all users per month?
SELECT COUNT(DISTINCT visit_id)::NUMERIC/ COUNT(DISTINCT DATE_TRUNC('month',event_time)) AS avg_visits
FROM clique_bait.events;

--4. What is the number of events for each event type?
SELECT event_name, COUNT(event_time) AS num_events
FROM clique_bait.events AS e
LEFT JOIN clique_bait.event_identifier AS i
ON e.event_type = i.event_type
GROUP BY event_name;

--5. What is the percentage of visits which have a purchase event?
SELECT ROUND(COUNT(DISTINCT purchase_visit_id)::NUMERIC/ COUNT(DISTINCT visit_id)*100,1) AS visit_pct
FROM (
SELECT *, CASE WHEN event_type=3 THEN visit_id ELSE NULL END AS purchase_visit_id
FROM clique_bait.events) AS subquery;

--6. What is the percentage of visits which view the checkout page but do not have a purchase event?
WITH event_type2 AS (
SELECT *
FROM clique_bait.events
WHERE event_type=2),
event_type3 AS (
SELECT *
FROM clique_bait.events
WHERE event_type=3),
sub_event AS (
SELECT * 
FROM (
	SELECT *
	FROM clique_bait.events AS e
	WHERE EXISTS
		(SELECT visit_id
	 	FROM event_type2 AS t2
 		WHERE e.visit_id = t2.visit_id)) AS s
WHERE NOT EXISTS
	(SELECT visit_id
     FROM event_type3 AS t3
     WHERE s.visit_id = t3.visit_id)),
sub_event_visit_id AS (
SELECT DISTINCT visit_id FROM sub_event),
event_visit_id AS (
SELECT DISTINCT visit_id FROM clique_bait.events)

SELECT ROUND(COUNT(sub_id)::NUMERIC/ COUNT(event_id)*100,1) AS pct
FROM (
SELECT s.visit_id AS sub_id, e.visit_id AS event_id 
FROM sub_event_visit_id AS s 
FULL JOIN event_visit_id AS e
ON s.visit_id = e.visit_id) AS subquery;

--7. What are the top 3 pages by number of views?
SELECT page_id, COUNT(*) AS page_count
FROM clique_bait.events 
GROUP BY page_id
ORDER BY page_count DESC
LIMIT 3;

--8. What is the number of views and cart adds for each product category?
SELECT product_category, COUNT(DISTINCT page_view_id) AS num_page_views, COUNT(DISTINCT cart_id) AS num_add_cart
FROM (
SELECT *, CASE WHEN event_type=1 THEN visit_id ELSE NULL END AS page_view_id,
CASE WHEN event_type=2 THEN visit_id ELSE NULL END AS cart_id
FROM clique_bait.events AS e
LEFT JOIN clique_bait.page_hierarchy AS p
ON e.page_id = p.page_id 
WHERE event_type=1 OR event_type=2) AS subquery
GROUP BY product_category;

--9. What are the top 3 products by purchases?
WITH event_type2 AS (
SELECT *
FROM clique_bait.events AS e
LEFT JOIN clique_bait.page_hierarchy AS p
ON e.page_id = p.page_id
WHERE event_type=2),
event_type3 AS (
SELECT visit_id
FROM clique_bait.events
WHERE event_type=3)

SELECT t2.product_id, COUNT(*) AS product_count
FROM event_type2 AS t2
RIGHT JOIN event_type3 AS t3
ON t2.visit_id = t3.visit_id
GROUP BY t2.product_id
ORDER BY COUNT(*) DESC
LIMIT 3;

--3. Product Funnel Analysis
--Using a single SQL query - create a new output table which has the following details:

-- How many times was each product viewed?
SELECT product_id, COUNT(*) AS product_views
FROM clique_bait.events AS e
LEFT JOIN clique_bait.page_hierarchy AS p
ON e.page_id = p.page_id 
WHERE event_type=1
GROUP BY product_id
ORDER BY product_id;

-- How many times was each product added to cart?
SELECT product_id, COUNT(*) AS add_cart
FROM clique_bait.events AS e
LEFT JOIN clique_bait.page_hierarchy AS p
ON e.page_id = p.page_id 
WHERE event_type=1
GROUP BY product_id
ORDER BY product_id;

-- How many times was each product added to a cart but not purchased (abandoned)?
-- How many times was each product purchased

-- Additionally, create another table which further aggregates the data for the above points but this time for each product category instead of individual products.

--Use your 2 new output tables - answer the following questions:

--1. Which product had the most views, cart adds and purchases?
--2. Which product was most likely to be abandoned?
--3. Which product had the highest view to purchase percentage?
--4. What is the average conversion rate from view to cart add?
--5. What is the average conversion rate from cart add to purchase?

--3. Campaigns Analysis
--Generate a table that has 1 single row for every unique visit_id record and has the following columns:

--user_id
--visit_id
--visit_start_time: the earliest event_time for each visit
--page_views: count of page views for each visit
--cart_adds: count of product cart add events for each visit
--purchase: 1/0 flag if a purchase event exists for each visit
--campaign_name: map the visit to a campaign if the visit_start_time falls between the start_date and end_date
--impression: count of ad impressions for each visit
--click: count of ad clicks for each visit
--(Optional column) cart_products: a comma separated text value with products added to the cart sorted by the order they were added to the cart (hint: use the sequence_number)

--Use the subsequent dataset to generate at least 5 insights for the Clique Bait team - bonus: prepare a single A4 infographic that the team can use for their management reporting sessions, be sure to emphasise the most important points from your findings.

--Some ideas you might want to investigate further include:

--Identifying users who have received impressions during each campaign period and comparing each metric with other users who did not have an impression event
--Does clicking on an impression lead to higher purchase rates?
--What is the uplift in purchase rate when comparing users who click on a campaign impression versus users who do not receive an impression? What if we compare them with users who just an impression but do not click?
--What metrics can you use to quantify the success or failure of each campaign compared to eachother?

