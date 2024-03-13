-- Create the synonym 
create or replace synonym collection_batches_lez
  for cisadm_lez.collection_batches;
  
create or replace synonym paid_items_lez
  for cisadm_lez.paid_items;

create or replace synonym payment_transactions_lez
  for cisadm_lez.payment_transactions;
  
create or replace synonym paid_acct_facts_lez
  for cisadm_lez.paid_acct_facts;
  
create or replace synonym forms_of_payment_lez
  for cisadm_lez.forms_of_payment;
  
create or replace synonym fop_cash_lez
  for cisadm_lez.fop_cash;
  
create or replace synonym payers_lez
  for cisadm_lez.payers;
  
create or replace synonym crc_acct_no_mappings_lez
  for cisadm_lez.crc_acct_no_mappings;

create or replace synonym batch_numbers_lez
  for cisadm_lez.batch_numbers_lez;
  
create or replace synonym tran_numbers_lez
  for cisadm_lez.tran_numbers_lez;

create or replace synonym get_or_no_lez
  for cisadm_lez.get_or_no_lez;