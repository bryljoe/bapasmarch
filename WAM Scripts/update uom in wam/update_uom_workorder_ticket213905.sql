update synergen.waif_work_order_material
   set job_status = 'CREATED', 
       job_message = '',
       unit_of_issue = 'm'
 where work_order_no || '-' || work_order_task_no = 'W268102-02'
   and plant = '01';

update synergen.sa_work_order_task_cu_items
   set unit_of_measure = 'm'
 where plant = '01'
   and work_order_no = 'W268102'
   and work_order_task_no = '02'
   and item_id = '0166293';

update synergen.sa_work_order_material
   set unit_of_issue = 'm'
 where plant = '01'
   and work_order_no = 'W268102'
   and work_order_task_no = '02'
   and stock_code = '0166293';

update synergen.sa_catalog
   set unit_of_issue = 'm', 
       unit_of_purchase = 'm'
 where plant = '01'
   and stock_code = '0166293';

commit;