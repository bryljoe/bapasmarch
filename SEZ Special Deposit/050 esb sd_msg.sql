insert into sd_refund_registry (REG_CODE, REG_VALUE, REMARKS, EFFDT)
values ('BILLDEPMSG', '19BD', 'Special Deposit with Bill Deposit Top Up Only', to_date('01-01-2019', 'dd-mm-yyyy'));

insert into sd_refund_registry (REG_CODE, REG_VALUE, REMARKS, EFFDT)
values ('REFUNDMSG', '19RF', 'Special Deposit with Refund Only', to_date('01-01-2019', 'dd-mm-yyyy'));

insert into sd_refund_registry (REG_CODE, REG_VALUE, REMARKS, EFFDT)
values ('ARMSG', '19AR', 'Special Deposit with Bill Deposit Top Up and Refund', to_date('01-01-2019', 'dd-mm-yyyy'));

insert into sd_refund_registry (REG_CODE, REG_VALUE, REMARKS, EFFDT)
values ('WOMSG', '19WO', 'Special Deposit with Writeoff Only', to_date('01-01-2019', 'dd-mm-yyyy'));

insert into sd_refund_registry (REG_CODE, REG_VALUE, REMARKS, EFFDT)
values ('CLAIM_ADDRESS3', 'Canal Road corner Labitan Street. CBD Area, Subic Bay Freeport Zone', 'Claiming Address', to_date('31-12-2017', 'dd-mm-yyyy'));

update sd_refund_registry
   set reg_value = 'Dante T. Pollescas'
 where reg_code = 'SIGN_NAME';
 
update sd_refund_registry
   set reg_value = '(63-47) 250-1200'
 where reg_code = 'CONTACT_NO'; 

commit;