--Case Study #2 - Pizza Runner

--Case Study Questions
-- A. Pizza Metrics
--1.How many pizzas were ordered?
SELECT COUNT(order_id)
FROM pizza_runner.customer_orders;

--2.How many unique customer orders were made?
SELECT COUNT(DISTINCT order_id)
FROM pizza_runner.customer_orders;

--3.How many successful orders were delivered by each runner?
SELECT runner_id, COUNT(order_id)
FROM pizza_runner.runner_orders
WHERE cancellation IS NULL OR cancellation IN ('null','')
GROUP BY runner_id;

--4.How many of each type of pizza was delivered?
SELECT pizza_name, count(order_id) FROM (
SELECT pizza_id, A.order_id FROM pizza_runner.customer_orders as A
LEFT JOIN (
SELECT order_id
FROM pizza_runner.runner_orders
WHERE cancellation IS NULL OR cancellation IN ('null','')) AS B
ON A.order_id = B.order_id) as C
LEFT JOIN pizza_runner.pizza_names as N
ON C.pizza_id = N.pizza_id
GROUP BY pizza_name;

--5.How many Vegetarian and Meatlovers were ordered by each customer?
SELECT customer_id, pizza_name, COUNT(order_id) AS count
FROM pizza_runner.customer_orders AS c
LEFT JOIN pizza_runner.pizza_names AS n
ON c.pizza_id = n.pizza_id
GROUP BY customer_id, pizza_name;

--6.What was the maximum number of pizzas delivered in a single order?
SELECT order_id, COUNT(pizza_id) AS pizza_count
FROM pizza_runner.customer_orders
GROUP BY order_id
ORDER BY pizza_count DESC
LIMIT 1;

--7.For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

--8.How many pizzas were delivered that had both exclusions and extras?

SELECT COUNT(pizza_id) AS pizza_count
FROM pizza_runner.customer_orders AS c
LEFT JOIN pizza_runner.runner_orders AS r
ON c.order_id = r.order_id
WHERE (cancellation IS NULL OR cancellation IN ('null',''))
AND NOT (exclusions IS NULL OR exclusions IN ('null',''))
AND NOT (extras IS NULL OR extras IN ('null',''));

--9.What was the total volume of pizzas ordered for each hour of the day?
SELECT EXTRACT (hour FROM order_time) as order_hour, COUNT(pizza_id) AS pizza_count
FROM pizza_runner.customer_orders 
GROUP BY order_hour
ORDER BY order_hour;

--10.What was the volume of orders for each day of the week?
SELECT DAYOFWEEK(order_time::DATE) AS day_of_week,
COUNT(order_id) AS order_count
FROM pizza_runner.customer_orders 
GROUP BY day_of_week;

--B. Runner and Customer Experience
--1.How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
SELECT DATE(DATE_TRUNC('week',registration_date)) AS registration_week,
COUNT(runner_id) AS runner_count
FROM pizza_runner.runners
WHERE registration_date >= '2021-01-01'
GROUP BY registration_week;

--2.What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
SELECT ROUND(AVG(minutes),1) AS avg_min
FROM (
SELECT *, LEFT(TRIM(duration),2)::NUMERIC AS minutes
FROM pizza_runner.runner_orders
WHERE cancellation IS NULL OR cancellation='' or cancellation = 'null') AS subquery;

--3.Is there any relationship between the number of pizzas and how long the order takes to prepare?

--4.What was the average distance travelled for each customer?
SELECT ROUND(AVG(KM),1) AS avg_km
FROM (
SELECT *, REPLACE(distance,'km','')::NUMERIC AS km
FROM pizza_runner.runner_orders
WHERE cancellation IS NULL OR cancellation='' or cancellation = 'null') AS subquery;

--5.What was the difference between the longest and shortest delivery times for all orders?
SELECT MAX(minutes)-MIN(minutes) AS min_diff
FROM (
SELECT *, LEFT(TRIM(duration),2)::NUMERIC AS minutes
FROM pizza_runner.runner_orders
WHERE cancellation IS NULL OR cancellation='' or cancellation = 'null') AS subquery;

--6.What was the average speed for each runner for each delivery and do you notice any trend for these values?
--7.What is the successful delivery percentage for each runner?

--C. Ingredient Optimisation
--1.What are the standard ingredients for each pizza?
--2.What was the most commonly added extra?
--3.What was the most common exclusion?
--4.Generate an order item for each record in the customers_orders table in the format of one of the following:
--Meat Lovers
--Meat Lovers - Exclude Beef
--Meat Lovers - Extra Bacon
--Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
--5.Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
--For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
--6.What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?

--D. Pricing and Ratings
--1.If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
--2.What if there was an additional $1 charge for any pizza extras?
---Add cheese is $1 extra
--3.The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
--4.Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
/*----
customer_id
order_id
runner_id
rating
order_time
pickup_time
Time between order and pickup
Delivery duration
Average speed
Total number of pizzas
---*/
--5.If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?

--E. Bonus Questions
--If Danny wants to expand his range of pizzas - how would this impact the existing data design? Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?
