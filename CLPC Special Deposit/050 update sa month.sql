update balance_sas a
   set sa_month =
       (select to_char(trunc(to_date(start_dt, 'MM/DD/YYYY'), 'MM'), 'MM')
          from ci_sa
         where sa_id = a.sa_id);


update deposit_sas a
   set sa_month =
       (select to_char(trunc(to_date(start_dt, 'MM/DD/YYYY'), 'MM'), 'MM')
          from ci_sa
         where sa_id = a.sa_id);

commit;