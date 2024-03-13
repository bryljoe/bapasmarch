alter table balance_sas drop primary key;

alter table balance_sas
add constraint balance_sas_pk primary key (period, acct_id, sa_id,sa_month);

alter table deposit_sas drop primary key;

alter table deposit_sas
add constraint deposit_sas_pk primary key (period, acct_id, sa_id,sa_month);