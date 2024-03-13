-- work order W164320-01
update wam_esb.tif_sa_work_order_task_copy
   set cbs_status = 'N'
 where plant = '03'
   and tif_recordid in ('17827986', '17827983', '17827883', '17757600', '17754885', '17754737');

-- work order W164320-02
update wam_esb.tif_sa_work_order_task_copy
   set cbs_status = 'N'
 where plant = '03'
   and tif_recordid in ('17827987', '17827984', '17827884', '17757603', '17754888', '17754796');

commit;