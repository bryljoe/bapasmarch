-- Create the synonym 
create or replace synonym collection_batches_bez
  for cisadm_bez.collection_batches;
  
create or replace synonym paid_items_bez
  for cisadm_bez.paid_items;

create or replace synonym payment_transactions_bez
  for cisadm_bez.payment_transactions;
  
create or replace synonym paid_acct_facts_bez
  for cisadm_bez.paid_acct_facts;
  
create or replace synonym forms_of_payment_bez
  for cisadm_bez.forms_of_payment;
  
create or replace synonym fop_cash_bez
  for cisadm_bez.fop_cash;
  
create or replace synonym payers_bez
  for cisadm_bez.payers;
  
create or replace synonym crc_acct_no_mappings_bez
  for cisadm_bez.crc_acct_no_mappings;

create or replace synonym batch_numbers_bez
  for cisadm_bez.batch_numbers_bez;
  
create or replace synonym tran_numbers_bez
  for cisadm_bez.tran_numbers_bez;

create or replace synonym get_or_no_bez
  for cisadm_bez.get_or_no_bez;