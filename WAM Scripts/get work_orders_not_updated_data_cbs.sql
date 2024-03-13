with wam_wo as
 (select a.tif_recordid,
         a.tif_operationtype,
         a.plant,
         a.work_order_no,
         a.work_order_task_no,
         a.task_status,
         a.cbs_status,
         a.date_inserted,
         dense_rank() over(partition by a.plant, a.work_order_no, a.work_order_task_no order by a.date_inserted desc) ranks
    from wam_esb.tif_sa_work_order_task_copy@wamprod.apd.com.ph a,
         (select distinct plant, work_order_no, work_order_task_no
            from wam_esb.tif_sa_work_order_task_copy@wamprod.apd.com.ph
           where tif_operationtype = 'U'
             and trunc(date_inserted) = to_date('02/05/2024', 'MM/DD/YYYY')) b
   where a.plant = b.plant
     and a.work_order_no = b.work_order_no
     and a.work_order_task_no = b.work_order_task_no)
select wam_wo.tif_recordid,
       wam_wo.tif_operationtype,
       wam_wo.plant,
       wam_wo.work_order_no,
       wam_wo.work_order_task_no,
       wam_wo.task_status,
       wam_wo.cbs_status,
       wam_wo.date_inserted
  from wam_wo wam_wo
 where wam_wo.ranks = 1
   and not exists
 (select 1
      from cbs_wam.wam_wo_task@vecolgcy.apd.com.ph cbs_wo
         where wam_wo.plant = cbs_wo.plant
           and wam_wo.work_order_no = cbs_wo.wam_wo_no
           and wam_wo.work_order_task_no = cbs_wo.work_order_task_no
           and wam_wo.task_status = cbs_wo.task_status);