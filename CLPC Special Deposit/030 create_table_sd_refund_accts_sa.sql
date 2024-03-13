-- Create table
create table SD_REFUND_ACCTS_SA
(
  period                  VARCHAR2(10) not null,
  acct_id                 CHAR(10) not null,
  sa_month                VARCHAR2(10) not null,
  acct_name               VARCHAR2(100),
  person_type             VARCHAR2(100),
  bill_cyc_cd             CHAR(4),
  mr_rte_cd               CHAR(16),
  address                 VARCHAR2(500),
  bd_msgr                 VARCHAR2(10),
  bd_seq                  VARCHAR2(10),
  prem_id                 CHAR(10),
  parent_prem_id          CHAR(10),
  active                  VARCHAR2(1),
  ar_balance_amt          NUMBER,
  ar_avg_bill_amt         NUMBER,
  prompt_payor            VARCHAR2(1),
  eligible_for_bd_topup   VARCHAR2(1),
  bd_balance_amt          NUMBER,
  bd_refund_amt           NUMBER,
  bd_refund_dt            DATE,
  wo_balance_amt          NUMBER,
  last_applied_rev_month  DATE,
  rev_period_from         DATE,
  rev_period_to           DATE,
  sd_total_balance_amt    NUMBER,
  sd_total_rev_amt        NUMBER,
  sd_total_parent_rev_amt NUMBER,
  sd_total_child_rev_amt  NUMBER,
  sd_total_for_bd_amt     NUMBER,
  sd_total_for_ar_amt     NUMBER,
  sd_total_for_wo_amt     NUMBER,
  sd_total_for_refund_amt NUMBER,
  status                  VARCHAR2(10),
  created_on              DATE default sysdate,
  applied_on              DATE,
  remarks                 VARCHAR2(100),
  apt_balance_amt         NUMBER,
  apwo_balance_amt        NUMBER,
  apar_balance_amt        NUMBER
)
tablespace CLPESB_DATA_01
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
alter table SD_REFUND_ACCTS_SA
  add constraint SD_REFUND_ACCTS_SA_PK primary key (PERIOD, ACCT_ID, SA_MONTH)
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
