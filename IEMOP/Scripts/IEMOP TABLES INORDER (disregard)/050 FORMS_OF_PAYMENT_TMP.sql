-- Create table
create table FORMS_OF_PAYMENT_TMP
(
  tran_no      NUMBER not null,
  seq_no       NUMBER(3) not null,
  payment_type VARCHAR2(12),
  amount_paid  NUMBER(15,2)
)
tablespace CISTS_DATA01
  pctfree 10
  initrans 1
  maxtrans 255;
-- Create/Recreate primary, unique and foreign key constraints 
alter table FORMS_OF_PAYMENT_TMP
  add constraint FORMS_OF_PAYMENT_TMP_PK primary key (TRAN_NO, SEQ_NO)
  using index 
  tablespace CISTS_DATA01
  pctfree 10
  initrans 2
  maxtrans 255;
alter table FORMS_OF_PAYMENT_TMP
  add constraint FORMS_OF_PAYMENT_TMP_FK foreign key (TRAN_NO)
  references PAYMENT_TRANSACTIONS_TMP (TRAN_NO);
