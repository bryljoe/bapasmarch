update synergen.sa_work_history_task
   set task_status      = 'CLOSED',
       last_update_date = sysdate,
       last_update_user = 'SDP # 216330 and 216165'
 where plant = '01'
   and work_order_no || '-' || work_order_task_no in ('W174170-01', 'W171038-01','W184816-01', 'W186426-01');

update synergen.sa_work_history
   set work_status      = 'HISTORY',
       last_update_date = sysdate,
       last_update_user = 'SDP # 216330 and 216165'
 where plant = '01'
   and work_order_no in ('W174170','W171038','W184816','W186426');

commit;