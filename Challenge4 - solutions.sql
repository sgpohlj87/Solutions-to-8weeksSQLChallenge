--Case Study #4 - Data Bank

--A. Customer Nodes Exploration
--1. How many unique nodes are there on the Data Bank system?
SELECT COUNT(DISTINCT node_id) 
FROM data_bank.customer_nodes;

--2. What is the number of nodes per region?
SELECT ROUND(COUNT(node_id)::NUMERIC/ COUNT(DISTINCT region_id),0) AS avg_node
FROM data_bank.customer_nodes;

--3. How many customers are allocated to each region?
SELECT region_name, COUNT(DISTINCT customer_id) AS num_customer
FROM data_bank.customer_nodes AS c
LEFT JOIN data_bank.regions AS r
ON c.region_id = r.region_id
GROUP BY region_name;

--4. How many days on average are customers reallocated to a different node?

--5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?


--B. Customer Transactions
--1. What is the unique count and total amount for each transaction type?
SELECT txn_type, COUNT(DISTINCT CONCAT(customer_id,txn_date)) AS txn_count, SUM(txn_amount) AS txn_sum
FROM data_bank.customer_transactions
GROUP BY txn_type;

--2. What is the average total historical deposit counts and amounts for all customers?
SELECT ROUND(COUNT(DISTINCT CONCAT(customer_id,txn_date))::NUMERIC/ COUNT(DISTINCT customer_id),0) AS avg_txn_count, 
ROUND(SUM(txn_amount)::NUMERIC/ COUNT(DISTINCT customer_id),0)  AS avg_txn_sum
FROM data_bank.customer_transactions;

--3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?SELECT txn_month, COUNT(DISTINCT customer_id) AS customers
SELECT txn_month, COUNT(DISTINCT customer_id) AS customers
FROM (
SELECT customer_id,to_char(DATE_TRUNC('month',txn_date),'YYYY-MM') AS txn_month, SUM(deposit_flag) AS deposit, SUM(purchase_flag) AS purchase, SUM(withdrawal_flag) AS withdrawal
FROM (
SELECT customer_id, txn_date, CASE WHEN txn_type='deposit' THEN 1 ELSE NULL END AS deposit_flag,
CASE WHEN txn_type='purchase' THEN 1 ELSE NULL END AS purchase_flag, CASE WHEN txn_type='withdrawal' THEN 1 ELSE NULL END AS withdrawal_flag
FROM data_bank.customer_transactions) AS subquery
GROUP BY customer_id, DATE_TRUNC('month',txn_date)
HAVING SUM(deposit_flag) >1 AND (SUM(purchase_flag) = 1 or SUM(withdrawal_flag)=1)) AS subquery2
GROUP BY txn_month
ORDER BY txn_month;

--4.What is the closing balance for each customer at the end of the month?
WITH balance_data AS (
SELECT *, to_char(DATE_TRUNC('month',txn_date),'YYYY-MM') AS txn_month,
               CASE WHEN txn_type='deposit' THEN txn_amount 
               WHEN txn_type='purchase' THEN txn_amount*-1 
               WHEN txn_type='withdrawal' THEN txn_amount*-1 END AS txn_balance
FROM data_bank.customer_transactions)

SELECT customer_id, txn_month, closing_balance
FROM (
SELECT customer_id,txn_date, txn_month, txn_balance,
SUM(txn_balance) OVER (PARTITION BY customer_id, txn_month ORDER BY customer_id, txn_date) AS closing_balance,
ROW_NUMBER() OVER (PARTITION BY customer_id, txn_month ORDER BY txn_date DESC ) AS rn
FROM balance_data 
GROUP BY customer_id, txn_month,txn_date,txn_balance
ORDER BY customer_id, txn_month,txn_date) AS subquery
WHERE rn=1;

--5. What is the percentage of customers who increase their closing balance by more than 5%?
WITH balance_data AS (
SELECT *, to_char(DATE_TRUNC('month',txn_date),'YYYY-MM') AS txn_month,
               CASE WHEN txn_type='deposit' THEN txn_amount 
               WHEN txn_type='purchase' THEN txn_amount*-1 
               WHEN txn_type='withdrawal' THEN txn_amount*-1 END AS txn_balance
FROM data_bank.customer_transactions),
closing_data AS (
SELECT customer_id, txn_month, closing_balance
FROM (
SELECT customer_id,txn_date, txn_month, txn_balance,
SUM(txn_balance) OVER (PARTITION BY customer_id, txn_month ORDER BY customer_id, txn_date) AS closing_balance,
ROW_NUMBER() OVER (PARTITION BY customer_id, txn_month ORDER BY txn_date DESC ) AS rn
FROM balance_data 
GROUP BY customer_id, txn_month,txn_date,txn_balance
ORDER BY customer_id, txn_month,txn_date) AS subquery
WHERE rn=1)

SELECT *, LAG(closing_balance) OVER (PARTITION BY customer_id ORDER BY txn_month) AS lag_closing_balance FROM closing_data;
............................

--C. Data Allocation Challenge
--To test out a few different hypotheses - the Data Bank team wants to run an experiment where different groups of customers would be allocated data using 3 different options:

--- Option 1: data is allocated based off the amount of money at the end of the previous month
--- Option 2: data is allocated on the average amount of money kept in the account in the previous 30 days
--- Option 3: data is updated real-time

--For this multi-part challenge question - you have been requested to generate the following data elements to help the Data Bank team estimate how much data will need to be provisioned for each option:

--- running customer balance column that includes the impact each transaction
--- customer balance at the end of each month
--- minimum, average and maximum values of the running balance for each customer

--Using all of the data available - how much data would have been required for each option on a monthly basis?

--D. Extra Challenge
--Data Bank wants to try another option which is a bit more difficult to implement - they want to calculate data growth using an interest calculation, just like in a traditional savings account you might have with a bank.

--If the annual interest rate is set at 6% and the Data Bank team wants to reward its customers by increasing their data allocation based off the interest calculated on a daily basis at the end of each day, how much data would be required for this option on a monthly basis?

--Special notes:

--Data Bank wants an initial calculation which does not allow for compounding interest, however they may also be interested in a daily compounding interest calculation so you can try to perform this calculation if you have the stamina!
--Extension Request
--The Data Bank team wants you to use the outputs generated from the above sections to create a quick Powerpoint presentation which will be used as marketing materials for both external investors who might want to buy Data Bank shares and new prospective customers who might want to bank with Data Bank.

--1. Using the outputs generated from the customer node questions, generate a few headline insights which Data Bank might use to market it’s world-leading security features to potential investors and customers.
--2. With the transaction analysis - prepare a 1 page presentation slide which contains all the relevant information about the various options for the data provisioning so the Data Bank management team can make an informed decision.
