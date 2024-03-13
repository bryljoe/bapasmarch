select * from sa_work_Order where work_order_no = 'W251330';
select * from sa_work_order_task where work_order_no || '-' || work_order_task_no in ('W251330-05','W251330-06','W251330-07');
select * from sa_department where plant = '01' and department = '9052161';
select * from sa_area where plant = '01' and department = '9052161' and area = '042';




update sa_work_order_task
   set area = '042', department = '9052161'
 where plant = '01'
   and area = 'ANS'
   and department = '2271'
   and work_order_no || '-' || work_order_task_no in
       ('W251330-05', 'W251330-06', 'W251330-07')

 commit;
