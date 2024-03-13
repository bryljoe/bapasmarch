select plant,
       work_order_no,
       work_order_task_no,
       item_sequence_no,
       unit_of_issue,
       item_desc,
       revised_estimate_quantity,
       original_estimate_quantity,
       actual_quantity,
       stock_code,
       expense_code,
       created_date,
       created_by,
       task_account,
       source_system,
       job_status,
       job_message
  from synergen.waif_work_order_material a
 where a.plant = '03'
   and a.work_order_no = 'W159736'
   and a.work_order_task_no = '01'
   and not exists (select 1
          from synergen.waif_work_order_material b
         where b.plant = a.plant
           and b.stock_code = a.stock_code
           and b.job_status = 'SUCCESS');