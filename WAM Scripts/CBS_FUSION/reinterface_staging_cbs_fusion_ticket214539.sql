 update cbs_wam.apdu_ap_inv_interface
    set record_status = 'PENDING'
  where invoice_id in ('2302728','2302729','2302730');
 
 commit;
