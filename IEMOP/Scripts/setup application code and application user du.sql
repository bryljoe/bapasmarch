-- set up application code
insert into app_codes (APP_CD, DESCRIPTION)
values ('IMP', 'IEMOP - Sale of Energy');

-- set up application user DU access
insert into cisadm_apps.app_user_du_privs (APP_USER_DU_ID, USERNAME, APP_CD, DU_CD, PRIM_DU_SW)
values (1000000326, 'BAPAS', 'IMP', 'CLPC', 'Y');

insert into cisadm_apps.app_user_du_privs (APP_USER_DU_ID, USERNAME, APP_CD, DU_CD, PRIM_DU_SW)
values (1000000327, 'BAPAS', 'IMP', 'DLPC', 'Y');

insert into cisadm_apps.app_user_du_privs (APP_USER_DU_ID, USERNAME, APP_CD, DU_CD, PRIM_DU_SW)
values (1000000328, 'BAPAS', 'IMP', 'VECO', 'Y');

insert into cisadm_apps.app_user_du_privs (APP_USER_DU_ID, USERNAME, APP_CD, DU_CD, PRIM_DU_SW)
values (1000000329, 'BAPAS', 'IMP', 'SEZ', 'Y');

insert into cisadm_apps.app_user_du_privs (APP_USER_DU_ID, USERNAME, APP_CD, DU_CD, PRIM_DU_SW)
values (1000000330, 'BAPAS', 'IMP', 'MEZ', 'Y');

insert into cisadm_apps.app_user_du_privs (APP_USER_DU_ID, USERNAME, APP_CD, DU_CD, PRIM_DU_SW)
values (1000000331, 'BAPAS', 'IMP', 'BEZ', 'Y');

insert into cisadm_apps.app_user_du_privs (APP_USER_DU_ID, USERNAME, APP_CD, DU_CD, PRIM_DU_SW)
values (1000000332, 'BAPAS', 'IMP', 'LEZ', 'Y');