--QUE1. What is the total amount each customer spent at the restaurant?
select * from sales;
select * from menu;
select * from members;
select s.customer_id, format( sum( m.price  ), 'C') total_sales
from sales s inner join menu m on s.product_id = m.product_id
group by s.customer_id;
-----ANS; Customer A has spent the highest amount of money on any of the menu available, I used the T-SQL format option to display the dollar sign

--QUE2: How many days has each customer visited the restaurant?
select customer_id,  count(distinct order_date) NoOfDaysVisited
from sales
group by  customer_id;
-----ANS: I used a count to wrap the distinct order date, this is because, without the distinct, we are going to
-- get duplicate values for some customer who visited twice in same day.

--QUE 3: What was the first item from the menu purchased by each customer?
with CTEfirstPurchase as (
select s.customer_id,  m.product_name, 
dense_rank () OVER ( partition by s.customer_id order by s.order_date
) rankValue
from sales s inner join 
 menu m on s.product_id = m.product_id)
 select customer_id, product_name
 from CTEfirstPurchase
 where rankValue = 1
 group by customer_id, product_name;
-----ANS:Here, i make use of Window function "dense rank" to first get a group of each customer purchases, after which I use the 
-- Common Table Expression CTE to the the first rank in each customer group.

--QUE What is the most purchased item on the menu and how many times was it purchased by all customers?
select TOP 1 m.product_name, sum(m.price) TotalPurchase, count(m.product_name) NoOfpurchase
from sales s inner join  menu m on s.product_id = m.product_id
group by  m.product_name
order by NoOfpurchase DESC;
-----ANS; Ramen is the most purchased item by all customer, with a total sale of $96 and it was purchased a total of 8 times

--QUE 5. Which item was the most popular for each customer?
with MostPopular as (
select s.customer_id, m.product_name, sum(m.price) TotalPurchase, count(m.product_name) NoOfpurchase,
RANK () OVER (partition by s.customer_id order by count(m.product_name) desc) rankValue
from sales s inner join  menu m on s.product_id = m.product_id
group by s.customer_id, m.product_name )
select customer_id, product_name, NoOfpurchase
from MostPopular
where rankValue = 1 ;
-----ANS; First, I created a join between the menu and sales table to get information for all customers and not the members alone(customer 'C')
-- is not a memeber. I obtained the no of purchases on each meanu item for each Customers, then use the window function 'RANk' to group each customer
-- preference in term of number, then a created a CTE, whic only select the item rank 1 in each of the customer purchase group.


--QUE6. Which item was purchased first by the customer after they became a member?

WITH CTE_FIRSTORDER AS (
select s.customer_id, m.product_name, s.order_date, me.join_date,
RANK () OVER (partition by s.customer_id order by s.order_date) as Rankvalue
from sales s inner join menu m on s.product_id=m.product_id inner join members me on s.customer_id = me.customer_id
where me.join_date <= s.order_date)

select customer_id, product_name, order_date
from CTE_FIRSTORDER
where Rankvalue = 1;

-----ANS; The first Customer ordered Curry when he became a member, while that for customer B was sushi

--QUE 7. Which item was purchased just before the customer became a member?
with cte_lastbefore AS (
select s.customer_id, m.product_name, s.order_date, me.join_date,
RANK () OVER (partition by s.customer_id order by s.order_date desc) as Rankvalue
from sales s inner join menu m on s.product_id=m.product_id inner join members me on s.customer_id = me.customer_id
where   s.order_date < me.join_date)
select customer_id, product_name
from cte_lastbefore
where Rankvalue = 1;

-----ANS; Here, I tried to look out for the order each member had just clos to the time they became a member. 
-- and as we can see, Customer A had, sushi and curry while customer B had Sushi right before becoming a member.

--QUE8. What is the total items and amount spent for each member before they became a member?
select s.customer_id, count( distinct m.product_name) NOofItems, format (sum( m.price), 'C') Total_spent --, s.order_date, me.join_date
--RANK () OVER (partition by s.customer_id order by s.order_date desc) as Rankvalue
from sales s inner join menu m on s.product_id=m.product_id inner join members me on s.customer_id = me.customer_id
where   s.order_date < me.join_date
group by s.customer_id;

-----ANS: Both customers had 2 distinct item purchased before becaming a member and combine amount of $65.00, however, Customer B spent more than Customer A.


--QUE9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier — how many points would each customer have?
with cte_point as (
select s.customer_id, m.product_name,
case 
     when m.product_name = 'sushi' then sum(m.price) * 20
	 else  sum(m.price) * 10 
	 end PointPercustomer
from sales s inner join menu m on s.product_id=m.product_id 
group by s.customer_id, m.product_name
)

select customer_id, sum(PointPercustomer) PointPerCustomer
from cte_point
group by customer_id;
-----ANS: Here, the question is an IF....ELSE statement, and it therefore require the use of CASE Statement to solve it, 
--also, The result of the main query can then serve as a view/sub query for the common table expression/outer query.
--The output reveal that customer B had the heightest point of 940 for all brand of products.

--QUE 10.In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 

with date_cte as 
(SELECT *, 
      DATEADD(DAY, 6, join_date) AS valid_date, 
      EOMONTH('2021-01-31') AS last_date
   FROM members AS m)

select d.customer_id, s.order_date, d.join_date, d.valid_date, d.last_date, m.product_name, m.price,
SUM(CASE
      WHEN m.product_name = 'sushi' THEN 2 * 10 * m.price
      WHEN s.order_date BETWEEN d.join_date AND d.valid_date THEN 2 * 10 * m.price
      ELSE 10 * m.price
      END) AS points
from date_cte d 
join sales s on d.customer_id = s.customer_id
join  menu m on s.product_id = m.product_id 
where s.order_date < d.last_date
group by d.customer_id, s.order_date, d.join_date, d.valid_date, d.last_date, m.product_name, m.price;

















