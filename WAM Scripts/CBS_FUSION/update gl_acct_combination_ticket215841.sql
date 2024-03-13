-- Sar 1214
update cbs_fusion.apdu_ap_inv_lines_interface t
   set t.dist_code_concatenated = '3013-2021101011-20101-9062121-0001-0000000-460042-00000-00000-0000-0000-0000'
 where t.dist_code_concatenated =
       '3013-2021101011-20101-9062121-0001-0000000-000000-00000-00000-0000-0000-0000'
   and t.invoice_id = 2302972;

update cbs_fusion.apdu_ap_inv_interface t
   set t.record_status = 'PENDING'
 where t.invoice_id = 2302972;

update cbs_wam.work_order_service_contract a
   set a.account_no = '3013.20101.9062111.0001.0000000.460042.00000.00000.0000.0000.0000'
 where a.plant = '01'
   and a.wo_number || '-' || a.wo_taskno = 'W268565-01';

commit;