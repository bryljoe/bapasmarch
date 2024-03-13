update wam_esb.tif_sa_work_order_task_copy
   set cbs_status = 'N'
 where plant = '03'
   and tif_recordid in ('17754890','17754918');

commit;