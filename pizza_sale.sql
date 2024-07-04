select * from pizzas;
select * from pizza_types;
select * from orders;
select * from order_details;





-- 1) Retrieve the total number of orders placed.

-- solution A:
select count(order_id) as "total orders" from orders;

-- solution B:
select max(order_id) as "total orders" from order_details;







-- 2) Calculate the total revenue generated from pizza sales.

-- solution A:

select round(sum(p.price * od.quantity)::numeric,2) as total_revenue
from pizzas as p join order_details as od
on p.pizza_id = od.pizza_id;

-- solution B:
select round(sum(sod.total_quantity*p.price)::numeric,2) from
(select od.pizza_id, sum(od.quantity) as "total_quantity" from order_details od
group by od.pizza_id) sod
join pizzas p on p.pizza_id = sod.pizza_id;






-- 3) Identify the highest-priced pizza.

-- solution A:
select max(p.price) from pizzas p
join pizza_types pt
on pt.pizza_type_id = p.pizza_type_id;
-- the problem with solution A is that we cant include pizza name without using group by clause

-- solution B: with pizza name
select pt.name, p.price from pizzas p 
join pizza_types pt
on pt.pizza_type_id = p.pizza_type_id
order by p.price desc limit 1;






-- 4) Identify the most common pizza size ordered.

-- solution A:
select p.size, sum(od.quantity) as "total_quantity" from pizzas p
join order_details od
on p.pizza_id = od.pizza_id
group by p.size order by total_quantity desc;

-- solution B:
with cal_size as
(select *,
case 
when od.pizza_id like '%xxl' then 'double extra large'
when od.pizza_id like '%xl' then 'extra large'
when od.pizza_id like '%l' then 'large'
when od.pizza_id like '%m' then 'medium'
when od.pizza_id like '%s' then 'small'
end as pizza_size
from order_details od)

select pizza_size, sum(quantity) as total_quantity from cal_size
group by pizza_size
order by total_quantity desc;







-- 5) List the top 5 most ordered pizza types along with their quantities.

-- solution A:
select pt.name, sum(od.quantity) as total_quantity
from pizza_types pt
join pizzas p
on pt.pizza_type_id = p.pizza_type_id
join order_details od
on od.pizza_id = p.pizza_id
group by pt.name order by total_quantity desc limit 5;


-- if you want to break down the pizza type to category and size, then here is the ans
select pt.name, pt.category, p.size, sum(od.quantity) as total_quantity
from pizza_types pt
join pizzas p
on pt.pizza_type_id = p.pizza_type_id
join order_details od
on od.pizza_id = p.pizza_id
group by pt.name, pt.category, p.size order by total_quantity desc limit 5;

-- you will see some difference between the current and previous answer









-- 6) Join the necessary tables to find the total quantity of each pizza category ordered.

-- solution A:

select pt.category, sum(od.quantity) as total_quantity
from pizza_types pt
join pizzas p
on pt.pizza_type_id = p.pizza_type_id
join order_details od
on od.pizza_id = p.pizza_id
group by pt.category order by total_quantity desc;








-- 7) Determine the distribution of orders by hour of the day.

-- solution A:
select date_part('hour', o.time) as order_hour, count(o.order_id)as no_of_orders
from orders o
group by date_part('hour', o.time)
order by no_of_orders desc;








-- 8) Join relevant tables to find the orders category-wise distribution of pizzas.

-- solution A:

select pt.category, count(od.order_id)as no_of_orders from pizzas p
join order_details od
on od.pizza_id = p.pizza_id
join pizza_types pt
on pt.pizza_type_id = p.pizza_type_id
group by pt.category
order by no_of_orders desc
;






-- 9) Group the orders by date and calculate the average number of pizzas ordered per day.
-- solution A:

select round(avg(no_of_orders)::numeric, 0) as avg_order_per_day from
(select o.date, sum(od.quantity)as no_of_orders from orders o
join order_details od
on od.order_id = o.order_id
group by o.date)
;






-- 10) Determine the top 3 most ordered pizza types based on revenue.

-- solution A:
select pt.name, round(sum(od.quantity*p.price)::numeric, 0) as revenue from order_details od
join pizzas p
on od.pizza_id = p.pizza_id
join pizza_types pt
on pt.pizza_type_id = p.pizza_type_id
group by pt.name
order by revenue desc
limit 3;






-- 11) Calculate the percentage contribution of each pizza type to total revenue.
-- solution A:
select category, round(revenue::numeric,0), round(total_revenue::numeric,0),
round((revenue/total_revenue)::numeric,2)*100 as percentage
from
(select pt.category, sum(od.quantity*p.price) as revenue, 
sum(sum(od.quantity*p.price)) over() as total_revenue
from order_details od
join pizzas p
on od.pizza_id = p.pizza_id
join pizza_types pt
on pt.pizza_type_id = p.pizza_type_id
group by pt.category
order by revenue desc);








-- 12) Analyze the cumulative revenue generated over time.
-- solution A:
select date,
sum(revenue) over(order by date) as cum_sum
from
(
	select o.date, sum(p.price*od.quantity) as revenue
	from orders o
	join order_details od
	on o.order_id = od.order_id
	join pizzas p 
	on p.pizza_id = od.pizza_id
	group by o.date
);






-- 13) Determine the top 3 most ordered pizza types based on revenue for each pizza category.
-- solution A:
select name, category, round(revenue::numeric,2) as revenue
from
(
	select *,
	row_number() over(partition by category order by revenue desc) as sales
	from
	(
		select pt.name, pt.category, sum(p.price*od.quantity) as revenue
		from pizzas p
		join pizza_types pt
		on p.pizza_type_id = pt.pizza_type_id
		join order_details od
		on od.pizza_id=p.pizza_id
		group by pt.name, pt.category
	)
) where sales<=3;
