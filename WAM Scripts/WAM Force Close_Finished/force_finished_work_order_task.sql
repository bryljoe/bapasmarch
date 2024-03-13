--alter trigger synergen.cm_wo_completion_fa_upload disable;
alter trigger synergen.sdbt_ai_work_order_task disable;
alter trigger synergen.sdbt_ai_work_order_task_stmt disable;
alter trigger synergen.sdbt_au_work_order_task disable;
alter trigger synergen.sdbt_au_work_order_task_stmt disable;
alter trigger synergen.tmp_au_work_order_task_stmt disable;
alter trigger synergen.wift_invreq_wotask_interface disable;
--alter trigger synergen.cm_wo_ccb_fa_char disable;
--alter trigger synergen.sdbt_au_work_order disable;
--alter trigger synergen.sdbt_au_work_order_stmt disable;

begin

  update synergen.sa_work_order_task
     set task_status      = 'FINISHED',
         finished_date    = sysdate
   where plant = '03'
     and task_status = 'ACTIVE'
     and work_order_no || '-' || work_order_task_no in
         ('W096054-02', 'W096054-03');
  
end;
/
--alter trigger synergen.cm_wo_completion_fa_upload disable;
alter trigger synergen.sdbt_ai_work_order_task disable;
alter trigger synergen.sdbt_ai_work_order_task_stmt disable;
alter trigger synergen.sdbt_au_work_order_task disable;
alter trigger synergen.sdbt_au_work_order_task_stmt disable;
alter trigger synergen.tmp_au_work_order_task_stmt disable;
alter trigger synergen.wift_invreq_wotask_interface disable;
--alter trigger synergen.cm_wo_ccb_fa_char disable;
--alter trigger synergen.sdbt_au_work_order disable;
--alter trigger synergen.sdbt_au_work_order_stmt disable;