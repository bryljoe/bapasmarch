update synergen.sa_work_order_material
   set stock_code = '0063692'
 where work_order_no || '-' || work_order_task_no = 'W159736-01'
   and stock_code = '0063682'
   and plant = '03';

update synergen.waif_work_order_material
   set stock_code = '0063692'
 where work_order_no || '-' || work_order_task_no = 'W159736-01'
   and stock_code = '0063682'
   and plant = '03';

update synergen.waif_work_order_material
   set job_status = 'CREATED', 
       job_message = ''
 where work_order_no || '-' || work_order_task_no = 'W159736-01'
   and plant = '03';

commit;