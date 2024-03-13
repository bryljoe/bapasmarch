-- Create table
create table PAYERS_TMP
(
  payer_type VARCHAR2(10) not null,
  payer_id   VARCHAR2(20) not null,
  last_name  VARCHAR2(64) not null,
  first_name VARCHAR2(40),
  mid_name   VARCHAR2(40),
  address    VARCHAR2(120)
)
tablespace CISTS_DATA01
  pctfree 10
  initrans 1
  maxtrans 255;
-- Create/Recreate primary, unique and foreign key constraints 
alter table PAYERS_TMP
  add constraint PAYERS_TMP_PK primary key (PAYER_TYPE, PAYER_ID)
  using index 
  tablespace CISTS_DATA01
  pctfree 10
  initrans 2
  maxtrans 255;
