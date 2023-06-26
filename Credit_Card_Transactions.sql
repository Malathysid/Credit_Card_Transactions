-- Write a query to print top 5 cities WITH highest spends and their percentage contribution of total credit card spends
WITH cte AS(
SELECT sum(amount) AS city_spend,city 
FROM credit_card_transactions 
GROUP BY city)
SELECT *,round(city_spend/(SELECT sum(amount) FROM credit_card_transactions)*100,2) AS precentage 
FROM cte ORDER BY city_spend DESC LIMIT 5;

-- Write a query to print highest spend month and amount spent in that month for each card type
WITH total_amount AS (
SELECT 
	card_type,
	MONTH(transaction_date) AS Transaction_Month,
	YEAR(transaction_date) AS Transaction_Year,
    SUM(amount) AS total_sum
FROM credit_card_transactions
GROUP BY card_type,MONTH(transaction_date),YEAR(transaction_date))
SELECT * FROM (SELECT *,RANK() OVER(PARTITION BY card_type ORDER BY total_sum desc) AS rn  FROM total_amount) x WHERE rn=1;

WITH total_amount AS (
SELECT 
	card_type,
	MONTH(transaction_date) AS Transaction_Month,
	YEAR(transaction_date) AS Transaction_Year,
    SUM(amount) AS total_sum
FROM credit_card_transactions
GROUP BY card_type,MONTH(transaction_date),YEAR(transaction_date))
SELECT * FROM (SELECT *,max(total_sum) OVER(PARTITION BY card_type) AS max_amount  FROM total_amount) x WHERE total_sum=max_amount;

/*Write a query to print the transaction details(all columns FROM the table) for each card type when
it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)*/

WITH cte AS (
SELECT 
	*,
    SUM(amount) OVER(PARTITION BY card_type ORDER BY transaction_date,transaction_id) AS total_spend
FROM credit_card_transactions)
SELECT * FROM (
	SELECT *,
			RANK() OVER(PARTITION BY card_type ORDER BY total_spend) AS rn 
	FROM cte WHERE total_spend>=1000000) x 
WHERE rn=1;

-- Write a query to find city which had lowest percentage spend for gold card type
WITH CTE as (
SELECT 
		sum(amount) as amount,
        sum(case when card_type='Gold' then amount end) as gold_amount,
        city,
        card_type
FROM credit_card_transactions
group by city,card_type)
select city,sum(gold_amount)/sum(amount)*100 as total_percentage from cte 
group by city 
having sum(gold_amount) is not null
order by total_percentage
limit 1;
        
-- Write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)

with cte as (
select city,exp_type, sum(amount) as total_amount from credit_card_transactions
group by city,exp_type)
select
city , max(case when rn_asc=1 then exp_type end) as lowest_exp_type
, min(case when rn_desc=1 then exp_type end) as highest_exp_type
from
(select *
,rank() over(partition by city order by total_amount desc) rn_desc
,rank() over(partition by city order by total_amount asc) rn_asc
from cte) A
group by city;



-- Write a query to find percentage contribution of spends by females for each expense type

WITh cte AS (
SELECT 
		exp_type,
        SUM(amount) AS total_amount,
        SUM(case when gender='F' then amount end) AS female_spent 
FROM credit_card_transactions 
GROUP BY exp_type )
SELECT  exp_type,
		(female_spent/total_amount)*100 AS female_per 
FROM cte;

-- Which card and expense type combination saw highest month over month growth in Jan-2014
WITH cte as (
SELECT 
		SUM(amount) as total_amount,
        card_type,
        exp_type,
        YEAR(transaction_date) AS yr,
        MONTH(transaction_date) AS mth 
FROM credit_card_transactions
GROUP BY card_type,exp_type,YEAR(transaction_date),MONTH(transaction_date)),
cte1 AS (
	SELECT 
		*,lag(total_amount) OVER( PARTITION BY card_type,exp_type order by yr,mth)  AS pre_mnth_amount 
	FROM cte)
SELECT card_type,exp_type,mom FROM (SELECT *,(total_amount-pre_mnth_amount)/pre_mnth_amount AS mom FROM cte1
WHERE yr=2014 AND mth=01 AND pre_mnth_amount IS NOT NULL ) x ORDER BY mom DESC LIMIT 1;


-- During weekends which city has highest total spend to total no of transcations ratio
select city,sum(amount)/count(1) as ratio
from credit_card_transactions
where dayname(transaction_date) in ('Saturday','Sunday')
group by city
order by ratio desc
limit 1


-- Which city took least number of days to reach its 500th transaction after the first transaction in that city

with cte as ( (select a.city,datediff(a.transaction_date,b.transaction_date) as duration from 
(select * from (
select *,row_number() over (partition by city order by transaction_date) as rn from credit_card_transactions) x where rn=500) a
left join
(select * from (
select *,row_number() over (partition by city order by transaction_date) as rn from credit_card_transactions) y where rn=1) b
on a.city=b.city) )
select city,duration from cte where duration=(select min(duration) from cte);

with cte as (
select *
,row_number() over(partition by city order by transaction_date,transaction_id) as rn
from credit_card_transactions)
select city,datediff(max(transaction_date),min(transaction_date)) as datediff1
from cte
where rn=1 or rn=500
group by city
having count(1)=2
order by datediff1 limit 1
