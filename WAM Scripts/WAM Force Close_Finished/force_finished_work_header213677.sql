alter trigger synergen.sdbt_au_work_order disable;
alter trigger synergen.sdbt_au_work_order_stmt disable;
begin
    
  update synergen.sa_work_order
     set work_status      = 'FINISHED',
         finished_date    = sysdate,
         last_update_date = sysdate,
         actual_finish_date = sysdate
   where plant = '01'
     and work_status = 'ACTIVE'
     and work_order_no in ('W268713','W268714','W268723','W268724');
  
   commit;
  
end;
/
alter trigger synergen.sdbt_au_work_order enable;
alter trigger synergen.sdbt_au_work_order_stmt enable;








