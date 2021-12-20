--Case Study #3 - Foodie-Fi

-- A. Customer Journey

--Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.
--Try to keep it as short as possible - you may also want to run some sort of join to make your explanations a bit easier!

-- B. Data Analysis Questions

--1.How many customers has Foodie-Fi ever had?
SELECT COUNT(DISTINCT customer_id)
FROM foodie_fi.subscriptions; 

--2.What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
SELECT to_char(DATE_TRUNC('month',start_date),'YYYY-MM') AS start_month, COUNT(*)
FROM foodie_fi.subscriptions
GROUP BY DATE_TRUNC('month',start_date)
ORDER BY DATE_TRUNC('month',start_date);

--3.What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
SELECT plan_name, COUNT(*)
FROM foodie_fi.subscriptions AS s
LEFT JOIN foodie_fi.plans AS p
ON s.plan_id = p.plan_id
WHERE DATE_TRUNC('year',start_date) > '2020-01-01'
GROUP BY p.plan_id, plan_name
ORDER BY p.plan_id;

--4.What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
WITH combine AS (
SELECT *, CASE WHEN s.plan_id=4 THEN 1 ELSE NULL END AS churn_flag
FROM foodie_fi.subscriptions AS s
LEFT JOIN foodie_fi.plans AS p
ON s.plan_id = p.plan_id)

SELECT SUM(churn_flag) AS churn_count, ROUND(SUM(churn_flag)::NUMERIC/COUNT(*)*100,1) AS churn_pct
FROM combine;

--5.How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
WITH churn_data AS (
SELECT *, LEAD(start_date,1) OVER (PARTITION BY customer_id ORDER BY plan_id) AS lead_date
FROM foodie_fi.subscriptions AS s
WHERE plan_id IN ('0','4')
ORDER BY customer_id),
subscribe AS (
SELECT customer_id
FROM foodie_fi.subscriptions
WHERE plan_id IN ('1','2','3')
GROUP BY customer_id),
churn AS (
SELECT c.* FROM churn_data AS c
LEFT JOIN subscribe AS 
ON c.customer_id = s.customer_id
WHERE lead_date IS NOT NULL AND s.customer_id IS NULL
ORDER BY lead_date-start_date),
trial AS (
SELECT * FROM foodie_fi.subscriptions AS s
WHERE plan_id=0)

SELECT COUNT(DISTINCT c.customer_id) as churn_count, 
ROUND(COUNT(DISTINCT c.customer_id)::NUMERIC/COUNT(DISTINCT t.customer_id)*100,0) as churn_pct
FROM churn AS c, trial AS t;

--6.What is the number and percentage of customer plans after their initial free trial?
WITH flag_data AS (
SELECT customer_id, plan_id, CASE WHEN plan_id=0 THEN 1 ELSE NULL END AS trial_flag, CASE WHEN plan_id IN ('1','2','3') THEN 1 ELSE NULL END AS plan_flag
FROM foodie_fi.subscriptions
WHERE plan_id IN ('0','1','2','3')
GROUP BY customer_id, plan_id
ORDER BY customer_id),
group_data AS (
SELECT customer_id, SUM(trial_flag) as trial, SUM(plan_flag) AS plan
FROM flag_data
GROUP BY customer_id)

SELECT COUNT(plan) AS plan_num, ROUND(COUNT(plan)::NUMERIC/COUNT(trial)*100,1) AS plan_pct FROM group_data; 

--7.What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
SELECT plan_name, COUNT(s.plan_id) AS count, ROUND(COUNT(s.plan_id)::NUMERIC/COUNT(*)*100,1) AS pct
FROM (SELECT * FROM foodie_fi.subscriptions
WHERE DATE(start_date)='2020-12-31') AS s
RIGHT JOIN foodie_fi.plans AS p
ON s.plan_id = p.plan_id
GROUP BY p.plan_id, plan_name
ORDER BY p.plan_id;

--8.How many customers have upgraded to an annual plan in 2020?
WITH flag_data AS (
SELECT customer_id, start_date,
CASE WHEN plan_id=1 THEN 1 ELSE NULL END AS basic_monthly,
CASE WHEN plan_id=2 THEN 1 ELSE NULL END AS pro_monthly,
CASE WHEN plan_id=3 THEN 1 ELSE NULL END AS pro_annual,
CASE WHEN plan_id=1 OR plan_id=2 THEN start_date ELSE NULL END AS monthly_date,
CASE WHEN plan_id=3 THEN start_date ELSE NULL END AS pro_annual_date
FROM foodie_fi.subscriptions
WHERE plan_id IN ('1','2','3')
GROUP BY customer_id, start_date,plan_id, monthly_date, pro_annual_date
),
transform_data AS (
SELECT customer_id, SUM(basic_monthly) AS basic_monthly, SUM(pro_monthly) AS pro_monthly, SUM(pro_annual) AS pro_annual, monthly_date, pro_annual_date
FROM flag_data
WHERE pro_annual_date >= monthly_date
GROUP BY customer_id, pro_annual_date, monthly_date
ORDER BY customer_id)

SELECT COUNT(upgrade) 
FROM (
SELECT *, 
CASE WHEN basic_monthly=1 AND pro_annual=1 THEN 1 
WHEN pro_monthly=1 AND pro_annual=1 THEN 1 ELSE NULL END AS upgrade
FROM transform_data
WHERE EXTRACT(YEAR FROM pro_annual_date)=2020) AS subquery;

--9.How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
SELECT ROUND(AVG(start_date-min_date),0) AS avg_diff_date
FROM (
SELECT *, MIN(start_date) OVER (PARTITION BY customer_id) AS min_date
FROM foodie_fi.subscriptions) AS subquery
WHERE plan_id=3;

--10.Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
WITH days_diff AS (
SELECT customer_id, plan_id, start_date-min_date AS days_diff
FROM (
SELECT *, MIN(start_date) OVER (PARTITION BY customer_id) AS min_date
FROM foodie_fi.subscriptions) AS subquery
WHERE plan_id=3)

SELECT MIN(days_diff), MAX(days_diff) FROM days_diff; /* MIN = 7, MAX = 346 */

SELECT 
CASE WHEN days_diff BETWEEN 1 AND 30 THEN '1-30'
WHEN days_diff BETWEEN 31 AND 60 THEN '31-60' 
WHEN days_diff BETWEEN 61 AND 90 THEN '61-90' 
WHEN days_diff BETWEEN 91 AND 120 THEN '91-120' 
WHEN days_diff BETWEEN 121 AND 150 THEN '121-150' 
WHEN days_diff BETWEEN 151 AND 180 THEN '151-180' 
WHEN days_diff BETWEEN 181 AND 210 THEN '181-210' 
WHEN days_diff BETWEEN 211 AND 240 THEN '211-240' 
WHEN days_diff BETWEEN 241 AND 270 THEN '241-270' 
WHEN days_diff BETWEEN 271 AND 300 THEN '271-300' 
WHEN days_diff BETWEEN 301 AND 330 THEN '301-330'
WHEN days_diff BETWEEN 331 AND 360 THEN '331-360' END AS days_band,
ROUND(AVG(days_diff),0) AS avg_diff_date
FROM days_diff
GROUP BY days_band;

--11.How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
SELECT COUNT(DISTINCT customer_id)
FROM (
SELECT *,  LEAD(start_date,1) OVER (PARTITION BY customer_id ORDER BY plan_id) AS lead_date
FROM foodie_fi.subscriptions
WHERE plan_id IN ('1','2')
ORDER BY customer_id, plan_id) AS subquery
WHERE lead_date IS NOT NULL AND start_date >= lead_date;

--C. Challenge Payment Question

--The Foodie-Fi team wants you to create a new payments table for the year 2020 that includes amounts paid by each customer in the subscriptions table with the following requirements:
--monthly payments always occur on the same day of month as the original start_date of any monthly paid plan
--upgrades from basic to monthly or pro plans are reduced by the current paid amount in that month and start immediately
--upgrades from pro monthly to pro annual are paid at the end of the current billing period and also starts at the end of the month period
--once a customer churns they will no longer make payment

--Example outputs for this table might look like the following:
/*--
customer_id	plan_id	plan_name	payment_date	amount	payment_order
1	1	basic monthly	2020-08-08	9.90	1
1	1	basic monthly	2020-09-08	9.90	2
1	1	basic monthly	2020-10-08	9.90	3
1	1	basic monthly	2020-11-08	9.90	4
1	1	basic monthly	2020-12-08	9.90	5
2	3	pro annual	2020-09-27	199.00	1
13	1	basic monthly	2020-12-22	9.90	1
15	2	pro monthly	2020-03-24	19.90	1
15	2	pro monthly	2020-04-24	19.90	2
16	1	basic monthly	2020-06-07	9.90	1
16	1	basic monthly	2020-07-07	9.90	2
16	1	basic monthly	2020-08-07	9.90	3
16	1	basic monthly	2020-09-07	9.90	4
16	1	basic monthly	2020-10-07	9.90	5
16	3	pro annual	2020-10-21	189.10	6
18	2	pro monthly	2020-07-13	19.90	1
18	2	pro monthly	2020-08-13	19.90	2
18	2	pro monthly	2020-09-13	19.90	3
18	2	pro monthly	2020-10-13	19.90	4
18	2	pro monthly	2020-11-13	19.90	5
18	2	pro monthly	2020-12-13	19.90	6
19	2	pro monthly	2020-06-29	19.90	1
19	2	pro monthly	2020-07-29	19.90	2
19	3	pro annual	2020-08-29	199.00	3
--*/

--D. Outside The Box Questions
--The following are open ended questions which might be asked during a technical interview for this case study - there are no right or wrong answers, but answers that make sense from both a technical and a business perspective make an amazing impression!

--1.How would you calculate the rate of growth for Foodie-Fi?
--2.What key metrics would you recommend Foodie-Fi management to track over time to assess performance of their overall business?
--3.What are some key customer journeys or experiences that you would analyse further to improve customer retention?
--4.If the Foodie-Fi team were to create an exit survey shown to customers who wish to cancel their subscription, what questions would you include in the survey?
--5.What business levers could the Foodie-Fi team use to reduce the customer churn rate? How would you validate the effectiveness of your ideas?
