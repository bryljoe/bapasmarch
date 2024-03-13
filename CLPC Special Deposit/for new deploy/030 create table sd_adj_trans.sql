-- Create table
create table SD_ADJ_TRANS
(
  period              VARCHAR2(10) not null,
  acct_id             CHAR(10) not null,
  sa_id_from          CHAR(10) not null,
  sa_id_to            CHAR(10) not null,
  adj_type_cd_from    CHAR(8),
  adj_type_cd_to      CHAR(8),
  amount              NUMBER,
  remarks             VARCHAR2(100),
  status              VARCHAR2(10),
  created_on          DATE,
  created_by          VARCHAR2(30),
  adj_stg_ctl_id_from NUMBER,
  adj_stg_ctl_id_to   NUMBER,
  adj_stg_up_id_from  NUMBER,
  adj_stg_up_id_to    NUMBER
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
alter table SD_ADJ_TRANS
  add constraint SD_ADJ_TRANS_PK primary key (PERIOD, ACCT_ID, SA_ID_FROM, SA_ID_TO)
  using index 
  tablespace USERS
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
