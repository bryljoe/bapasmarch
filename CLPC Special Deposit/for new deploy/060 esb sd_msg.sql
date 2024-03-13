
insert into sd_refund_registry (REG_CODE, REG_VALUE, REMARKS, EFFDT)
values ('BILLDEPMSG', '19BD', 'Special Deposit with Bill Deposit Top Up Only', to_date('01-01-2019', 'dd-mm-yyyy'));

insert into sd_refund_registry (REG_CODE, REG_VALUE, REMARKS, EFFDT)
values ('REFUNDMSG', '19RF', 'Special Deposit with Refund Only', to_date('01-01-2019', 'dd-mm-yyyy'));

insert into sd_refund_registry (REG_CODE, REG_VALUE, REMARKS, EFFDT)
values ('ARMSG', '19AR', 'Special Deposit with Bill Deposit Top Up and Refund', to_date('01-01-2019', 'dd-mm-yyyy'));

insert into sd_refund_registry (REG_CODE, REG_VALUE, REMARKS, EFFDT)
values ('WOMSG', '19WO', 'Special Deposit with Writeoff Only', to_date('01-01-2019', 'dd-mm-yyyy'));

commit;
