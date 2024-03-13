-- Create table
create table COLLECTION_FILES
(
  hdr_id      NUMBER not null,
  du_cd       VARCHAR2(10) not null,
  file_type   VARCHAR2(10),
  file_name   VARCHAR2(255),
  attachment  CLOB,
  created_by  VARCHAR2(30),
  created_on  DATE,
  uploaded_by VARCHAR2(30),
  uploaded_on DATE,
  status      VARCHAR2(5) default 'P'
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
-- Add comments to the columns 
comment on column COLLECTION_FILES.status
  is 'P = Pending, U = Uploaded, E = Error, C = Cancelled';
-- Create/Recreate primary, unique and foreign key constraints 
alter table COLLECTION_FILES
  add constraint COLLECTION_FILES_PK primary key (HDR_ID)
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
