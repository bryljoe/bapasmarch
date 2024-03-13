alter trigger synergen.cm_wo_ccb_fa_char disable;
alter trigger synergen.sdbt_au_work_order disable;
alter trigger synergen.sdbt_au_work_order_stmt disable;

update sa_work_order
   set work_status      = 'FINISHED',
       last_update_date = sysdate,
       last_update_user = 'SDP # 216330',
       finished_date    = sysdate,
       finished_by      = 'SDP # 216330'
 where plant = '01'
   and work_order_no in ('W248996', 'W248931', 'W244984', 'W254121');

commit;

alter trigger synergen.cm_wo_ccb_fa_char disable;
alter trigger synergen.sdbt_au_work_order disable;
alter trigger synergen.sdbt_au_work_order_stmt disable;