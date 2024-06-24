-- with cte as( 
select contract, 
datediff('2022-09-01', max(purchase_date)) as Recency , 
sum(GMV)/timestampdiff(year, max(created_date), '2022-09-01') as Monetary ,  
count(customerid)*1.0/ timestampdiff(year, max(created_date), '2022-09-01') as 
Frequency , 
row_number() over(order by datediff('2022-09-01', max(purchase_date))) as 
rn_recency , 
row_number() over(order by sum(GMV)/timestampdiff(year, max(created_date), '2022
09-01') desc  ) as rn_monetary , 
row_number() over(order by count(customerid)*1.0/ timestampdiff(year, 
max(created_date), '2022-09-01') desc ) as rn_frequency 
from customer_registered cr  
join customer_transaction ct on cr.id = ct.customerid  
where ct.customerid <> 0 and cr.stopdate = 0 
group by contract  
order by count(customerid)*1.0/ timestampdiff(year, max(created_date), '2022-09
01') desc  
), 
customer_statistics as( 
select Contract, Recency, Frequency, Monetary , 
case when rn_recency >= (select min(rn_recency) from cte) and rn_recency < (select 
count(rn_recency)*0.25 from cte) then 4 
     when rn_recency >= (select count(rn_recency)*0.25 from cte) and rn_recency < 
(select count(rn_recency)*0.5 from cte) then 3 
     when rn_recency >= (select count(rn_recency)*0.5 from cte) and rn_recency < 
(select count(rn_recency)*0.75 from cte) then 2 
     else 1 end as R, 
case when rn_frequency >= (select min(rn_frequency) from cte) and rn_frequency < 
(select count(rn_frequency)*0.25 from cte) then 1 
     when rn_frequency >= (select count(rn_frequency)*0.25 from cte) and 
rn_frequency < (select count(rn_frequency)*0.5 from cte) then 2 
     when rn_frequency >= (select count(rn_frequency)*0.5 from cte) and 
rn_frequency < (select count(rn_frequency)*0.75 from cte) then 3 
     else 4 end as F, 
case when rn_monetary >= (select min(rn_monetary) from cte) and rn_monetary < 
(select count(rn_monetary)*0.25 from cte) then 1 
     when rn_monetary >= (select count(rn_monetary)*0.25 from cte) and rn_monetary 
< (select count(rn_monetary)*0.5 from cte) then 2 
     when rn_monetary >= (select count(rn_monetary)*0.5 from cte) and rn_monetary 
< (select count(rn_monetary)*0.75 from cte) then 3 
     else 4 end as M 
from cte 
where recency is not null 
), 
customer_RFM as ( 
select *, concat(R,F,M) as RFM 
from customer_statistics 
) 
select *,  
case   when rfm in (444, 443, 434, 344) then 'Champion' 
  when rfm in (442, 441, 432, 431, 433, 343, 342, 341) then 'Loyal Customers' 
  when rfm in (424, 423, 324, 323, 413, 414, 343, 334) then 'Potential' 
  when rfm in (333, 332, 331, 313) then 'Promising' 
  when rfm in (244, 234, 243, 233, 224, 214, 213, 134, 144, 143, 133) then 
'Need Attention' 
  when rfm in (111, 112, 113, 114, 121, 122, 123, 221, 211, 222) then 'Lost' 
  else 'Other' 
  end as Cus_type 
from customer_RFM 