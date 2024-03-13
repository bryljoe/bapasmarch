alter trigger synergen.cm_wo_completion_fa_upload disable;
alter trigger synergen.sdbt_ai_work_order_task disable;
alter trigger synergen.sdbt_ai_work_order_task_stmt disable;
alter trigger synergen.sdbt_au_work_order_task disable;
alter trigger synergen.sdbt_au_work_order_task_stmt disable;
alter trigger synergen.tmp_au_work_order_task_stmt disable;
alter trigger synergen.wift_invreq_wotask_interface disable;
alter trigger synergen.cm_wo_ccb_fa_char disable;
alter trigger synergen.sdbt_au_work_order disable;
alter trigger synergen.sdbt_au_work_order_stmt disable;


update sa_work_order_task
   set task_status      = 'CLOSED',
       last_update_date = sysdate,
       last_update_user = 'SDP # 214195'
 where plant = '03'
   and work_order_no = 'W139568'
   and task_status = 'FINISHED';

update sa_work_order
   set work_status      = 'CLOSED',
	   closed_date 	= sysdate,
	   closed_by	= 'SDP # 214195',
           last_update_date = sysdate,
           last_update_user = 'SDP # 214195'
 where plant = '03'
   and work_order_no = 'W139568';

commit;


alter trigger synergen.cm_wo_completion_fa_upload enable;
alter trigger synergen.sdbt_ai_work_order_task enable;
alter trigger synergen.sdbt_ai_work_order_task_stmt enable;
alter trigger synergen.sdbt_au_work_order_task enable;
alter trigger synergen.sdbt_au_work_order_task_stmt enable;
alter trigger synergen.tmp_au_work_order_task_stmt enable;
alter trigger synergen.wift_invreq_wotask_interface enable;
alter trigger synergen.cm_wo_ccb_fa_char enable;
alter trigger synergen.sdbt_au_work_order enable;
alter trigger synergen.sdbt_au_work_order_stmt enable;