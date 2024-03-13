-- update work order task to approved
update synergen.sa_work_order_task
   set task_status = 'APPROVED'
 where work_order_no || '-' || work_order_task_no in
       ('W143876-05',
        'W139481-01',
        'W141109-02',
        'W145445-01',
        'W143673-02',
        'W140847-01')
   and plant = '03';

-- update work order task to planning
update synergen.sa_work_order_task
   set task_status = 'PLANNING'
 where work_order_no || '-' || work_order_task_no = 'W139472-01'
   and plant = '03';

-- update expense code
update synergen.sa_work_order_material
   set sent_to_ebs_ind = NULL, expense_code = '2021101011'
 where work_order_no || '-' || work_order_task_no in
       ('W121719-06', 'W089412-07')
   and plant = '03';

update synergen.sa_work_order_task_cu_items
   set expense_code = '2021101011'
 where work_order_no || '-' || work_order_task_no in
       ('W121719-06', 'W089412-07')
   and item_type = 'M'
   and plant = '03';

update synergen.waif_work_order_material
   set expense_code = '2021101011', job_status = 'CREATED'
 where work_order_no || '-' || work_order_task_no in
       ('W121719-06', 'W089412-07')
   and plant = '03';

commit;

alter trigger synergen.cm_wo_completion_fa_upload disable;

update synergen.sa_work_order
   set work_status      = 'APPROVED',
       closed_date      = null,
       last_update_user = 'SDP 205632',
       last_update_date = sysdate
 where plant = '03'
   and work_order_no in ('W143673', 'W140847');

update synergen.sa_work_order
   set work_status      = 'PLANNING',
       closed_date      = null,
       last_update_user = 'SDP 205632',
       last_update_date = sysdate
 where plant = '03'
   and work_order_no = 'W139472';

commit;

alter trigger synergen.cm_wo_completion_fa_upload enable;
