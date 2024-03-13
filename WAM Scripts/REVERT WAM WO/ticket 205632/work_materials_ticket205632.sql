update synergen.sa_work_order_material
   set sent_to_ebs_ind = null
 where plant = '03'
 and work_order_no || '-' || work_order_task_no in
       ('W143876-05',
        'W139481-01',
        'W141109-02',
        'W145445-01',
        'W143673-02',
        'W140847-01');
        
 
update synergen.sa_work_order_material
   set item_status = 'CREATED'
 where plant = '03'
 and work_order_no || '-' || work_order_task_no in
       ('W143876-05',
        'W139481-01',
        'W141109-02',
        'W145445-01',
        'W143673-02',
        'W140847-01');
        
update synergen.sa_work_order_material
   set item_status = 'ACTIVE'
 where plant = '03'
 and work_order_no || '-' || work_order_task_no in
       ('W143876-05',
        'W139481-01',
        'W141109-02',
        'W145445-01',
        'W143673-02',
        'W140847-01');


commit;
