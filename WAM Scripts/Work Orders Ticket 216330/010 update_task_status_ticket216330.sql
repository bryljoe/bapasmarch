alter trigger synergen.sdbt_ai_work_order_task disable;
alter trigger synergen.sdbt_ai_work_order_task_stmt disable;
alter trigger synergen.sdbt_au_work_order_task disable;
alter trigger synergen.sdbt_au_work_order_task_stmt disable;
alter trigger synergen.tmp_au_work_order_task_stmt disable;
alter trigger synergen.wift_invreq_wotask_interface disable;


update sa_work_order_task
   set task_status      = 'FINISHED',
       last_update_date = sysdate,
       last_update_user = 'SDP # 216330',
       finished_date 	= sysdate,
       finished_by 		= 'SDP # 216330'
 where plant = '01'
   and work_order_no || '-' || work_order_task_no in ('W248996-01','W248931-01','W244984-01','W254121-01','W254121-02');
  

alter trigger synergen.sdbt_ai_work_order_task enable;
alter trigger synergen.sdbt_ai_work_order_task_stmt enable;
alter trigger synergen.sdbt_au_work_order_task enable;
alter trigger synergen.sdbt_au_work_order_task_stmt enable;
alter trigger synergen.tmp_au_work_order_task_stmt enable;
alter trigger synergen.wift_invreq_wotask_interface enable;