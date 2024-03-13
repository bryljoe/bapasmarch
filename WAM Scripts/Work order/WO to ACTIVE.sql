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
   set task_status      = 'FINISHED',
       last_update_date = sysdate,
       last_update_user = 'SDP # 203249'
 where plant = '02'
   and task_status = 'CLOSED'
   and work_order_no || '-' || work_order_task_no in
       ('W002699-01',
        'W002699-02',
        'W002699-03',
        'W002699-04',
        'W002699-05',
        'W005216-01',
        'W004989-01',
        'W005484-01',
        'W005123-01',
        'W005685-01');

update sa_work_order
   set work_status      = 'ACTIVE',
       last_update_user = 'SDP # 203249',
       last_update_date = sysdate
 where plant = '02'
   and work_status = 'CLOSED'
   and work_order_no in ('W002699','W005216','W004989','W005484','W005123','W005685');

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