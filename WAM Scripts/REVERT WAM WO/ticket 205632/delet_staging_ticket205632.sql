delete synergen.waif_work_order_material
 where work_order_no || '-' || work_order_task_no = 'W140847-01'
   and plant = '03';
   
commit;