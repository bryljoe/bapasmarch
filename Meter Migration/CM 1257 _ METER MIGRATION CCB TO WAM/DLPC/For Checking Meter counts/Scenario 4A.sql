-- Scenario 4A
declare
  l_plant       varchar2(10) := '01';
  l_mtr_cnt_ccb number;
  l_mtr_cnt_wam number;
begin
	
  select count(1)
    into l_mtr_cnt_wam
    from synergen.sa_asset@wamprod.apd.com.ph sa
   where plant = l_plant
     and asset_type = '1I01'
     and asset_status = 'ACTIVE';

  dbms_output.put_line('WAM Meters : ' ||
                       l_mtr_cnt_wam);
	                    
  with meters as
   (select trim(badge_nbr) badge_nbr,
           mtr_id,
           dense_rank() over(partition by badge_nbr order by receive_dt desc) dense_rank
      from ci_mtr),
  mtr_config as
   (select mtr_config_id,
           mtr_id,
           eff_dttm,
           dense_rank() over(partition by mtr_id order by eff_dttm desc) dense_rank
      from ci_mtr_config
     where mtr_config_ty_cd <> 'E-EXPORT    '),
  mtr_event as
   (select mr.mtr_config_id,
           max(mr.read_dttm) keep(dense_rank first order by mr.read_dttm desc) read_dttm,
           max(mr.mr_id) keep(dense_rank first order by mr.read_dttm desc) mr_id,
           max(csme.sp_mtr_hist_id) keep(dense_rank first order by mr.read_dttm desc) sp_mtr_hist_id,
           max(trim(csme.sp_mtr_evt_flg)) keep(dense_rank first order by mr.read_dttm desc) sp_mtr_evt_flg
      from ci_mr mr, ci_sp_mtr_evt csme
     where mr.mr_id = csme.mr_id
    --and mr.read_dttm >= trunc(sysdate)
     group by mr.mtr_config_id)
  select count(1)
    into l_mtr_cnt_ccb
    from meters m, mtr_config mc, mtr_event me
   where m.dense_rank = 1
     and m.mtr_id = mc.mtr_id
     and mc.dense_rank = 1
     and mc.mtr_config_id = me.mtr_config_id
     /*and me.sp_mtr_evt_flg = 'I'*/;

  dbms_output.put_line('CCB Meters : ' || l_mtr_cnt_ccb);



end;
