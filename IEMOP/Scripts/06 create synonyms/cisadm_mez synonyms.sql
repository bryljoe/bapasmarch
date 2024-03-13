-- Create the synonym 
create or replace synonym collection_batches_mez
  for cisadm_mez.collection_batches;
  
create or replace synonym paid_items_mez
  for cisadm_mez.paid_items;

create or replace synonym payment_transactions_mez
  for cisadm_mez.payment_transactions;
  
create or replace synonym paid_acct_facts_mez
  for cisadm_mez.paid_acct_facts;
  
create or replace synonym forms_of_payment_mez
  for cisadm_mez.forms_of_payment;
  
create or replace synonym fop_cash_mez
  for cisadm_mez.fop_cash;
  
create or replace synonym payers_mez
  for cisadm_mez.payers;
  
create or replace synonym crc_acct_no_mappings_mez
  for cisadm_mez.crc_acct_no_mappings;

create or replace synonym batch_numbers_mez
  for cisadm_mez.batch_numbers_mez;
  
create or replace synonym tran_numbers_mez
  for cisadm_mez.tran_numbers_mez;