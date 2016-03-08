-- quiz 5 q1: 
-- How many distinct skus have the brand “Polo fas”, and are either size “XXL” or “black” in color?
-- answer: 13623
select count(distinct sku)
from skuinfo
where brand = 'polo fas' and (color = 'black' or size = 'XXL');

-- quiz 5 q2:
-- There was one store in the database which had only 11 days in one of its months 
-- (in other words, that store/month/year combination only contained 11 days of transaction data). 
-- In what city and state was this store located?
-- answer: Atlanta, GA
select distinct (s.store || extract(month from saledate) || extract(year from saledate)) as comb
		,count(distinct saledate) as num
		,s.state
		,s.city
from store_msa s left join trnsact t
	on s.store = t.store
group by comb, s.state, s.city
order by num asc;

-- quiz 5 q3:
--Which sku number had the greatest increase in total sales revenue from November to December?
-- answer: 3949538
select distinct sku
			,sum(case when extract(month from saledate) =  11 then amt end) as nrev
			,sum(case when extract(month from saledate) =  12 then amt end) as drev
			,drev-nrev as incr
from trnsact 
group by sku
where stype = 'p' 
	and oreplace((extract(month from saledate) || extract(year from saledate)), ' ', '') 
		not like '%82005%'                -- examine only purchases and excludes all data from  Aug. 2005 
order by incr desc;

-- quiz 5 q4:
-- What vendor has the greatest number of distinct skus in the transaction table that do not exist in the skstinfo table? 
-- (Remember that vendors are listed as distinct numbers in our data set).
-- answer: 5715232
select count(distinct t.sku) as cnt
		,s.vendor
from skuinfo s left join trnsact t
  on s.sku = t.sku
where t.sku not in
    (select skst.sku 
     from   skstinfo)
group by s.vendor
order by cnt desc;

-- quiz 5 q5:
-- What is the brand of the sku with the greatest standard deviation in sprice? 
-- Only examine skus which have been part of over 100 transactions.
-- answer: polo fas
select brand
       ,std
from(select top 3 stddev_samp(sprice) as std
			,sku
		from trnsact
		group by sku
		having sum(quantity) > 100
		where stype = 'p' 
			and oreplace((extract(month from saledate) || extract(year from saledate)), ' ', '') 
				not like '%82005%' 
		order by std desc
	) as t
left join skuinfo s
	on s.sku = t.sku;

-- quiz5 q6:
-- What is the city and state of the store which had the greatest increase in average daily revenue
-- (as I define it in Teradata Week 5 Exercise Guide) from November to December?
-- answer: Metairie, LA, 41423.30
select city
	   ,state
	   ,dailyincr
from (
	select distinct store
			,sum(case when extract(month from saledate) =  11 then amt end) as nrev
			,sum(case when extract(month from saledate) =  12 then amt end) as drev
			,count(distinct case when extract(month from saledate) =  11 then saledate end) as novday
			,count(distinct case when extract(month from saledate) =  12 then saledate end) as decday
			,nrev/novday as ndailyrev
			,drev/decday as ddailyrev
			,(ddailyrev-ndailyrev)as dailyincr
	from trnsact 
	group by store
	where stype = 'p' 
		and oreplace((extract(month from saledate) || extract(year from saledate)), ' ', '') 
			not like '%82005%'                -- examine only purchases and excludes all data from  Aug. 2005 
	having  novday > 20 
		and decday > 20
	) as rev 
left join store_msa
	on store_msa.store = rev.store
group by city
		,state
		,dailyincr
order by dailyincr desc;

-- quiz5 q7:
-- Compare the average daily revenue of the store with the highest msa_income 
-- and the store with the lowest median msa_income (according to the msa_income field). 
-- In what city and state were these two stores, and which store had a higher average daily revenue?
-- answer: Spanish fort, AL 17884.08 (high inc)
--			    Mcallen, TX 56601.99  (low inc)

select (sum(rev)/sum(nday)) as avgrev                        -- avoid double average
        ,city
		,state
from (select top 1 city
        ,state
		,msa_income
		,store
		from store_msa
		order by msa_income desc                             -- change to `asc` to get the store w/lowest median income
		) as highinc
left join (select distinct (extract(month from saledate) || extract(year from saledate)) as my
            ,sum(amt)as rev
			,store
			,count(distinct saledate) as nday
			from trnsact 
			group by my, store
			where stype = 'p' 
				and oreplace(my, ' ', '') not like '%82005%' -- examine only purchases and excludes all data from  Aug. 2005 
			having nday > 20 				                 -- excludes all stores with less than 20 days of data
			)as rev 
on highinc.store = rev.store
group by city
         ,state;

-- quiz 5 q8:
-- Divide the msa_income groups up so that msa_incomes between 1 and 20,000 are labeled 'low', 
-- msa_incomes between 20,001 and 30,000 are labeled 'med-low', msa_incomes between 30,001 and 40,000 are labeled 'med-high',
-- and msa_incomes between 40,001 and 60,000 are labeled 'high'. Which of these groups has the highest average daily revenue per store?
-- answer: med-high, 21999.69
select case when s.msa_income >= 1 and s.msa_income <= 20000 then 'low'
            when s.msa_income >= 20001 and s.msa_income <= 30000 then 'med-low'
            when s.msa_income >= 30001 and s.msa_income <= 40000 then 'med-high'
            when s.msa_income >= 40001 and s.msa_income <= 60000 then 'high' 
       end as income_level
	   ,(sum(rev)/sum(nday)) as dailyrev
from store_msa s 
left join (
			select distinct (extract(month from saledate) || extract(year from saledate)) as my
				,sum(amt)as rev
				,store
				,count(distinct saledate) as nday
			from trnsact 
			group by my, store
			where stype = 'p' 
				and oreplace(my, ' ', '') 
					not like '%82005%'						 -- examine only purchases and excludes all data from  Aug. 2005 
			having nday > 20 				                 -- excludes all stores with less than 20 days of data
			)as rev 
  on s.store = rev.store
group by income_level
order by dailyrev desc;

-- quiz5 q9:Divide stores up so that stores with msa populations between 1 and 100,000 are labeled 'very small',
-- stores with msa populations between 100,001 and 200,000 are labeled 'small', 
-- stores with msa populations between 200,001 and 500,000 are labeled 'med_small', 
-- stores with msa populations between 500,001 and 1,000,000 are labeled 'med_large', 
-- stores with msa populations between 1,000,001 and 5,000,000 are labeled “large”, 
-- and stores with msa_population greater than 5,000,000 are labeled “very large”. 
-- What is the average daily revenue for a store in a “very large” population msa?
-- answer: very large, 25451.53
select case when s.msa_pop >= 1 and s.msa_pop <= 100000 then 'very small'
            when s.msa_pop >= 100001 and s.msa_pop <= 200000 then 'small'
            when s.msa_pop >= 200001 and s.msa_pop <= 500000 then 'med-small'
            when s.msa_pop >= 500001 and s.msa_pop <= 1000000 then 'med-large' 
            when s.msa_pop >= 1000001 and s.msa_pop <= 5000000 then 'large' 
            when s.msa_pop > 5000000 then 'very large' 
       end as pop_level
	   ,(sum(rev)/sum(nday)) as dailyrev
from store_msa s 
left join (
			select distinct (extract(month from saledate) || extract(year from saledate)) as my
				,sum(amt)as rev
				,store
				,count(distinct saledate) as nday
			from trnsact 
			group by my, store
			where stype = 'p' 
				and oreplace(my, ' ', '') 
					not like '%82005%'						 -- examine only purchases and excludes all data from  Aug. 2005 
			having nday > 20 				                 -- excludes all stores with less than 20 days of data
			)as rev 
  on s.store = rev.store
group by pop_level;


-- quiz5 q10: Which department in which store had the greatest percent increase in average daily sales revenue from November to December, 
-- and what city and state was that store located in? 
-- Only examine departments whose total sales were at least $1,000 in both November and December.
-- answer: 
select distinct st.store
	   ,st.city
	   ,st.state
	   ,d.deptdesc
	   ,perinc
from(select distinct store
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
		and sum(amt) > 1000
	)as rev
left join skuinfo s
	on s.sku = rev.sku
left join store_msa st
	on rev.store = st.store
left join deptinfo d
	on s.dept = d.dept
group by st.store
		 ,st.city
		 ,st.state
		 ,d.deptdesc
		 ,perinc
order by perinc desc;

-- quiz5 q11: Which department within a particular store had the greatest decrease in average daily sales revenue from August to September, 
-- and in what city and state was that store located?
-- Clinique, Louisville, KY, -442.94
select st.city
	  ,st.state
	  ,decr
	  ,d.deptdesc
from(select distinct store
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
	)as rev
left join store_msa st
	on rev.store = st.store
left join skuinfo s 
	on s.sku = rev.sku
left join deptinfo d
	on s.dept = d.dept
group by st.city
		 ,st.state
		 ,d.deptdesc
		 ,decr
order by decr asc;

-- quiz5 q12: Identify the department within a particular store that had the greatest decrease in number of items sold from August to September. 
-- How many fewer items did that department sell in September compared to August, and in what city and state was that store located?
-- answer:
select  ,d.deptdesc
		,s.state
		,s.city
		,decr
from (select distinct store
			,sku
			,sum(case when extract(month from saledate) =  8 then quantity end) as augquant
			,sum(case when extract(month from saledate) =  9 then quantity end) as septquant
			,count(distinct case when extract(month from saledate) =  8 then saledate end) as augday
			,count(distinct case when extract(month from saledate) =  9 then saledate end) as septday
			,septquant - augquant as decr
	from trnsact t
	group by store
			,sku
	where stype = 'p' 
		and oreplace((extract(month from saledate) || extract(year from saledate)), ' ', '') 
			not like '%82005%' 
	having   augday > 20
		and septday > 20
	) as t 
left join store_msa s
	on t.store = s.store
left join skuinfo sk
	on sk.sku = t.sku
left join deptinfo d
    on sk.dept = d.dept
group by ,d.deptdesc
		,s.state
		,s.city
		,decr
order by decr asc;
		
-- quiz5 q13: each store, determine the month with the minimum average daily revenue. 
-- For each of the twelve months of the year, count how many stores' minimum average daily revenue was in that month. 
-- During which month(s) did over 100 stores have their minimum average daily revenue?

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
from (select distinct store
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
	qualify row_num = 12								  -- limit the output of row_num (rank) to 12
	)as rev;

-- quiz5 q14:Write a query that determines the month in which each store had its maximum number of sku units returned. 
-- During which month did the greatest number of stores have their maximum number of sku units returned?
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
from (select distinct store
		    ,extract(month from saledate) as mm
		    ,count(sku) as numsku
		    ,row_number() over (partition by store order by numsku desc) as row_num
	from trnsact 
	group by mm
			,store
	where stype = 'r' 
		and oreplace((extract(month from saledate) || extract(year from saledate)), ' ', '') 
			not like '%82005%' 						  -- examine only purchases and excludes all data from  Aug. 2005 
	having count(distinct saledate) > 20			  -- excludes all stores with less than 20 days of date
	qualify row_num = 1								  -- limit the output of row_num (rank) to 1
	)as skucnt;

