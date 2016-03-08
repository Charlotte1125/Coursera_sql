-- Exercise 1. How many distinct dates are there in the saledate column of the transaction
-- table for each month/year combination in the database?
-- answer: 13
select distinct (extract(year from saledate) || extract(month from saledate)) as ym
from trnsact
order by ym;    

-- Exercise 2. Use a CASE statement within an aggregate function to determine which sku
-- had the greatest total sales during the combined summer months of June, July, and August.
select distinct sku
	,sum(case when extract(month from saledate) = 6 then amt end) as jun
	,sum(case when extract(month from saledate) = 7 then amt end) as july
	,sum(case when extract(month from saledate) = 8 then amt end) as aug
	,(jun + july + aug) as total
from trnsact  
group by sku
order by total desc;

-- Exercise 3. How many distinct dates are there in the saledate column of the transaction
-- table for each month/year/store combination in the database? Sort your results by the
-- number of days per combination in ascending order.
select distinct (extract(month from saledate) || extract(year from saledate) || store) as mys
	,count(mys) as num
from trnsact 
group by mys
order by num;

-- Exercise 4. What is the average daily revenue for each store/month/year combination in
-- the database? Calculate this by dividing the total revenue for a group by the number of
-- sales days available in the transaction table for that group. 
select distinct (extract(month from saledate) || extract(year from saledate) || store) as mys
       ,(sum(amt)/count(distinct saledate)) as dailyrev
from trnsact 
group by mys
where stype = 'p' 
	and oreplace(mys, ' ', '') not like '%82005%' -- examine only purchases and excludes all data from  Aug. 2005 
having count(distinct saledate) > 20 			  -- excludes all stores with less than 20 days of data
order by dailyrev;

-- Exercise 5. What is the average daily revenue brought in by Dillard’s stores in areas of
-- high, medium, or low levels of high school education?
-- answer: low: 34159.76, medium: 25037.89, hgh: 20937.31
select case when msa_high >= 50 and msa_high <= 60 then 'low' 
            when msa_high >  60 and msa_high <= 70 then 'medium'
	        when msa_high >  70 then 'high'
	    end as edu_lvl
	   ,(sum(rev)/sum(nday)) as avgrev       -- avoid double average
from store_msa 
left join (
	select distinct (extract(month from saledate) || extract(year from saledate)) as my
		,sum(amt)as rev, store
		,count(distinct saledate) as nday
	from trnsact 
	group by my, store
	where stype = 'p' 
		and oreplace(my, ' ', '') not like '%82005%' -- examine only purchases and excludes all data from  Aug. 2005 
	having nday > 20 				     -- excludes all stores with less than 20 days of data
	)
	as rev 
on store_msa.store = rev.store
group by edu_lvl;

-- Exercise 6. Compare the average daily revenues of the stores with the highest median
-- msa_income and the lowest median msa_income. In what city and state were these stores,
-- and which store had a higher average daily revenue? 
-- answer: Spanish fort, AL 17884.08 (high inc)
--			Mcallen, TX 56601.99 (low inc)
select (sum(rev)/sum(nday)) as avgrev                        -- avoid double average
        ,city
		,state
from (
	select top 1 city
        ,state
		,msa_income
		,store
	from store_msa
	order by msa_income desc                             -- change to `ase` to get the store w/lowest median income
	)
	as highinc
left join (select distinct (extract(month from saledate) || extract(year from saledate)) as my
            ,sum(amt)as rev
			,store
			,count(distinct saledate) as nday
			from trnsact 
			group by my, store
			where stype = 'p' 
				and oreplace(my, ' ', '') not like '%82005%' -- examine only purchases and excludes all data from  Aug. 2005 
			having nday > 20 				                 -- excludes all stores with less than 20 days of data
			) as rev 
on highinc.store = rev.store
group by city
         ,state;

-- Exercise 7: What is the brand of the sku with the greatest standard deviation in sprice?
-- Only examine skus that have been part of over 100 transactions.
-- answer: cabernet, std = 178.6
select brand
       ,std
from(
	select top 3 stddev_samp(sprice) as std
			,sku
	from trnsact
	group by sku
	having sum(quantity) > 100
	where stype = 'p' 
		and oreplace((extract(month from saledate) || extract(year from saledate)), ' ', '') 
			not like '%82005%' 
	order by std desc;
	) as t
left join skuinfo s
	on s.sku = t.sku;

-- Exercise 8: Examine all the transactions for the sku with the greatest standard deviation in
-- sprice, but only consider skus that are part of more than 100 transactions.

-- get the sku number: 3733090 w/ highest std
select top 3 stddev_samp(sprice) as std
	    ,sku
from trnsact
group by sku
having sum(quantity) > 100
where stype = 'p' 
	and oreplace((extract(month from saledate) || extract(year from saledate)), ' ', '') 
		not like '%82005%' 
order by std desc;

select * 
from trnsact
where sku = '5453849';

-- Exercise 9: What was the average daily revenue Dillard’s brought in during each month of
-- the year?
-- answer:  
--	12 2004 11333356.01
--	2  2005 7363752.69
--	7  2005 7271088.69
--	4  2005 6949616.95
--	3  2005 6736315.39
--	5  2005 6666962.59
--	6  2005 6524845.42
--	11 2004 6296913.50
--	10 2004 6106357.90
--	1  2005 5836833.31
--	8  2004 5616841.37
--	9  2004 5596588.02
select distinct (extract(month from saledate) || extract(year from saledate)) as my
		,(sum(amt)/count(distinct saledate)) as dailyrev
from trnsact 
group by my
where stype = 'p' 
	and oreplace(my, ' ', '') 
		not like '%82005%' -- examine only purchases and excludes all data from  Aug. 2005 
having count(distinct saledate) > 20 -- excludes all stores with less than 20 days of data
order by dailyrev desc;

-- Exercise 10: Which department, in which city and state of what store, had the greatest %
-- increase in average daily sales revenue from November to December? 
-- answer: Clinique, Charlotte, NC, 3.31%
select st.city
	    ,st.state
		,d.deptdesc
		,perinc
from(
	select distinct store
		,sku
		,sum(case when extract(month from saledate) =  11 then amt end) as nrev
		,sum(case when extract(month from saledate) =  12 then amt end) as drev
		,count(distinct case when extract(month from saledate) =  11 then saledate end) as novday
		,count(distinct case when extract(month from saledate) =  12 then saledate end) as decday
		,nrev/novday as ndailyrev
		,drev/decday as ddailyrev
		,(ddailyrev-ndailyrev)/ndailyrev as perinc
	from trnsact 
	group by store
	         ,sku
	where stype = 'p' 
		and oreplace((extract(month from saledate) || extract(year from saledate)), ' ', '') 
			not like '%82005%'                -- examine only purchases and excludes all data from  Aug. 2005 
	having  novday > 20 
		and decday > 20                       -- excludes all stores with less than 20 days of data
	) as rev
left join skuinfo s
	on s.sku = rev.sku
left join store_msa st
	on rev.store = st.store
left join deptinfo d
	on s.dept = d.dept
group by st.city
	,st.state
	,d.deptdesc
	,perinc
order by perinc desc;

-- Exercise 11: What is the city and state of the store that had the greatest decrease in
-- average daily revenue from August to September?
-- answer: Louisville, KY, -442.94
select st.city
		,st.state
		,decr
from(
	select distinct store
			,sku
			,sum(case when extract(month from saledate) =  8 then amt end) as augrev
			,sum(case when extract(month from saledate) =  9 then amt end) as septrev
			,count(distinct case when extract(month from saledate) =  8 then saledate end) as augday
			,count(distinct case when extract(month from saledate) =  9 then saledate end) as septday
			,augrev/augday as augdailyrev
			,septrev/septday as septdailyrev
			,(septdailyrev-augdailyrev) as decr
	from trnsact 
	group by store
			,sku
	where stype = 'p' 
		and oreplace((extract(month from saledate) || extract(year from saledate)), ' ', '') 
			not like '%82005%'                -- examine only purchases and excludes all data from  Aug. 2005 
	having   augday > 20 
		and septday > 20   	  -- excludes all stores with less than 20 days of data
	) as rev
left join store_msa st
	on rev.store = st.store
group by st.city
		,st.state
		,decr
order by decr asc;

-- Exercise 12: Determine the month of maximum total revenue for each store. Count the
-- number of stores whose month of maximum total revenue was in each of the twelve
-- months. Then determine the month of maximum average daily revenue. Count the
-- number of stores whose month of maximum average daily revenue was in each of the
-- twelve months. How do they compare?

-- determine max total rev for each store and count 
-- answer: 321 in Dec.
--		   3   in Mar.
-- 		   3   in July
-- 		   1   in Sept.
select count(case when mm = 1 then mm end) as jancnt
	   ,count(case when mm = 2 then mm end) as febcnt
	   ,count(case when mm = 3 then mm end) as marcnt
	   ,count(case when mm = 4 then mm end) as aprcnt
	   ,count(case when mm = 5 then mm end) as maycnt
       ,count(case when mm = 6 then mm end) as juncnt
       ,count(case when mm = 7 then mm end) as julycnt
	   ,count(case when mm = 8 then mm end) as augcnt
	   ,count(case when mm = 9 then mm end) as septcnt
	   ,count(case when mm = 10 then mm end) as otccnt
	   ,count(case when mm = 11 then mm end) as novcnt
	   ,count(case when mm = 12 then mm end) as deccnt		
from (
	select distinct store
		   ,extract(month from saledate) as mm
		   ,sum(amt) as monthrev
		   ,row_number() over (partition by store order by monthrev desc) as row_num
	from trnsact 
	group by mm, store
	where stype = 'p' 
		and oreplace((extract(month from saledate) || extract(year from saledate)), ' ', '') 
			not like '%82005%' 						  -- examine only purchases and excludes all data from  Aug. 2005 
	having count(distinct saledate) > 20			  -- excludes all stores with less than 20 days of date
	qualify row_num = 1								  -- limit the output of row_num (rank) to 1
	) as rev;
	
-- determine max average daily rev for each store and count
-- answer: 317 in Dec.
--		   4   in Mar.
-- 		   3   in July
-- 		   2   in Feb
--         1   in Sept.
select  count(case when mm = 1 then mm end) as jancnt
	   ,count(case when mm = 2 then mm end) as febcnt
	   ,count(case when mm = 3 then mm end) as marcnt
	   ,count(case when mm = 4 then mm end) as aprcnt
	   ,count(case when mm = 5 then mm end) as maycnt
       ,count(case when mm = 6 then mm end) as juncnt
       ,count(case when mm = 7 then mm end) as julycnt
	   ,count(case when mm = 8 then mm end) as augcnt
	   ,count(case when mm = 9 then mm end) as septcnt
	   ,count(case when mm = 10 then mm end) as otccnt
	   ,count(case when mm = 11 then mm end) as novcnt
	   ,count(case when mm = 12 then mm end) as deccnt		
from (
	select distinct store
		    ,extract(month from saledate) as mm
		    ,sum(amt)/count(distinct saledate) as dailyrev
		    ,row_number() over (partition by store order by dailyrev desc) as row_num
	from trnsact 
	group by mm
			,store
	where stype = 'p' 
		and oreplace((extract(month from saledate) || extract(year from saledate)), ' ', '') 
			not like '%82005%' 						  -- examine only purchases and excludes all data from  Aug. 2005 
	having count(distinct saledate) > 20			  -- excludes all stores with less than 20 days of date
	qualify row_num = 1								  -- limit the output of row_num (rank) to 1
	)as rev;
