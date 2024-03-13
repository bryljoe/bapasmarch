-- Create the synonym 
create or replace synonym collection_batches_clp
  for cisadm_clp.collection_batches;
  
create or replace synonym paid_items_clp
  for cisadm_clp.paid_items;

create or replace synonym payment_transactions_clp
  for cisadm_clp.payment_transactions;
  
create or replace synonym paid_acct_facts_clp
  for cisadm_clp.paid_acct_facts;
  
create or replace synonym forms_of_payment_clp
  for cisadm_clp.forms_of_payment;
  
create or replace synonym fop_cash_clp
  for cisadm_clp.fop_cash;
  
create or replace synonym payers_clp
  for cisadm_clp.payers;
  
create or replace synonym crc_acct_no_mappings_clp
  for cisadm_clp.crc_acct_no_mappings;

create or replace synonym batch_numbers_clp
  for cisadm_clp.batch_numbers_clp;
  
create or replace synonym tran_numbers_clp
  for cisadm_clp.tran_numbers_clp;

create or replace synonym get_or_no_clp
  for cisadm_clp.get_or_no_clp;