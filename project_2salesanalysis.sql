-- OverView
select * from sales

-- summarizing unique values
select STATUS distnict from sales group by STATUS 
select year_id from sales group by year_id
select PRODUCTLINE from sales group by PRODUCTLINE
select CITY from sales group by CITY
select STATE from sales group by STATE
select COUNTRY from sales group by COUNTRY
select TERRITORY from sales group by TERRITORY
select DEALSIZE from sales group by DEALSIZE

-- Analysis
----- Revenue by ProductLine
select productline, SUM(sales) as totalRevenue
from sales
group by PRODUCTLINE
order by 2 desc

select productline, SUM(sales) as totalRevenue
from sales
group by PRODUCTLINE
order by 2 desc  -- Classic Cars contributed the most to revenue in 3 years

------ by year
select YEAR_ID, SUM(sales) as totalRevenue
from sales
group by YEAR_ID
order by 2 desc --- highest-2004, lowest -2005 - data not complete for 2005 or operations stopeed in 2005

----- monthly analysis 
select MONTH_ID, round(SUM(sales),2) as totalRevenue
from sales
group by MONTH_ID
order by 2 desc -- highest in Nov, Oct and May

select productline, SUM(sales) as totalRevenue
from sales
where MONTH_ID = 11
group by PRODUCTLINE
order by 2 desc

select productline, SUM(sales) as totalRevenue
from sales
where MONTH_ID = 10
group by PRODUCTLINE
order by 2 desc  --- Classic Cars have highest sales in productline in these months

select productline, SUM(sales) as totalRevenue
from sales
where MONTH_ID = 6
group by PRODUCTLINE
order by 2 desc

------ RFM analysis of Customers - Who is our best Customer

With cte1 as
(
	select CUSTOMERNAME,
	SUM(sales) totalrevenue,
	avg(sales) avgrevenue,
	COUNT(ORDERNUMBER) as Frequency,
	max(orderdate) lastorderdate,
	(select max(orderdate) from sales) as max_date,
	DATEDIFF(DD,max(orderdate),(select max(orderdate) from sales)) as recency
	from sales
	group by CUSTOMERNAME),
cte2 as (
	Select cte1.*, 
	NTILE(4) OVER(ORDER BY avgrevenue) rfm_monetary,
	NTILE(4) OVER(ORDER BY frequency) rfm_frequency,
	NTILE(4) OVER(ORDER BY recency desc) rfm_recency
	from cte1 ),
cte3 as (
	select c.*, 
	(c.rfm_frequency+c.rfm_monetary+c.rfm_recency) as rfm_sum,
	(cast(c.rfm_frequency as varchar)+cast(c.rfm_monetary as varchar)+cast(c.rfm_recency as varchar) )as rfm_cell
     from cte2  c) 
select * from cte3

---- Which Products are sold together
select PRODUCTCODE  from sales 
where ORDERNUMBER in (
	select ordernumber
	from  (
		select ORDERNUMBER, COUNT(*) as n from sales
		where status = 'shipped'
		group by ORDERNUMBER) as x
	where x.n = 2)


---- Our best customers/ RFM Analysis


DROP TABLE IF EXISTS #rfm
;with rfm as 
(
	select 
		CUSTOMERNAME, 
		sum(sales) MonetaryValue,
		avg(sales) AvgMonetaryValue,
		count(ORDERNUMBER) Frequency,
		max(ORDERDATE) last_order_date,
		(select max(ORDERDATE) from sales) max_order_date,
		DATEDIFF(DD, max(ORDERDATE), (select max(ORDERDATE) from sales)) Recency
	from sales
	group by CUSTOMERNAME
),
rfm_calc as
(

	select r.*,
		NTILE(4) OVER (order by Recency desc) rfm_recency,
		NTILE(4) OVER (order by Frequency) rfm_frequency,
		NTILE(4) OVER (order by MonetaryValue) rfm_monetary
	from rfm r
)
select 
	c.*, rfm_recency+ rfm_frequency+ rfm_monetary as rfm_cell,
	cast(rfm_recency as varchar) + cast(rfm_frequency as varchar) + cast(rfm_monetary  as varchar)rfm_cell_string
into #rfm
from rfm_calc c

select CUSTOMERNAME , rfm_recency, rfm_frequency, rfm_monetary,
	case 
		when rfm_cell_string in (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) then 'lost_customers'  --lost customers
		when rfm_cell_string in (133, 134, 143, 244, 334, 343, 344, 144) then 'slipping away, cannot lose' -- (Big spenders who haven’t purchased lately) slipping away
		when rfm_cell_string in (311, 411, 331) then 'new customers'
		when rfm_cell_string in (222, 223, 233, 322) then 'potential churners'
		when rfm_cell_string in (323, 333,321, 422, 332, 432) then 'active' --(Customers who buy often & recently, but at low price points)
		when rfm_cell_string in (433, 434, 443, 444) then 'loyal'
	end rfm_segment

from #rfm