delete from synergen.waif_agila_additional_items
 where work_order_no = 'W007626'
   and task_no = '02'
   and plant = '02';
 
delete from synergen.waif_agila_posting_wam_designs a
  where work_order_no = 'W007626'
    and plant = '02'
    and task_no = '02';


commit;