--Case Study #5 - Data Mart

--1. Data Cleansing Steps
--In a single query, perform the following operations and generate a new table in the data_mart schema named clean_weekly_sales:
--a.Convert the week_date to a DATE format
--b.Add a week_number as the second column for each week_date value, for example any value from the 1st of January to 7th of January will be 1, 8th to 14th will be 2 etc
--c.Add a month_number with the calendar month for each week_date value as the 3rd column
--d.Add a calendar_year column as the 4th column containing either 2018, 2019 or 2020 values
--e.Add a new column called age_band after the original segment column using the following mapping on the number inside the segment value
/*
segment	age_band
1	Young Adults
2	Middle Aged
3 or 4	Retirees */

--f.Add a new demographic column using the following mapping for the first letter in the segment values:
/*
segment	demographic
C	Couples
F	Families */
--g.Ensure all null string values with an "unknown" string value in the original segment column as well as the new age_band and demographic columns
--h.Generate a new avg_transaction column as the sales value divided by transactions rounded to 2 decimal places for each record

CREATE TABLE age_band (
  "segment" VARCHAR(4),
  "age_band" VARCHAR(20)
 );

 INSERT INTO age_band
  ("segment", "age_band")
VALUES
  ('1','Young Adults'),
  ('2','Middle Aged'),
  ('3','Retirees');

CREATE TABLE demographic (
  "segment" VARCHAR(4),
  "demographic" VARCHAR(20)
 );

 INSERT INTO demographic
  ("segment", "demographic")
VALUES
  ('C','Couples'),
  ('F','Families');

WITH cleaned_data AS (
SELECT DATE(MAKE_DATE(year,month,day)) AS week_date, DATE_PART('week',DATE(MAKE_DATE(year,month,day))) AS week_number,
DATE_PART('month',DATE(MAKE_DATE(year,month,day))) AS month_number, DATE_PART('year',DATE(MAKE_DATE(year,month,day))) AS calendar_year,
region, platform, REPLACE(s.segment,'null','unknown') AS segment, customer_type, transactions, sales, COALESCE(age_band,'unknown') AS age_band, 
COALESCE(demographic,'unknown') AS demographic, ROUND(sales/transactions,2) AS avg_transaction
FROM (
SELECT split_part(week_date, '/', 1)::INTEGER AS day, split_part(week_date, '/', 2)::INTEGER AS month, CONCAT('20',split_part(week_date, '/', 3))::INTEGER AS year, *, 
RIGHT(segment,1) AS segment_num, LEFT(segment,1) AS segment_alpha
FROM data_mart.weekly_sales) AS s
LEFT JOIN age_band AS a
ON s.segment_num=a.segment
LEFT JOIN demographic AS d
ON s.segment_alpha=d.segment)

SELECT * FROM cleaned_data
LIMIT 10;

--2. Data Exploration
--1. What day of the week is used for each week_date value?
--2. What range of week numbers are missing from the dataset?

SELECT t.day::date 
FROM   generate_series(timestamp SELECT MIN(week_date) AS min_week_date FROM cleaned_data
                     , timestamp SELECT MAX(week_date) AS max_week_date FROM cleaned_data
                     , interval  '1 day') AS t(day);
-----------------------------------------------------------------------------------------------------------------

--3. How many total transactions were there for each year in the dataset?
SELECT calendar_year, SUM(transactions) AS total_transactions
FROM cleaned_data
GROUP BY calendar_year;

--4. What is the total sales for each region for each month?
SELECT region, month_number, SUM(sales) AS total_sales
FROM cleaned_data
GROUP BY region, month_number
ORDER BY region, month_number;

--5. What is the total count of transactions for each platform
SELECT platform, SUM(transactions) AS total_transactions
FROM cleaned_data
GROUP BY platform;

--6. What is the percentage of sales for Retail vs Shopify for each month?
WITH overall_sales AS (
SELECT month_number, SUM(sales) AS overall_sales
FROM cleaned_data
GROUP BY month_number),
monthly_sales AS (
SELECT platform, month_number, SUM(sales) AS monthly_sales
FROM cleaned_data
GROUP BY platform, month_number)

SELECT month_number, platform, ROUND(monthly_sales::NUMERIC/overall_sales::NUMERIC*100,1) AS sales_pct
FROM (
SELECT m.*, overall_sales FROM monthly_sales AS m
LEFT JOIN overall_sales AS o
ON m.month_number = o.month_number) AS subquery
GROUP BY month_number, platform, monthly_sales, overall_sales
ORDER BY month_number, platform;

--7. What is the percentage of sales by demographic for each year in the dataset?

WITH overall_sales AS (
SELECT calendar_year, SUM(sales) AS overall_sales
FROM cleaned_data
GROUP BY calendar_year),
demographic_sales AS (
SELECT demographic, calendar_year, SUM(sales) AS demographic_sales
FROM cleaned_data
GROUP BY demographic, calendar_year)

SELECT calendar_year, demographic, ROUND(demographic_sales::NUMERIC/overall_sales::NUMERIC*100,1) AS sales_pct
FROM (
SELECT d.*, overall_sales FROM demographic_sales AS d
LEFT JOIN overall_sales AS o
ON d.calendar_year = o.calendar_year) AS subquery
GROUP BY calendar_year, demographic, demographic_sales, overall_sales
ORDER BY calendar_year, demographic;

--8. Which age_band and demographic values contribute the most to Retail sales?
SELECT age_band, demographic, SUM(sales) as total_sales
FROM cleaned_data
WHERE platform = 'Retail' AND age_band != 'unknown' AND demographic != 'unknown'
GROUP BY age_band, demographic
ORDER BY SUM(sales) DESC
LIMIT 1;

--9. Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? 
--If not - how would you calculate it instead?
SELECT platform, ROUND(AVG(total_sales),0) AS avg_sales
FROM (
SELECT calendar_year, platform, SUM(sales) as total_sales
FROM cleaned_data
GROUP BY calendar_year, platform) AS subquery
GROUP BY platform;

--3. Before & After Analysis
--This technique is usually used when we inspect an important event and want to inspect the impact before and after a certain point in time.

--Taking the week_date value of 2020-06-15 as the baseline week where the Data Mart sustainable packaging changes came into effect.

--We would include all week_date values for 2020-06-15 as the start of the period after the change and the previous week_date values would be before

--Using this analysis approach - answer the following questions:

--1.What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?
--2.What about the entire 12 weeks before and after?
--3.How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?

--4. Bonus Question
--Which areas of the business have the highest negative impact in sales metrics performance in 2020 for the 12 week before and after period?
/*
region
platform
age_band
demographic
customer_type */
