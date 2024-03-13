alter trigger synergen.sdbt_ai_work_order_task disable;
alter trigger synergen.sdbt_ai_work_order_task_stmt disable;
alter trigger synergen.sdbt_au_work_order_task disable;
alter trigger synergen.sdbt_au_work_order_task_stmt disable;
alter trigger synergen.tmp_au_work_order_task_stmt disable;
alter trigger synergen.wift_invreq_wotask_interface disable;

update synergen.sa_work_order_task
   set task_status      = 'ACTIVE',
       last_update_date = sysdate,
       last_update_user = 'SDP # 216867'
 where plant = '01'
   and work_order_no || '-' || work_order_task_no = 'W249976-01';

commit;

alter trigger synergen.sdbt_ai_work_order_task enable;
alter trigger synergen.sdbt_ai_work_order_task_stmt enable;
alter trigger synergen.sdbt_au_work_order_task enable;
alter trigger synergen.sdbt_au_work_order_task_stmt enable;
alter trigger synergen.tmp_au_work_order_task_stmt enable;
alter trigger synergen.wift_invreq_wotask_interface enable;

