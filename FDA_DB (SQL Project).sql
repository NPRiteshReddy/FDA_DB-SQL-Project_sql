use fda_db;

select * from product;
select * from application ;
select * from regactiondate ;
select* from appdoc ;
select * from appdoctype_lookup;
select * from chemtypelookup;
select * from doctype_lookup;
select * from product_tecode;
select * from reviewclass_lookup;

/*1. Determine the number of drugs approved each year and provide insights into the yearly
trends*/

select *
from product p inner join Application a inner join regactiondate r on p.applno = a.applno and a.applno = r.applno ;

with Approval_data as(
select p.applno , p.productno , p.drugname , d.actiondate , d.actiontype
from product p inner join regactiondate d on p.applno = d.applno where d. actiontype = 'AP'
order by d.actiondate desc  
)
select count(drugname) as 'Total_Approved_Drugs_Count', Year(actiondate )from approval_data 
group by year(actiondate) order by count(drugname)desc;                                                   /* needs to find out which table to use for approvals ?*/

with Approval_data as(
select p.applno , p.productno , p.drugname , a.actiontype
from product p inner join application a on p.applno = a.applno where  a.actiontype = 'AP'  
)
select count(z.drugname) as 'Total_approved_Drug_Count', year(d.actiondate)
from Approval_data z inner join regactiondate d on z.applno = d.applno
group by year(d.actiondate) order by count(z.drugname) desc;

create view	Approval_Year_Data as
select count(p.drugname) as 'Drug_Count' , year(r.actiondate) as 'Year'
from product p inner join Application a inner join regactiondate r on p.applno = a.applno and a.applno = r.applno
where r.actiontype = 'ap'
group by year(r.actiondate) order by count(p.drugname) desc;                                            /*<< VIEW >>*/ 

/*2. Identify the top three years that got the highest and lowest approvals, in descending and
ascending order, respectively*/

create view Highst_Approval as
select count(p.drugname) as 'Drug_Count' , year(r.actiondate) as 'Year'
from product p inner join Application a inner join regactiondate r on p.applno = a.applno and a.applno = r.applno
where r.actiontype = 'ap'
group by year(r.actiondate) order by count(p.drugname) desc
limit 3;                                                                                                /*<< VIEW >>*/ 

create view Lowest_Approval as
select count(p.drugname) as 'Drug_Count' , year(r.actiondate) as 'Year'
from product p inner join Application a inner join regactiondate r on p.applno = a.applno and a.applno = r.applno
where r.actiontype = 'ap'
group by year(r.actiondate) order by count(p.drugname) 
limit 3;                                                                                                /*<< VIEW >>*/ 

/*3. Explore approval trends over the years based on sponsors.*/

select*
from product p inner join application a on p.applno = a.applno;

select a.sponsorapplicant , count(a.actiontype)
from product p inner join application a on p.applno = a.applno
group by a.sponsorapplicant order by count(a.actiontype) desc;

with Sponsors_data as(
select p.applno , p.form , p.drugname , a.sponsorapplicant 
from product p inner join application a  on p.applno = a.applno 
)
select  s.sponsorapplicant , count(d.actiontype) as 'Total_Approvals', year(d.actiondate) as 'Year'
from sponsors_data s inner join regactiondate d on s.applno =d.applno
where not (actiontype ='TA')
group by  s.sponsorapplicant , year(d.actiondate) order by count(d.actiontype) ;                                                           /* needs date sorting ?*/

create view sponsor_Trends as
select a.sponsorapplicant , count(r.actiontype) as 'Total_Approvals', year(r.actiondate) as 'Year'
from product p inner join Application a inner join regactiondate r on p.applno = a.applno and a.applno = r.applno
where r.actiontype = 'ap' 
group by a.sponsorapplicant ,year(r.actiondate) order by count(r.actiontype) desc ;                           /*<< MAKE A VIEW >>*/ 
 
select count(distinct(a.sponsorapplicant)) , year(r.actiondate) as 'Year'
from product p inner join Application a inner join regactiondate r on p.applno = a.applno and a.applno = r.applno
where r.actiontype = 'ap' and year(r.actiondate) = 2016
group by year(r.actiondate)  ; 

select count(distinct(sponsorapplicant)) from application;

/*4. Rank sponsors based on the total number of approvals they received each year between 1939
and 1960.*/

create view sponsor_Ranking_1939_1960 as 
with Sponsors_data as(
select p.applno , p.form , p.drugname , a.sponsorapplicant 
from product p inner join application a  on p.applno = a.applno where not (actiontype ='TA')
)
select  s.sponsorapplicant ,count(d.actiontype) as 'Total_Approvals',
rank() over(order by count(d.actiontype) desc) as 'ApprovalCount_Ranking',  year(d.actiondate)
from sponsors_data s inner join regactiondate d on s.applno =d.applno
where year(d.actiondate) > 1939 and year(d.actiondate) < 1960
group by  s.sponsorapplicant , year(d.actiondate) order by count(d.actiontype) desc;                           /*<< MAKE A VIEW >>*/ 

select a.applno , a.sponsorapplicant , d.actiontype , d.actiondate
from application a inner join regactiondate d on a. applno = d. applno
where d.actiondate > '1939-01-01 00:00:00' and d.actiondate < '1960-01-01 00:00:00';           /*needs to sort actiontype*/

create view Sponsors_Count as
select count(distinct(sponsorapplicant)) as 'Toatal_Sponsors' from application;

/*1. Group products based on MarketingStatus. Provide meaningful insights into the
segmentation patterns.*/

create view MktStatus_TotalDrugs as 
select count(drugname) as 'Total_Drug_Count' ,ProductMktStatus 
from product 
group by productmktstatus order by count(drugname) desc;                                                    /*<< MAKE A VIEW >>*/ 

create view MktStatus_Form_TotalDrugs as 
select count(drugname) as 'Total_Drug_Count',form , Productmktstatus
from product 
group by form  ,Productmktstatus order by Productmktstatus desc;                                            /*<< MAKE A VIEW >>*/

select count(distinct(form)) as 'Total_Forms' from product;

/*2. Calculate the total number of applications for each MarketingStatus year-wise after the year
2010.*/

create view Totalappl_MktStatus_Yr2010 as 
with productmktstatus as(
select r.applno , p.productmktstatus 
from product p inner join Application a inner join regactiondate r on p.applno = a.applno and a.applno = r.applno
)
select count(d.applno) as 'Total_ApplnoCount', m.productmktstatus , year (d.docdate) as 'Year'
from productmktstatus m inner join appdoc d on m.applno = d.applno
where year(d.docdate) > '2010'
group by m.productmktstatus , year(d.docdate) order by year (d.docdate) ;                                      /*<< MAKE A VIEW >>*/

create view Totalappl_MktStatus as 
with productmktstatus as(
select r.applno , p.productmktstatus 
from product p inner join Application a inner join regactiondate r on p.applno = a.applno and a.applno = r.applno
)
select count(d.applno) as 'Total_ApplnoCount', m.productmktstatus , year (d.docdate) as 'Year'
from productmktstatus m inner join appdoc d on m.applno = d.applno
where year(d.docdate) > '2010'
group by m.productmktstatus , year(d.docdate) order by year (d.docdate) ;

create view Totalappl_MktStatus_Yr2010_1 as
with productmktstatus as(
select r.applno , p.productmktstatus 
from product p inner join Application a inner join regactiondate r on p.applno = a.applno and a.applno = r.applno
)
select count(d.applno) as 'Total_ApplnoCount', m.productmktstatus , year (d.docdate) as 'Year'
from productmktstatus m inner join appdoc d on m.applno = d.applno
where year(d.docdate) > '2010'and productmktstatus = '1'
group by m.productmktstatus , year(d.docdate) order by year (d.docdate) ;

create view Totalappl_MktStatus_Yr2010_2 as
with productmktstatus as(
select r.applno , p.productmktstatus 
from product p inner join Application a inner join regactiondate r on p.applno = a.applno and a.applno = r.applno
)
select count(d.applno) as 'Total_ApplnoCount', m.productmktstatus , year (d.docdate) as 'Year'
from productmktstatus m inner join appdoc d on m.applno = d.applno
where year(d.docdate) > '2010'and productmktstatus = '2'
group by m.productmktstatus , year(d.docdate) order by year (d.docdate) ;

create view Totalappl_MktStatus_Yr2010_3 as

create view Totalappl_MktStatus_Yr2010_4 as
with productmktstatus as(
select r.applno , p.productmktstatus 
from product p inner join Application a inner join regactiondate r on p.applno = a.applno and a.applno = r.applno
)
select count(d.applno) as 'Total_ApplnoCount', m.productmktstatus , year (d.docdate) as 'Year'
from productmktstatus m inner join appdoc d on m.applno = d.applno
where year(d.docdate) > '2010' and productmktstatus = '4'
group by m.productmktstatus , year(d.docdate) order by year (d.docdate) ;
                         

with yearly_marketingstatus as(
select p.applno , p.productmktstatus , a.docdate
from product p inner join appdoc a on p.ApplNo = a.ApplNo 
where docdate > '2010-01-01 00:00:00'
)
select count(applno) as 'Total_Applno_Count' , productmktstatus 
from yearly_marketingstatus
group by productmktstatus order by count(applno) desc;                                          /*year wise ? */

/*3. Identify the top MarketingStatus with the maximum number of applications and analyze its
trend over time.*/

create view Totalappl_MktStatus as 
with productmktstatus as(
select r.applno , p.productmktstatus 
from product p inner join Application a inner join regactiondate r on p.applno = a.applno and a.applno = r.applno
)
select count(d.applno) as 'Total_ApplnoCount', m.productmktstatus , year (d.docdate) as 'Year'
from productmktstatus m inner join appdoc d on m.applno = d.applno
group by m.productmktstatus , year(d.docdate) order by year (d.docdate) desc;                                    /*<< MAKE A VIEW >>*/

/*1. Categorize Products by dosage form and analyze their distribution.*/

select applno,form ,dosage, drugname , dense_rank()over(partition by drugname order by dosage desc)
from product;

with Products_dosage_form as (
select applno,form ,dosage, drugname , dense_rank()over(partition by drugname order by dosage desc)
from product
)
select count(distinct(drugname)) as 'Drug_Count',form ,dosage
from Products_dosage_form 
group by form,dosage order by count(drugname) desc;

create view Product_Distribution as
with Products_dosage_form as (
select applno,form ,dosage, drugname , dense_rank()over(partition by drugname order by dosage desc)
from product
)
select count(distinct( drugname)) as 'Drug_Count',form 
from Products_dosage_form 
group by form order by count(drugname) desc
limit 10;                                                                                                       /*<< MAKE A VIEW >>*/

/*2. Calculate the total number of approvals for each dosage form and identify the most
successful forms.*/

with Approval_From as (
select d.applno,p.form ,p.dosage, p.drugname , actiontype, dense_rank()over(partition by drugname order by dosage desc)
from product p inner join regactiondate d on p.ApplNo = d.ApplNo
where not (actiontype = 'TA')
)
select count(actiontype) as 'Approved_Count' , form , dosage , drugname
from Approval_from 
group by  form , dosage , drugname order by count(actiontype) desc;

with Approval_From as (
select d.applno,p.form ,p.dosage, p.drugname , actiontype, dense_rank()over(partition by drugname order by dosage desc)
from product p inner join regactiondate d on p.ApplNo = d.ApplNo
where not (actiontype = 'TA')
)
select count(actiontype) as 'Approved_Count' , form  , dosage 
from Approval_from 
group by  form  , dosage  order by count(actiontype) desc;

create view successful_Forms as
with Approval_From as (
select r.applno,p.form ,p.dosage, p.drugname , r.actiontype , r.actiondate
from product p inner join Application a inner join regactiondate r on p.applno = a.applno and a.applno = r.applno 
where not (r.actiontype = 'TA')
)
select count(actiontype) as 'Approval_Count' , form  , dosage 
from Approval_from 
group by  form  , dosage  order by count(actiontype) desc;                                                      /*<< MAKE A VIEW >>*/

/*3. Investigate yearly trends related to successful forms.*/ 

with Approval_From as (
select d.applno,p.form ,p.dosage, p.drugname , actiontype, dense_rank()over(partition by drugname order by dosage desc)
from product p inner join regactiondate d on p.ApplNo = d.ApplNo
where not (actiontype = 'TA')
)
select count(actiontype) as 'Approved_Count' , form ,  drugname
from Approval_from 
group by  form , drugname order by count(actiontype) desc;

with Approval_From as (
select d.applno,p.form ,p.dosage, p.drugname , actiondate, actiontype, dense_rank()over(partition by drugname order by dosage desc)
from product p inner join regactiondate d on p.ApplNo = d.ApplNo
where not (actiontype = 'TA')
)
select count(actiontype) as 'Approval_Count' , form , year( actiondate)
from Approval_from 
group by  form ,year( actiondate) order by count(actiontype)  desc;

create view Successful_Forms_Yearly as 
with Approval_From as (
select r.applno,p.form ,p.dosage, p.drugname , r.actiontype , r.actiondate
from product p inner join Application a inner join regactiondate r on p.applno = a.applno and a.applno = r.applno 
where not (r.actiontype = 'TA')
)
select count(actiontype) as 'Approval_Count' , form , year(actiondate) as 'Actiondate_Year_Wise'
from Approval_from 
group by  form  ,year(actiondate)  order by count(actiontype) desc;                                               /*<< MAKE A VIEW >>*/

/*1. Analyze drug approvals based on therapeutic evaluation code (TE_Code).*/

select count(p.drugname) as 'Total_Drug_Count' , r.actiontype , t.tecode
from product p inner join product_tecode t inner join regactiondate r on p.applno = t.applno and p.applno = r.applno
where r.actiontype = 'ap'
group by t.tecode , r.actiontype order by count(p.drugname) desc;

create view Drug_Approvals_therapeuticEvaluationcode as
select count(r.actiontype) as 'Total_Approval_count' , p.drugname , t.tecode
from product p inner join product_tecode t inner join regactiondate r on p.applno = t.applno and p.applno = r.applno
where r.actiontype = 'ap'
group by t.tecode ,  p.drugname order by count(r.actiontype) desc;

create view Drug_Approvals_therapeuticEvaluationcode_Yearly as
select count(r.actiontype) as 'Total_Approval_count' , t.tecode ,year(r.actiondate)
from product p inner join product_tecode t inner join regactiondate r on p.applno = t.applno and p.applno = r.applno
where r.actiontype = 'ap'
group by t.tecode , year(r.actiondate) order by year(r.actiondate) desc;                                        /*<< MAKE A VIEW >>*/

with Drug_approval as (
select d.applno,p.form ,p.dosage, p.drugname , actiondate, actiontype
from product p inner join regactiondate d on p.ApplNo = d.ApplNo
where not (actiontype = 'TA')
)
select count(actiontype) as 'Toatal_Approvals', drugname , tecode
from drug_approval D inner join product_tecode T on D.applno = T.applno
group by tecode , drugname  order by count(actiontype) desc;       /*Toatal_Approvals analyze based on form,drugname and TE_code*/

with Drug_approval as (
select d.applno,p.form ,p.dosage, p.drugname , actiondate, actiontype
from product p inner join regactiondate d on p.ApplNo = d.ApplNo
where not (actiontype = 'TA')
)
select count(actiontype) as 'Toatal_Approvals', tecode
from drug_approval D inner join product_tecode T on D.applno = T.applno
group by tecode   order by count(actiontype) desc;                                 /*Toatal_Approvals analyze based on TE_code*/

with Drug_approval as (
select d.applno,p.form ,p.dosage, p.drugname , actiondate, actiontype
from product p inner join regactiondate d on p.ApplNo = d.ApplNo
where not (actiontype = 'TA')
)
select count(actiontype), actiondate , tecode
from drug_approval D inner join product_tecode T on D.applno = T.applno
group by tecode , actiondate order by actiondate desc;          /*Not needed*/            /*Toatal_Approvals analyze based on actiondate and TE_code*/

select count(distinct(t.tecode)) from product p inner join product_tecode T on p.applno = T.applno;

/*2. Determine the therapeutic evaluation code (TE_Code) with the highest number of Approvals in
each year.*/

select count(r.actiontype) as 'Total_Approval_count' , t.tecode ,year(r.actiondate)
from product p inner join product_tecode t inner join regactiondate r on p.applno = t.applno and p.applno = r.applno
where r.actiontype = 'ap'
group by t.tecode , year(r.actiondate) order by year(r.actiondate) desc;

with Drug_approval as (
select d.applno,p.form ,p.dosage, p.drugname , actiondate, actiontype
from product p inner join regactiondate d on p.ApplNo = d.ApplNo
where not (actiontype = 'TA')
)
select count(actiontype), year(d.actiondate) , tecode
from drug_approval D inner join product_tecode T on D.applno = T.applno
group by tecode , year(d.actiondate) order by year(d.actiondate)  desc; 
