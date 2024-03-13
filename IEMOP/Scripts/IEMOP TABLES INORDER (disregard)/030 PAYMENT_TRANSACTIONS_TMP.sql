-- Create table
create table PAYMENT_TRANSACTIONS_TMP
(
  tran_no       NUMBER not null,
  last_name     VARCHAR2(100) not null,
  first_name    VARCHAR2(50),
  mid_name      VARCHAR2(50),
  address       VARCHAR2(200),
  or_no         NUMBER(10) not null,
  or_date       DATE not null,
  or_status     VARCHAR2(16) not null,
  remarks       VARCHAR2(200),
  bank_ref_no   VARCHAR2(20),
  batch_no      NUMBER(15) not null,
  payer_id      VARCHAR2(20) not null,
  payer_type    VARCHAR2(10) not null,
  posted        NUMBER(1) default 0,
  cancel_reason VARCHAR2(200),
  or_count      NUMBER
)
tablespace CISTS_DATA01
  pctfree 10
  initrans 1
  maxtrans 255;
-- Create/Recreate primary, unique and foreign key constraints 
alter table PAYMENT_TRANSACTIONS_TMP
  add constraint PAYMENT_TRANSACTIONS_TMP_PK primary key (TRAN_NO)
  using index 
  tablespace CISTS_DATA01
  pctfree 10
  initrans 2
  maxtrans 255;
alter table PAYMENT_TRANSACTIONS_TMP
  add constraint PAYMENT_TRANSACTIONS_TMP_FK foreign key (BATCH_NO)
  references COLLECTION_BATCHES_TMP (BATCH_NO);
