update synergen.sa_work_order_task
   set account_no = '3013.20101.9052161.0001.0000000.460042.00000.00000.0000.0000'
 where plant = '01'
   and work_order_no || '-' || work_order_task_no in ('W266691-02','W268951-02');

update synergen.waif_work_order_material
   set task_account = '3013.20101.9052161.0001.0000000.460042.00000.00000.0000.0000',
       job_status = 'CREATED',
       job_message = ''
 where plant = '01'
   and work_order_no || '-' || work_order_task_no in ('W266691-02','W268951-02');
   
commit;