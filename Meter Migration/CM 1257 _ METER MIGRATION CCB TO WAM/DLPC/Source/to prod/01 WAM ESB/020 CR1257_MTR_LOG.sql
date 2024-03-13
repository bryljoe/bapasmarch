-- Create table
create table CR1257_MTR_LOG
(
  log_id    NUMBER default "WAM_ESB"."LOG_ID_SEQ"."NEXTVAL" not null,
  plant     VARCHAR2(3) not null,
  meter_no  VARCHAR2(50) not null,
  acct_no   VARCHAR2(50),
  mtr_evt   VARCHAR2(5),
  read_dttm DATE,
  pole_no   VARCHAR2(50),
  note      VARCHAR2(3000),
  status    VARCHAR2(10) default 'P'
)
tablespace WAM_ESB_DATA
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
alter table CR1257_MTR_LOG
  add constraint MTR_LOG_PK primary key (PLANT, METER_NO)
  using index 
  tablespace WAM_ESB_DATA
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
-- Grant/Revoke object privileges 
grant select, insert, update on WAM_ESB.CR1257_MTR_LOG to CCB_DLPC;
