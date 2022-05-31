CREATE TABLE plans (
  plan_id INTEGER,
  plan_name VARCHAR(13),
  price DECIMAL(5,2)
);

INSERT INTO plans
  (plan_id, plan_name, price)
VALUES
  ('0', 'trial', '0'),
  ('1', 'basic monthly', '9.90'),
  ('2', 'pro monthly', '19.90'),
  ('3', 'pro annual', '199'),
  ('4', 'churn', null);



CREATE TABLE subscriptions (
  customer_id INTEGER,
  plan_id INTEGER,
  start_date DATE
);
BULK INSERT subscriptions
FROM 'C:\Users\Victor Jokanola\Desktop\DATA SCIENCE\subscriptn.txt.txt'
WITH (
   FIELDTERMINATOR = ',',
   ROWTERMINATOR = '\n'
);

BULK INSERT subscriptions
FROM 'C:\Users\Victor Jokanola\Desktop\DATA SCIENCE\subscriptn2.txt.txt'
WITH (
   FIELDTERMINATOR = ',',
   ROWTERMINATOR = '\n'
);

BULK INSERT subscriptions
FROM 'C:\Users\Victor Jokanola\Desktop\DATA SCIENCE\subscriptn3.txt.txt'
WITH (
   FIELDTERMINATOR = ',',
   ROWTERMINATOR = '\n'
);
--------------------------SECTION A CUTOMER JOURNEY------------------------------------------
---SECTION A. QUESTION 1: Based off the 8 sample customers provided (customer ID 1,2,11,13,15,16,18,19) in the sample from the subscriptions table,
---write a brief description about each customer’s onboarding journey.

select * from plans p
join subscriptions s on p.plan_id = s.plan_id
where s.customer_id in (1,2,11,13,15,16,18,19);
-------ANSWER
--Customer 1; Satrted with the free trial and downgraded to the basic montly plan after a week.
-- Customer 2; Upgraded to the Pro annual plan after the initial trial.
-- Customer 11; Churn after the free trial
-- Customer 13; Downgraded to the basic plan after the free trial, then upgraded to the pro monthly after a week.
-- Customer 15; Maintains the pro monthly plan after free trials but churn 5 days into the plan.
-- Customer 16; Downgraded to the basic monthly plan and upgraded to the pro annual plan after 2 weeks
-- Customer 18; Maintain the pro monthly after the trial, same as customer 19, but upgraded to the pro monthly after 2 months.


------------------------SECTION B, DATA ANALYSIS QUESTIONS------------------------------
--QUE1;How many customers has Foodie-Fi ever had?
select count(distinct customer_id) from subscriptions;
-------ANSWER; Foodfi has 1000 unique customers.

--QUE2; What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
select 
 DATEPART(month, start_date) as month_date, --Cast to month in numbers
 DATENAME(month,start_date) AS month_name, -- Cast to month in names
  COUNT(*) AS trial_subscriptions

from subscriptions
where plan_id = 0
group by  DATENAME(month, start_date), DATEPART(month, start_date)
order by month_date;

-----ANSWER: March has the highest number of trial plans, whereas February has the lowest number of trial plans.

--QUE3;What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
SELECT 
  p.plan_id,
  p.plan_name,
  sum(case when s.start_date < '2021-01-01' then 1 else 0 end ) as event_2020,
  sum(case when s.start_date >= '2021-01-01' then 1 else 0 end ) as event_2021
FROM subscriptions s
JOIN plans p
  ON s.plan_id = p.plan_id
GROUP BY p.plan_id, p.plan_name
ORDER BY p.plan_id;

----ANSWER There were 0 customer on trial plan in 2021. Does it mean that there were no new customers in 2021, 
--or did they jumped on basic monthly plan without going through the 7-week trial?
--There more Churn than any other other plan in 2021, although the churn has greately reduce in 2021.

--QUE4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
select 
  sum( case when plan_id = 4 then 1 else 0 end ) as churn_count,
  100*sum( case when plan_id = 4 then 1 else 0 end )  /count(distinct customer_id) as Churn_percentage
from subscriptions;
--where plan_id = 4;

-----ANSWER; There are 307 customers who have churned, which is 30.7% of Foodie-Fi customer base.

--QUE5;How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?

with ranking as (

select customer_id, plan_id, 
RANK () OVER (partition by customer_id order by plan_id) custRank
from subscriptions)

select count(*) churn_count,
100*count(*)/   (select count(distinct customer_id) from subscriptions) churn_percantage
from ranking
WHERE plan_id = 4 -- Filter to churn plan
  AND custRank = 2 --Filter to rank 2 as customers who churned immediately after trial have churn plan ranked as 2

-----ANSWER; There are 92 customers who churned straight after the initial free trial which is at 9% of entire customer base.

--	QUE 6;What is the number and percentage of customer plans after their initial free trial?
with next_planCTE as (
select customer_id, plan_id,
LEAD(plan_id, 1) OVER (partition by customer_id order by plan_id) next_plan
from subscriptions )
select 
next_plan,count(*) Conversion,
CAST (ROUND(100*count(*) / (select count(distinct customer_id) from subscriptions),1) AS numeric(10,2))  Conversion_percentage
from next_planCTE
where next_plan IS NOT NULL 
  AND plan_id = 0
group by next_plan
order by next_plan;
-----ANSWER
--More than 80% of customers are on paid plans with small 3.7% on plan 3 (pro annual $199). 
--Foodie-Fi has to strategize on their customer acquisition who would be willing to spend more.

--QUE 7.What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?



--QUE8.How many customers have upgraded to an annual plan in 2020?

select count(distinct customer_id) annualSubscriber
from subscriptions
where plan_id = 3 and start_date <= '2020-12-31';
--196 customers upgraded to an annual plan in 2020.

--QUE9.How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?

-- Filter results to customers at trial plan = 0
WITH trial_plan AS (
SELECT 
  customer_id, 
  start_date AS trial_date
FROM subscriptions
WHERE plan_id = 0),
-- Filter results to customers at pro annual plan = 3
 annual_plan AS(
SELECT 
  customer_id, 
  start_date AS annual_date
FROM subscriptions
WHERE plan_id = 3)

SELECT round (avg (DATEDIFF(DAY, trial_date, annual_date)),0) avg_day_to_annual
from trial_plan tp
join annual_plan ap on tp.customer_id=ap.customer_id;
--------On average, it takes 104 days for a customer to upragde to an annual plan from the day they join Foodie-Fi.

--QUE10;Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
