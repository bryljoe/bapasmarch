select period,
       acct_id,
       acct_name,
       person_type,
       bill_cyc_cd,
       mr_rte_cd,
       address,
       bd_msgr,
       bd_seq,
       prem_id,
       parent_prem_id,
       active,
       ar_balance_amt,
       ar_avg_bill_amt,
       prompt_payor,
       eligible_for_bd_topup,
       bd_balance_amt,
       bd_refund_amt,
       bd_refund_dt,
       wo_balance_amt,
       last_applied_rev_month,
       rev_period_from,
       rev_period_to,
       sd_total_balance_amt,
       sd_total_rev_amt,
       sd_total_parent_rev_amt,
       sd_total_child_rev_amt,
       sd_total_for_bd_amt,
       sd_total_for_ar_amt,
       sd_total_for_wo_amt,
       sd_total_for_refund_amt,
       status,
       created_on,
       applied_on,
       remarks,
       apt_balance_amt,
       apwo_balance_amt,
       apar_balance_amt
  from esb.sd_refund_accts_sa@inhouseclpc.apd.com.ph sra
 where nvl(sra.sd_total_for_bd_amt, 0) > 0
   and nvl(sra.sd_total_for_wo_amt, 0) = 0
   and nvl(sra.sd_total_for_ar_amt, 0) = 0
   and (nvl(sra.sd_total_for_refund_amt, 0) > 0 or
        nvl(sra.apt_balance_amt, 0) > 0)
   and sra.active = 'Y';
