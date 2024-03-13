--check Wo staging Status:
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
   and a.work_order_task_no = '01';

--Check which material has not yet successfully interfaced to fusion.
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

--Check material in fusion if item type is not purchase.

--https://fa-evjn-saasfaprod1.fa.ocs.oraclecloud.com/fscmRestApi/resources/latest/itemsV2?q=OrganizationId="300000004152039";ItemNumber="0063682"&limit=1000;

--Check if naay Expance and Account wala pa na successfully interfaced to fusion.
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
           and b.expense_code = a.expense_code
           and b.task_account = a.task_account
           and b.job_status = 'SUCCESS');