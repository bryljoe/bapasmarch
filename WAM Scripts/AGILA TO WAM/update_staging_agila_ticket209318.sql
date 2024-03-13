
update agila.wo_staging_designs a
   set status = 'PRE-APPROVED',
       interface_status = '',
       date_posted = ''
 where work_order_no = 'W007626'
   and work_order_task_no = '02'
   and plant = '02';

update agila.additional_items a
   set status = 'PRE-APPROVED',
       interface_status = '',
       date_posted = ''
 where work_order_no = 'W007626'
   and task_no = '02'
   and plant = '02';


commit;