update synergen.sa_work_order
   set work_status = 'FINISHED'
 where plant = '03'
   and work_order_no = 'W149732';

commit;