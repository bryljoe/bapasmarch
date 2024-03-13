-- Create the synonym 
create or replace synonym collection_batches_dlp
  for cisadm_dlp.collection_batches;
  
create or replace synonym paid_items_dlp
  for cisadm_dlp.paid_items;

create or replace synonym payment_transactions_dlp
  for cisadm_dlp.payment_transactions;
  
create or replace synonym paid_acct_facts_dlp
  for cisadm_dlp.paid_acct_facts;
  
create or replace synonym forms_of_payment_dlp
  for cisadm_dlp.forms_of_payment;
  
create or replace synonym fop_cash_dlp
  for cisadm_dlp.fop_cash;
  
create or replace synonym payers_dlp
  for cisadm_dlp.payers;
  
create or replace synonym batch_numbers_dlp
  for cisadm_dlp.batch_numbers_dlp;
  
create or replace synonym tran_numbers_dlp
  for cisadm_dlp.tran_numbers_dlp;

create or replace synonym get_or_no_dlp
  for cisadm_dlp.get_or_no_dlp;