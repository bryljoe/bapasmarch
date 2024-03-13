
create table wam_esb.TEMP_TICKET211767
(
  stock_code         VARCHAR2(50),
  subinventory_code  VARCHAR2(300),
  avg_price          NUMBER(15,5),
  inventory_quantity NUMBER(15,5),
  id                 NUMBER default "WAM_ESB"."TEMP_SEQ"."NEXTVAL",
  plant              VARCHAR2(10),
  stock_desc         VARCHAR2(4000),
  uom                VARCHAR2(20)
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
