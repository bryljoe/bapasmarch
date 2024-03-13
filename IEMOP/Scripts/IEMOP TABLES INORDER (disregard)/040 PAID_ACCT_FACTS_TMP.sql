-- Create table
create table PAID_ACCT_FACTS_TMP
(
  tran_no           NUMBER not null,
  acct_no           VARCHAR2(10),
  acct_status       CHAR(1),
  schedule          VARCHAR2(20),
  area_code         VARCHAR2(4),
  government_code   VARCHAR2(2),
  tin               VARCHAR2(20),
  cfnp_required_amt NUMBER(15,2),
  last_date_paid    DATE,
  last_amount_paid  NUMBER(15,2),
  apply_for_recon   NUMBER(1) default 0
)
tablespace CISTS_DATA01
  pctfree 10
  initrans 1
  maxtrans 255;
-- Create/Recreate primary, unique and foreign key constraints 
alter table PAID_ACCT_FACTS_TMP
  add constraint PAID_ACCT_FACTS_TMP_PK primary key (TRAN_NO)
  using index 
  tablespace CISTS_DATA01
  pctfree 10
  initrans 2
  maxtrans 255;
alter table PAID_ACCT_FACTS_TMP
  add constraint PAID_ACCT_FACTS_TMP_FK foreign key (TRAN_NO)
  references PAYMENT_TRANSACTIONS_TMP (TRAN_NO);
