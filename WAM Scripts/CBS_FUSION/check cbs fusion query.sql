select t.*, t.rowid from cbs_wam.apdu_ap_inv_interface t where invoice_num = 'A000222' order by t.record_date desc;
select t.*, t.rowid from apdu_ap_inv_lines_interface t where t.invoice_id in ('A000222');


cbs_wam.apdu_ap_inv_interface

select t.*, rowid
  from cbs_wam.apdu_ap_inv_interface t
 order by t.record_date desc;

select *
  from apdu_ap_inv_interface t
 where t.record_status = 'FAILED'
 order by t.record_date desc;

select *
  from apdu_ap_inv_interface t
 where t.record_status = 'PENDING'
 order by t.record_date desc;


select t.*,
       t.rowid
  from apdu_ap_inv_lines_interface t
 where t.invoice_id in (2300068)
 and t.description in ('W146731-01','W147037-01','W146436-01');


select distinct t.description,
                t.dist_code_concatenated
  from apdu_ap_inv_lines_interface t
 where t.invoice_id in (2300068);


select t.dist_code_concatenated,
       count(1)
  from apdu_ap_inv_lines_interface t
 where t.invoice_id = 2302385
 group by t.dist_code_concatenated;

select t.invoice_id,
       t.invoice_line_id,
       t.dist_code_concatenated,
       t.record_status,
       t.record_date,
       t.record_msg
  from apdu_ap_inv_lines_interface t
 where t.dist_code_concatenated =
       '3013-2021101011-20101-9062121-0001-0000000-000000-00000-00000-0000-0000-0000'
   and t.invoice_id <> 2302447
 order by t.record_date desc


EMERGENCY LINE WORKS = segment7 460058

3013-2030100020-20101-9062111-0001-0000000-460036-00000-00000-0000-0000-0000   Wrong expense

3013-2021101011-20101-9062111-0001-0000000-460036-00000-00000-0000-0000-0000  Correct expense


UPDATE cbs_wam.work_order_service_contract t
   SET expense_code = '2021101011'
 WHERE wo_number = 'W146436'
   AND wo_taskno in ('01')
   and plant = '03';



update apdu_ap_inv_interface t
   set t.record_status = 'PENDING'
 where t.invoice_id = 2300048;

update apdu_ap_inv_lines_interface t
   set t.record_status = 'PENDING'
 where t.invoice_id = 2300048;

select a.*,
       rowid
  from cbs_wam.sar_invoice a
 where a.plant = '01'
   and a.sar_number = '307'
   and a.contractor_code = 406;


select t.invoice_id,
       t.invoice_num,
       t.description,
       t.record_status,
       t.record_msg,
       t.supplier_name,
       t.business_unit_name,
       rowid
  from apdu_ap_inv_interface t
 where t.invoice_num like '%1065%'

select *
  from cbs_wam.erp_mapping_po_vendors a
 where a.plant = '01'
and a.cbs_meaning like '%CARME%';


select *
  from cbs_wam.wam_wo_task a
 where a.dept = 144
   and a.crew = 'AESSL'
   and a.default_expense_code = '2021101011'
   and a.plant = '01'
   and exists
 (select 1
          from apdu_ap_inv_lines_interface b
         where b.dist_code_concatenated like '3013-%'
           and b.description = a.wam_wo_no || '-' || a.work_order_task_no
           and b.record_status = 'SUCCESS')
 order by a.creation_date desc





="UPDATE cbs_wam.work_order_service_contract t SET expense_code='"& M2 &"',account_no='"& T2 & ".0000' WHERE wo_number='"& B2 &"' AND wo_taskno = '"& C2 &"' and plant = '"& A2 &"';"


select work_order_no,
       work_order_task_no,
       bt.request_number,
       replace(gl, '.', '-') gl,
       sum(bt.amount) amount
  from (select bt.plant,
               rd.request_number,
               bt.bill_tag_amount amount,
               dc.wo_number work_order_no,
               dc.direct_charge work_order_task_no,
               (substr(account_no, 1, 5) || expense_code ||
               substr(account_no, 5)) gl
          from cbs_wam.billing_tags                bt,
               cbs_wam.request_details             rd,
               cbs_wam.work_order_service_contract dc
         where bt.plant = rd.plant
           and bt.plant = dc.plant
           and bt.wo_number = rd.wo_number
           and bt.wo_taskno = rd.wo_taskno
           and bt.wo_number = substr(dc.wo_number, 2)
           and bt.wo_taskno = dc.wo_taskno
           and bt.bill_tag_number = rd.bill_tag_number) bt,
       cbs_wam.billings bill,
       cbs_wam.gang_groups_lib ggl
 where bt.plant = bill.plant
   and bill.plant = ggl.plant
   and bt.request_number = bill.request_number
   and bill.contractor_code = ggl.code
   and bill.sar_number = 1065
   and bill.contractor_code = 417
   and bt.plant = '01'
 group by work_order_no,
          work_order_task_no,
          bt.request_number,
          gl;

