--> login to outage/outage in uat_outage--legacy_veco

--> delete data first in temporary table
delete outage.temp_table;

--> insert data base on the excel sheet provided by requestor
insert into temp_table (account_no) values ('2285905489');

--> check and count if there is data after insert in temp table
select count(*) from temp_table;
select * from temp_table;

--> update all accounts to 10 digit
update outage.temp_table t
   set t.account_no = lpad(t.account_no, 10, 0);
   
--> check if there is duplicate data, if duplicate found delete the duplicate account
select account_no
from outage.temp_table
group by account_no
having count(account_no) > 1;

select a.*, rowid
from outage.temp_table a
where account_no in ('4998530000', '0265199851');
 
delete from outage.temp_table
 where rowid not in
       (select min(rowid) from outage.temp_table group by account_no);
  
--> check affected customers first and backup data if naay data
 select * from outage.affected_customers a
 where a.outage_id = '18226';
 
--> if done backup data delete first this table kay mao ni ato insertan puhon        
delete from outage.affected_customers a
 where a.outage_id = '18226';
 
--> check if data is existing in outage.affected_customers
 select t.account_no
   from outage.temp_table t
  where exists (select 1
           from outage.affected_customers a
          where a.outage_id = '18226'
            and a.account_no = t.account_no);
           

--> insert the data from temp table to outage.affected_customers
insert into outage.affected_customers
  (outage_id,
   account_no)
  select 18226 outage_id,
         t.account_no
    from temp_table t
   where not exists (select 1
            from outage.affected_customers a
           where a.outage_id = 18226
             and a.account_no = t.account_no);

--> check if data was sucessfully inserted
select *
  from outage.affected_customers a
 where a.outage_id = 18226;


--> after check, export the result to sql then create insert statement. exxample script below
delete from outage.affected_customers a where a.outage_id = 18226;

insert into outage.affected_customers (outage_id,account_no,kwhr,kw,lcno,poleno) values (18226,'8284920000',null,null,null,null);

commit;

--> done

