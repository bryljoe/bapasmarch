select tif_recordid,
       tif_operationtype,
       plant,
       work_order_no || '-' || work_order_task_no || '-' || plant,
       cbs_status
  from wam_esb.tif_sa_work_order_task_copy@wamprod.apd.com.ph wam
 where tif_operationtype = 'I'
   and trunc(date_inserted) = to_Date('02/05/2024', 'MM/DD/YYYY')
   and not exists
 (select 1
          from cbs_wam.wam_wo_task@vecolgcy.apd.com.ph cbs
         where wam.plant = cbs.plant
           and wam.work_order_no = cbs.wam_wo_no
           and wam.work_order_task_no = cbs.work_order_task_no);