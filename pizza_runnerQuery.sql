--Let's begin by cleaning some of the dirty tables, e.g customer_orders and runner-orders table
--NB1. When creating a TEMP table in T-SQL, use select into as oppose to create temp table.
select order_id, customer_id,pizza_id, 
case 
    when exclusions is null or exclusions LIKE 'NULL' then ' '
	else exclusions
	end  exclusions,
case 
    when extras is NULL or extras like 'null' then ' '
	else extras
	end extras,
order_time

INTO CustomerOrderTemp2

from customer_orders;

--2.Here, I will be creating a new cleaned table for the runner_order table called RunnerOrderTemp

select order_id, runner_id,
case 
    when pickup_time like 'null' then ' '
	else pickup_time
	end pickup_time,
case 
    when distance like 'null' then ' '
	when distance like '%km' then TRIM('km' from distance)
	else distance
	end distance,
case 
    when duration like 'null' then ' '
	when duration like '%minutes' then TRIM('minutes' from duration)
	when duration like '%mins' then TRIM('mins' from duration)
	when duration like '%minute' then TRIM('minute' from duration)
	else duration
	end duration,
case 
    when cancellation like 'null' or cancellation is null  then ' '
	else cancellation
	end cancellation

into RunnerOrderTemp2

from runner_orders;

select * from RunnerOrderTemp2;

--3. The 3rd Transformation step is to change the data type of some columns, so that they can be ease to work with.
---ANS: To alter the data type of a desired table, just go to the table and right click, then select design and change as appropriate.

--------------------------------PIZZA METRICS SOLUTIONS------------------
--1.How many pizzas were ordered?
select count(order_id) Pizza_counts
from CustomerOrderTemp2;
-----ANS; 14 pizza were ordered.

--2.How many unique customer orders were made?
select count(distinct order_id) uniqueOrder
from CustomerOrderTemp2;
-----ANS: There are 10 unique orders by the customers

--3.How many successful orders were delivered by each runner?
select runner_id, count(*) successfulOrder
from RunnerOrderTemp2
where distance != 0
group by runner_id;
-----ANS: Runner 1 has 4 successful delivered orders.
--Runner 2 has 3 successful delivered orders.
--Runner 3 has 1 successful delivered order.

--4.How many of each type of pizza was delivered?

select c.pizza_id, count(r.order_id) NoOfPizza
from CustomerOrderTemp2 c join RunnerOrderTemp2 r on c.order_id = r.order_id
where distance !=0
group by c.pizza_id;

-----ANS: Pizza with ID 1 has 9 delivery while the other pizza type has 3 delivery.

--QUE5. How many Vegetarian and Meatlovers were ordered by each customer?
select count(c.order_id) NoOfPizzaOrder, c.customer_id, n.pizza_name
from CustomerOrderTemp2 c inner join pizza_names n on c.pizza_id=n.pizza_id
group by c.customer_id, n.pizza_name
order by c.customer_id;
-----ANS: Each customer ordered more Meatlovers than vegetarian, with Customer 103 and 104 with the most order of 3.

--QUE6.What was the maximum number of pizzas delivered in a single order?

with max_order as (
select c.order_id , count(*) PizzaOrder 
from CustomerOrderTemp2 c join RunnerOrderTemp2 r on c.order_id =r.order_id
where r.distance != 0
group by c.order_id  )
select  max(PizzaOrder) MaximumPizzaOrdered
from max_order;
-----ANS: The maximum number of pizza ordered is 3

--QUE7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?--------------REVISIT

select c.customer_id, count(*) OrderperCust,
sum
    (case when c.exclusions <> ' ' or c.extras <> ' ' then 1 else 0 end) atleastoneChange,
sum (case when c.exclusions = ' ' and c.extras = ' ' then 1 else 0 end) noChange
from CustomerOrderTemp2 c join RunnerOrderTemp2 r on c.order_id = r.order_id
where r.distance <> 0
group by c.customer_id;
-----ANS: customer IDs 103 and 105 had at least one change. in the pizza delivered 
-- While customer IDs 101 and 102 had pizza with no change at all
---Only customer 104 had an order where there are changes and also an order without any changes.

--QUE8.  How many pizzas were delivered that had both exclusions and extras?
select 
sum (case when c.exclusions <> ' ' and c.extras <> ' ' then 1 else 0 end) bothChange
from CustomerOrderTemp2 c join RunnerOrderTemp2 r on c.order_id = r.order_id
where r.distance <> 0;
-----ANS: Only on of the delivered orders has both changes made.

--QUE9 What was the total volume of pizzas ordered for each hour of the day?
SELECT 
  DATEPART(HOUR, [order_time]) AS hour_of_day, 
  COUNT(order_id) AS pizza_count
FROM CustomerOrderTemp2
GROUP BY DATEPART(HOUR, [order_time]);

-----ANS: Highest volume of pizza ordered is at 13 (1:00 pm), 18 (6:00 pm) and 21 (9:00 pm)and 23(11.00pm)
--Lowest volume of pizza ordered is at 11 (11:00 am)and  19 (7:00 pm) 

--QUE 10 What was the volume of orders for each day of the week?
SELECT 
   datename(dw,order_time) as DayOftheWeek,  COUNT(order_id) AS pizza_count
FROM CustomerOrderTemp2
group by datename(dw,order_time)
order by pizza_count;

-----ANS: More Pizza where on WEDNESSDAY and SATURDAY, while the least amount of pizza was order on FRIDAY.


---------------------B, RUNNER AND CUSTOMER EXPERIENCE----------------------------------
--QUE1;How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)?
select  DATEPART(WEEK, registration_date) registration_week, count(*) runner_signup
from runners
group by DATEPART(WEEK, registration_date);
----- week 1 and 3 has one signUp each while week 2 has two signUp
--QUE2; What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
with timeSpentCte as (

select c.order_id, c.order_time, r.pickup_time,   DATEDIFF(minute,c.order_time, r.pickup_time) pickupMin
from RunnerOrderTemp2 r
join CustomerOrderTemp2 c on r.order_id = c.order_id
where r.duration <> 0
group by c.order_id, c.order_time, r.pickup_time)

select avg(pickupMin) avgPickup_Minutes
from timeSpentCte
where pickupMin > 1;

-----ANS: The average time taken in minutes by runners to arrive at Pizza Runner HQ to pick up the order is 16 minutes.

--QUE3.Is there any relationship between the number of pizzas and how long the order takes to prepare?
with preparationTime as  (
select count(c.order_id) as pizza_order, c.order_time, r.pickup_time, DATEDIFF( minute, c.order_time,r.pickup_time) prepMinute
from RunnerOrderTemp2 r 
join CustomerOrderTemp2 c on r.order_id = c.order_id

where r.distance != 0
group by c.order_time, r.pickup_time)

select   pizza_order, avg(prepMinute) timeTOPrep
from preparationTime
group by pizza_order;

----ANS: 1. On average, a single pizza order takes 12 minutes to prepare.
------2. An order with 3 pizzas takes 30 minutes at an average of 10 minutes per pizza.
------3. It takes 16 minutes to prepare an order with 2 pizzas which is 9 minutes per pizza — therefore,making 2 pizzas in a single order the ultimate efficiency rate.


--QUE4. What was the average distance travelled for each customer?

select c.customer_id, avg( r.distance) avgDistance
from CustomerOrderTemp2 c 
join RunnerOrderTemp2 r on c.order_id = r.order_id
where r.distance <> 0
group by customer_id;
----------ANS: Customer 104 stay nearest to the Pizza HQ, while 105 stays futhest from the HQ

--QUE 5. What was the difference between the longest and shortest delivery times for all orders?
select max(duration)-min(duration) diff
from RunnerOrderTemp2
where distance <> 0;

-----ANS: The difference between longest (40 minutes) and shortest (10 minutes) delivery time for all orders is 30 minutes.

--QUE 6 What was the average speed for each runner for each delivery and do you notice any trend for these values?
select  r.runner_id, c.order_id, c.customer_id, r.distance, r.duration , ROUND( (r.distance/r.duration * 60),2) AS avg_speed   
from RunnerOrderTemp2 r
join CustomerOrderTemp2 c on r.order_id= c.order_id
where distance <> 0 
group by  r.runner_id, c.order_id, c.customer_id, r.distance, r. duration;
-------ANS: Runner A average speed runs from 37.5km/h to 60km/h
        --- Runner B has a average speed from 35.1km/h to 93.6km/h
		--- Runner C has a average speed of 40km/h


--QUE 7.What is the successful delivery percentage for each runner?
select runner_id, sum ( 100*
case when distance = 0 then 0
else 1 end
) / count(*)   as SuccessRate
from RunnerOrderTemp2
group by runner_id;


-----ANS: Only runner ID one has an hundred percent delivery rate.

----------------------------INGREDIENT OPTIMIZATION-----------------------------------------------------------------
--QUE1. What are the standard ingredients for each pizza?
select *
from pizza_names n 
join pizza_recipes r on n.pizza_id = r.pizza_id;


--QUE2. What was the most commonly added extra?







































