-- Create table
create table PAID_ITEMS_TMP
(
  tran_no       NUMBER not null,
  seq_no        NUMBER(3) not null,
  pay_code      VARCHAR2(20) not null,
  amount_credit NUMBER(15,2)
)
tablespace CISTS_DATA01
  pctfree 10
  initrans 1
  maxtrans 255;
-- Create/Recreate primary, unique and foreign key constraints 
alter table PAID_ITEMS_TMP
  add constraint PAID_ITEMS_TMP_PK primary key (TRAN_NO, SEQ_NO)
  using index 
  tablespace CISTS_DATA01
  pctfree 10
  initrans 2
  maxtrans 255;
alter table PAID_ITEMS_TMP
  add constraint PAID_ITEMS_TMP_FK foreign key (TRAN_NO)
  references PAYMENT_TRANSACTIONS_TMP (TRAN_NO);
