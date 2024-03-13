-- Create table
create table CRC_ACCT_NO_MAPPINGS_TMP
(
  crc               NUMBER(10) not null,
  acct_no           VARCHAR2(10) not null,
  acct_status       VARCHAR2(1),
  schedule          VARCHAR2(20),
  area_code         VARCHAR2(4),
  government_code   VARCHAR2(2),
  tin               VARCHAR2(20),
  cfnp_required_amt NUMBER(15,2),
  last_date_paid    DATE,
  last_amount_paid  NUMBER(15,2),
  bd_required_amt   NUMBER(15,2),
  emp_acct          NUMBER(1) default 0,
  bus_add           VARCHAR2(100),
  bus_activity      VARCHAR2(100)
)
tablespace CISTS_DATA01
  pctfree 10
  initrans 1
  maxtrans 255;
-- Create/Recreate primary, unique and foreign key constraints 
alter table CRC_ACCT_NO_MAPPINGS_TMP
  add constraint CRC_ACCT_NO_MAPPINGS_TMP_PK primary key (ACCT_NO, CRC)
  using index 
  tablespace CISTS_DATA01
  pctfree 10
  initrans 2
  maxtrans 255;
