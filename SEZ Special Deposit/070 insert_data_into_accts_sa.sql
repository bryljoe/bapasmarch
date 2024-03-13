insert into sd_refund_accts_sa
  (period,
   acct_id,
   sa_month,
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
   remarks)
  select period,
         acct_id,
         (select to_char(max(srs.sd_sa_start_dt), 'MM') sa_month
            from esb.sd_refund_sa srs
           where sra.period = srs.period
             and sra.acct_id = srs.acct_id) sa_month,
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
         remarks
    from esb.sd_refund_accts sra;

commit;