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

begin

  for x in (select distinct temp.plant,
                            temp.work_order_no,
                            swo.work_status
              from wam_esb.temp_sa_work_order temp,
                   synergen.sa_work_order     swo
             where temp.work_order_no = swo.work_order_no
               and temp.plant = swo.plant
               and temp.plant = '03'
               and temp.status = 'P'
               and swo.work_status not in ('CLOSED', 'CANCELED'))
 
   loop
    if x.work_status in
       ('ACTIVE', 'PLANNING', 'APPROVED', 'PENDING APPROVAL') then
   
      update synergen.sa_work_order_task
         set task_status      = 'FINISHED',
             finished_date    = sysdate,
             finished_by      = 'SDP # 156478',
             last_update_date = sysdate,
             last_update_user = 'SDP # 156478'
       where plant = x.plant
         and task_status not in ('CANCELED', 'FINISHED', 'REJECTED')
         and work_order_no = x.work_order_no;
   
      update synergen.sa_work_order
         set work_status      = 'FINISHED',
             finished_date    = sysdate,
             finished_by      = 'SDP # 156478',
             last_update_user = 'SDP # 156478',
             last_update_date = sysdate
       where plant = x.plant
         and work_status != 'FINISHED'
         and work_order_no = x.work_order_no;
   
      update synergen.sa_work_order_task
         set task_status      = 'CLOSED',
             last_update_date = sysdate,
             last_update_user = 'SDP # 156478'
       where plant = x.plant
         and task_status not in ('CANCELED', 'REJECTED', 'CLOSED')
         and work_order_no = x.work_order_no;
   
      update synergen.sa_work_order
         set work_status      = 'CLOSED',
             closed_date      = sysdate,
             closed_by        = 'SDP # 156478',
             last_update_user = 'SDP # 156478',
             last_update_date = sysdate
       where plant = x.plant
         and work_status != 'CLOSED'
         and work_order_no = x.work_order_no;
   
    elsif x.work_status in ('FINISHED') then
   
      update synergen.sa_work_order_task
         set task_status      = 'CLOSED',
             last_update_date = sysdate,
             last_update_user = 'SDP # 156478'
       where plant = x.plant
         and task_status not in ('CANCELED', 'REJECTED', 'CLOSED')
         and work_order_no = x.work_order_no;
   
      update synergen.sa_work_order
         set work_status      = 'CLOSED',
             closed_date      = sysdate,
             closed_by        = 'SDP # 156478',
             last_update_user = 'SDP # 156478',
             last_update_date = sysdate
       where plant = x.plant
         and work_status != 'CLOSED'
         and work_order_no = x.work_order_no;
   
    end if;
 
    update wam_esb.temp_sa_work_order
       set status = 'C', last_update_date = sysdate
     where rowid = x.rowid;
  end loop;

  commit;

end;
/
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