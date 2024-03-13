-- Create table
create table DEPOSIT_SAS
(
  period     VARCHAR2(10) not null,
  acct_id    CHAR(10) not null,
  sa_id      CHAR(10) not null,
  sa_type_cd CHAR(8),
  tot_amt    NUMBER(15,2),
  cur_amt    NUMBER(15,2),
  bal_amt    NUMBER(15,2),
  sa_month   VARCHAR2(10) not null

)
tablespace USERS
  pctfree 10
  initrans 1
  maxtrans 255
  storage
  (
    initial 64K
    next 1M
    minextents 1
    maxextents unlimited
  );
-- Create/Recreate primary, unique and foreign key constraints 
alter table DEPOSIT_SAS
  add constraint DEPOSIT_SAS_PK primary key (PERIOD, ACCT_ID, SA_ID, SA_MONTH)
  using index 
  tablespace CLPESB_DATA_01
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 64K
    next 1M
    minextents 1
    maxextents unlimited
  );
