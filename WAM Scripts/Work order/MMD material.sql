update Sa_Work_Order_Material
   set sent_to_ebs_ind = 'N'
 where plant = '02'
   and work_order_no || '-' || work_order_task_no in
       ('W004964-01',
        'W004964-02',
        'W004964-03',
        'W004964-04');
commit;
/
alter trigger synergen.cm_wo_completion_fa_upload disable;

update sa_work_order_task
   set task_status      = 'PLANNING',
       last_update_date = sysdate,
       last_update_user = 'SDP # 203249'
 where plant = '02'
   and work_order_no || '-' || work_order_task_no in
       ('W004964-01', 'W004964-02', 'W004964-03', 'W004964-04');

update sa_work_order_task
   set task_status      = 'ACTIVE',
       last_update_date = sysdate,
       last_update_user = 'SDP # 203249'
 where plant = '02'
   and work_order_no || '-' || work_order_task_no in
       ('W004964-01', 'W004964-02', 'W004964-03', 'W004964-04');

update sa_work_order
   set work_status      = 'PLANNING',
       last_update_user = 'SDP # 203249',
       last_update_date = sysdate
 where plant = '02'
   and work_order_no = 'W004964';

commit;


alter trigger synergen.cm_wo_completion_fa_upload enable;


   