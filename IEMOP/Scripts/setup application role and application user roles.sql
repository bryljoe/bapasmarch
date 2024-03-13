-- set up application role codes
insert into app_roles (ROLE_CD, DESCRIPTION)
values ('IMP_UPLOADER', 'IEMOP Uploader Access');

insert into app_roles (ROLE_CD, DESCRIPTION)
values ('IMP_INQUIRY', 'IEMOP Inquiry Access');

-- set up application user role access
insert into app_user_role_privs (APP_USER_ROLE_ID, USERNAME, APP_CD, ROLE_CD)
values (1000000217, 'BAPAS', 'IMP', 'IMP_UPLOADER');

insert into app_user_role_privs (APP_USER_ROLE_ID, USERNAME, APP_CD, ROLE_CD)
values (1000000218, 'BAPAS', 'IMP', 'IMP_INQUIRY');

insert into app_user_role_privs (APP_USER_ROLE_ID, USERNAME, APP_CD, ROLE_CD)
values (1000000219, 'BAPAS', 'IMP', 'ADMIN');