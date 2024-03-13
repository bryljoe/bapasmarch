create or replace  view collection_batches as
select batch_no,
       site_code,
       booth,
       teller,
       mode_of_entry,
       created_by,
       created_on,
       remitted_by,
       remitted_on,
       transmitted_by,
       transmitted_on,
       offline_or_date,
       or_count,
       requested_lt_min,
       granted_lt_min
  from cs.collection_batches@maliputo.aboitiz.net;
/
create or replace view crc_acct_no_mappings as
select crc,
       acct_no,
       acct_status,
       schedule,
       area_code,
       government_code,
       tin,
       cfnp_required_amt,
       last_date_paid,
       last_amount_paid,
       bd_required_amt,
       emp_acct,
       bus_add,
       bus_activity
  from cs.crc_acct_no_mappings@maliputo.aboitiz.net;
/
create or replace view fop_cash as
select tran_no, seq_no, amount_tendered
  from cs.fop_cash@maliputo.aboitiz.net;
/
create or replace view forms_of_payment as
select tran_no, seq_no, payment_type, amount_paid
  from cs.forms_of_payment@maliputo.aboitiz.net;
/
create or replace view paid_acct_facts as
select tran_no,
       acct_no,
       acct_status,
       schedule,
       area_code,
       government_code,
       tin,
       cfnp_required_amt,
       last_date_paid,
       last_amount_paid,
       apply_for_recon
  from cs.paid_acct_facts@maliputo.aboitiz.net;
/
create or replace view paid_items as
select tran_no, seq_no, pay_code, amount_credit
  from cs.paid_items@maliputo.aboitiz.net;
/
create or replace view payers as
select payer_type, payer_id, last_name, first_name, mid_name, address
  from cs.payers@maliputo.aboitiz.net;
/
create or replace view payment_transactions as
select tran_no,
       last_name,
       first_name,
       mid_name,
       address,
       or_no,
       or_date,
       or_status,
       remarks,
       bank_ref_no,
       batch_no,
       payer_id,
       payer_type,
       posted,
       cancel_reason,
       or_count
  from cs.payment_transactions@maliputo.aboitiz.net;
