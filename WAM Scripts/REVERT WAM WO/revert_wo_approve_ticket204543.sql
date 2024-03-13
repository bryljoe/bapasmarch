update synergen.sa_work_order_task
   set task_status = 'APPROVED'
 where work_order_no || '-' || work_order_task_no in
       ('W120980-01',
        'W123449-01',
        'W123348-02',
        'W122464-03',
        'W145800-03')
   and plant = '03';

update synergen.sa_work_order_material
   set sent_to_ebs_ind = NULL
 where work_order_no || '-' || work_order_task_no in
       ('W120980-01',
        'W123449-01',
        'W123348-02',
        'W122464-03',
        'W145800-03')
   and plant = '03';

commit;


alter trigger synergen.cm_wo_completion_fa_upload disable;

update synergen.sa_work_order
   set work_status      = 'APPROVED',
       closed_date      = null,
       last_update_user = 'SDP 204543',
       last_update_date = sysdate
 where plant = '03'
   and work_order_no in
       ('W120980', 'W123449', 'W123348', 'W122464', 'W145800');

commit;

alter trigger synergen.cm_wo_completion_fa_upload enable;