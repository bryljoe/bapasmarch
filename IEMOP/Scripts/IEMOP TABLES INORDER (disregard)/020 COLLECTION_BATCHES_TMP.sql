-- Create table
create table COLLECTION_BATCHES_TMP
(
  hdr_id           NUMBER not null,
  batch_no         NUMBER(15) not null,
  site_code        VARCHAR2(20) not null,
  booth            VARCHAR2(2) not null,
  teller           VARCHAR2(30) not null,
  mode_of_entry    VARCHAR2(12) default 'ON-LINE',
  created_by       VARCHAR2(30) not null,
  created_on       DATE not null,
  remitted_by      VARCHAR2(30),
  remitted_on      DATE,
  transmitted_by   VARCHAR2(30),
  transmitted_on   DATE,
  offline_or_date  DATE,
  or_count         NUMBER default 0,
  requested_lt_min NUMBER(2),
  granted_lt_min   NUMBER(2)
)
tablespace CISTS_DATA01
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
alter table COLLECTION_BATCHES_TMP
  add constraint COLLECTION_BATCHES_TMP_PK primary key (BATCH_NO)
  using index 
  tablespace CISTS_DATA01
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
alter table COLLECTION_BATCHES_TMP
  add constraint COLLECTION_BATCHES_TMP_FK foreign key (HDR_ID)
  references COLLECTION_FILES (HDR_ID);
