delete from synergen.waif_agila_additional_items
 where work_order_no = 'W262347'
   and task_no = '02'
   and plant = '01';
 
delete from synergen.waif_agila_posting_wam_designs a
  where work_order_no = 'W262347'
    and plant = '01'
    and task_no = '02';


commit;