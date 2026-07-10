create database retail_analysis;
use retail_analysis;

# altering tables
alter table clean_orders modify order_date Date;
alter table clean_orders modify required_date Date;
alter table clean_orders modify shipped_date date null;
alter table staffs_cleaned modify manager_id int;

# altering tables by adding primary key 
alter table customers_cleaned add primary key (customer_id);
alter table stores_cleaned add primary key (store_id);
alter table staffs_cleaned add primary key(staff_id);
alter table brands_cleaned add primary key(brand_id);
alter table categories_cleaned add primary key(category_id);
alter table products_cleaned add primary key(product_id);
alter table clean_orders add primary key(order_id);


#composite primary key 
alter table order_items_cleaned add primary key(order_id,item_id);
alter table stocks_cleaned add primary key(store_id,product_id);


# altering tables by adding foreign key 
#orders 
Alter table clean_orders add constraint fk_orders_customers foreign key (customer_id) 
references customers_cleaned(customer_id);
Alter table clean_orders add constraint fk_orders_stores foreign key (store_id) 
references stores_cleaned(store_id);
Alter table clean_orders add constraint fk_orders_staffs foreign key (staff_id) 
references staffs_cleaned(staff_id);

#products 
Alter table products_cleaned add constraint fk_products_brands foreign key (brand_id) 
references brands_cleaned(brand_id);
Alter table products_cleaned add constraint fk_products_categories foreign key (category_id) 
references categories_cleaned(category_id);

#order_items table 
alter table order_items_cleaned add constraint fk_orderitems_orders foreign key (order_id)
references clean_orders(order_id);
alter table order_items_cleaned add constraint fk_orderitems_products foreign key (product_id)
references products_cleaned(product_id);

#stocks_cleaned
alter table stocks_cleaned add constraint fk_stocks_store foreign key (store_id)
references stores_cleaned(store_id); 
alter table stocks_cleaned add constraint fk_stocks_product foreign key (product_id)
references products_cleaned(product_id); 

#staffs cleaned 
alter table staffs_cleaned add constraint fk_staffs_store foreign key (store_id)
references stores_cleaned(store_id); 

#self-reference foreign key
alter table staffs_cleaned add constraint fk_staffs_manager foreign key (manager_id) 
references staffs_cleaned(staff_id);

#Total Sales Analysis
# Total Revenue
select round(sum(quantity*list_price*(1 - discount)),0) as total_sales from order_items_cleaned;

#Top 10 products 
Select
    p.product_name,
    t.revenue
From products_cleaned p Inner
join
(
    Select
        product_id,
        Round(Sum(quantity * list_price * (1 - discount)),0) AS revenue
    From order_items_cleaned
    Group by product_id
) t
On p.product_id = t.product_id
Order by t.revenue desc
Limit 10;

# sales by store

Select 
    s.store_name,
    Round(Sum(oi.quantity * oi.list_price * (1 - oi.discount)),0) AS total_sales
From clean_orders o
Inner Join order_items_cleaned oi
On o.order_id = oi.order_id
Inner Join stores_cleaned s
On o.store_id = s.store_id
Group by s.store_id, s.store_name
Order by total_sales desc ;


# Customer Analysis 

# Repeat Customers 

Select c.customer_id , c.first_name , c.last_name , Count(o.order_id) As total_orders 
From customers_cleaned c Inner Join clean_orders o 
On c.customer_id = o.customer_id
Group by c.customer_id , c.first_name , c.last_name 
having Count(o.order_id)>1
Order by total_orders Desc;

# Highest Spending Customers 

Select c.customer_id , c.first_name , c.last_name , 
Round(Sum(oi.quantity*oi.list_price*(1-oi.discount)),0) as total_spending 
From customers_cleaned c Inner Join clean_orders o On c.customer_id = o.customer_id
Inner Join order_items_cleaned oi on o.order_id = oi.order_id Group by c.customer_id ,
c.first_name,c.last_name Order by total_spending desc ;

# Inventory Analysis
# Stock Availabale by store 
Select s.store_name , p.product_name,st.quantity From stocks_cleaned st 
Inner Join stores_cleaned s  On st.store_id = s.store_id 
Inner join products_cleaned p On st.product_id = p.product_id Order by st.quantity desc;

#Low Stock Products
Select s.store_name , p.product_name,st.quantity From stocks_cleaned st 
Inner Join stores_cleaned s On st.store_id = s.store_id 
Inner Join products_cleaned p On st.product_id = p.product_id 
where st.quantity <= 10 
order by st.quantity; 
drop view sales_summary;

#creating view as sales_summary

create view sales_summary as
select o.order_id, o.order_date,
o.customer_id, o.store_id, o.staff_id,
oi.product_id, 
p.product_name,
b.brand_name,
c.category_name,
st.store_name,
st.state, s.first_name as staff_first_name,
s.last_name as staff_last_name,
cu.first_name as customer_first_name,
cu.last_name as customer_last_name,
oi.quantity, oi.list_price, oi.discount,
(oi.quantity * oi.list_price * (1 - oi.discount)) as sales_amount
from clean_orders o
inner join order_items_cleaned oi on o.order_id = oi.order_id
inner join products_cleaned p on oi.product_id = p.product_id
inner join brands_cleaned b on p.brand_id = b.brand_id
inner join categories_cleaned c on p.category_id = c.category_id
inner join stores_cleaned st on o.store_id = st.store_id
inner join staffs_cleaned s on o.staff_id = s.staff_id
inner join customers_cleaned cu on o.customer_id = cu.customer_id;

create view sales_summary_region as select ss.* , cu.city as customer_city,
cu.state as customer_state
from sales_summary ss 
inner join customers_cleaned cu on ss.customer_id = cu.customer_id;


