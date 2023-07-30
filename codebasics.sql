use gdb023;
select * from dim_customer;
select * from dim_product;
select * from fact_sales_monthly;
select * from fact_manufacturing_cost;
select * from fact_pre_invoice_deductions;
select * from fact_gross_price;
#1. Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.
select distinct(market) from dim_customer where customer='Atliq Exclusive' and region='APAC';
#2. What is the percentage of unique product increase in 2021 vs. 2020? The final output contains these fields, unique_products_2020 unique_products_2021 percentage_chg
with temp1 as(
select count(distinct(product_code)) as unique_product_2020 from fact_sales_monthly where fiscal_year='2020'),
temp2 as(
select count(distinct(product_code)) as unique_product_2021 from fact_sales_monthly where fiscal_year='2021')
select t1.unique_product_2020, t2.unique_product_2021,round(100*((unique_product_2021-unique_product_2020)/unique_product_2020),2) as percent_change
from temp1 t1 join temp2 t2;
#3. Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. The final output contains 2 fields, segment product_count
select segment,count(distinct(product_code)) as product_count from dim_product group by segment order by product_count desc;
#4. Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? The final output contains these fields, segment product_count_2020 product_count_2021 difference
with temp1 as(
select p.segment as segment1, count(distinct(s.product_code)) as product_count_2020 from dim_product p join fact_sales_monthly s on p.product_code=s.product_code where s.fiscal_year='2020' group by p.segment),
temp2 as(
select p.segment as segment2, count(distinct(s.product_code)) as product_count_2021 from dim_product p join fact_sales_monthly s on p.product_code=s.product_code where s.fiscal_year='2021' group by p.segment)
select t1.segment1, t1.product_count_2020,t2.product_count_2021,t2.product_count_2021-t1.product_count_2020 as difference from temp1 t1 join temp2 t2 on t1.segment1=t2.segment2 order by difference desc;
#5. Get the products that have the highest and lowest manufacturing costs. The final output should contain these fields, product_code product manufacturing_cost
with temp1 AS(
select f.product_code AS product_code, p.product AS product, f.manufacturing_cost as manufacturing_cost
from fact_manufacturing_cost f join dim_product p on f.product_code=p.product_code
 group by p.product,p.product_code
 order by manufacturing_cost desc )
select product_code, product,manufacturing_cost from temp where manufacturing_cost=(select max(manufacturing_cost) from temp)
 union 
select product_code, product,manufacturing_cost from temp where manufacturing_cost=(select min(manufacturing_cost) from temp);
#6. Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market. The final output contains these fields, customer_code customer average_discount_percentage
select d.customer_code, c.customer, round(d.pre_invoice_discount_pct,2) as average_discount_percentage from fact_pre_invoice_deductions d join dim_customer c on d.customer_code=c.customer_code where d.fiscal_year='2021' and c.market='India' order by average_discount_percentage desc limit 5;
#7. Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month . This analysis helps to get an idea of low and high-performing months and take strategic decisions. The final report contains these columns: Month Year Gross sales Amount
select monthname(s.date) as month_name, s.fiscal_year as year, sum(s.sold_quantity*g.gross_price) as gross_sales_amount 
from fact_sales_monthly s join fact_gross_price g on s.product_code=g.product_code
join dim_customer c on s.customer_code=c.customer_code
where c.customer='Atliq Exclusive'
group by month_name,year;
#8. In which quarter of 2020, got the maximum total_sold_quantity? The final output contains these fields sorted by the total_sold_quantity, Quarter total_sold_quantity
select case when month(date) in (9,10,11) then '1'
            when month(date) in (12,1,2) then '2'
            when month(date) in (3,4,5) then '3'
            when month(date) in (6,7,8) then '4'
            end as Quarter_in_2020, sum(sold_quantity) as total_sold_quantity
from fact_sales_monthly 
where fiscal_year=2020
group by Quarter_in_2020
order by  total_sold_quantity desc;
#9. Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? 
with temp as(
select c.channel as channel, (sum(g.gross_price * s.sold_quantity)/1000000)  as gross_sales
from dim_customer c join fact_sales_monthly s on c.customer_code=s.customer_code
join fact_gross_price g on  g.product_code=s.product_code
where s.fiscal_year=2021
group by channel
)
select channel, round(gross_sales,2) as gross_sales_mln, round(100 * (gross_sales/sum(gross_sales) over()) ,2) as percentage from temp group by channel order by percentage desc;
#10. Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021
with temp1 as(
select p.division as division, p.product_code as product_code, p.product as product, sum(s.sold_quantity) as total_sold_quantity from dim_product p join fact_sales_monthly s on s.product_code=p.product_code
where s.fiscal_year=2021 
group by division,product_code, product
),
temp_2 as(
select *, rank() over (partition by division order by total_sold_quantity desc )  as rank_order from temp1) 
select * from temp_2 where rank_order<=3;
