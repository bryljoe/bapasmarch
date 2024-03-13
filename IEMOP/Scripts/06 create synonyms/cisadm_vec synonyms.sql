-- Create the synonym 
create or replace synonym collection_batches_vec
  for cisadm_vec.collection_batches;
  
create or replace synonym paid_items_vec
  for cisadm_vec.paid_items;

create or replace synonym payment_transactions_vec
  for cisadm_vec.payment_transactions;
  
create or replace synonym paid_acct_facts_vec
  for cisadm_vec.paid_acct_facts;
  
create or replace synonym forms_of_payment_vec
  for cisadm_vec.forms_of_payment;
  
create or replace synonym fop_cash_vec
  for cisadm_vec.fop_cash;
  
create or replace synonym payers_vec
  for cisadm_vec.payers;
  
create or replace synonym crc_acct_no_mappings_vec
  for cisadm_vec.crc_acct_no_mappings;

create or replace synonym batch_numbers_vec
  for cisadm_vec.batch_numbers_vec;
  
create or replace synonym tran_numbers_vec
  for cisadm_vec.tran_numbers_vec;