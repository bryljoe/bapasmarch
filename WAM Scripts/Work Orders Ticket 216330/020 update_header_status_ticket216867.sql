alter trigger synergen.cm_wo_ccb_fa_char disable;
alter trigger synergen.sdbt_au_work_order disable;
alter trigger synergen.sdbt_au_work_order_stmt disable;

update synergen.sa_work_order
   set work_status      = 'FINISHED',
       last_update_date = sysdate,
       last_update_user = 'SDP # 216867',
       finished_date    = sysdate,
       finished_by      = 'SDP # 216867'
 where plant = '01'
   and work_order_no = 'W198058';

commit;

alter trigger synergen.cm_wo_ccb_fa_char disable;
alter trigger synergen.sdbt_au_work_order disable;
alter trigger synergen.sdbt_au_work_order_stmt disable;

