alter trigger synergen.cm_wo_completion_fa_upload disable;
alter trigger synergen.cm_wo_ccb_fa_char disable;
alter trigger synergen.sdbt_au_work_order disable;
alter trigger synergen.sdbt_au_work_order_stmt disable;
begin
    
  update synergen.sa_work_order
     set work_status      = 'FINISHED',
         finished_date    = sysdate,
         last_update_date = sysdate
   where plant = '03'
     and work_status = 'ACTIVE'
     and work_order_no = 'W096054';
  
   commit;
  
end;
/
alter trigger synergen.cm_wo_completion_fa_upload enable;
alter trigger synergen.cm_wo_ccb_fa_char enable;
alter trigger synergen.sdbt_au_work_order enable;
alter trigger synergen.sdbt_au_work_order_stmt enable;