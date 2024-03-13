-- script 1 to execute in ESB 
declare
  l_plant             varchar2(10) := '03';
  l_asset_id          synergen.sa_asset.asset_id@wamprod.apd.com.ph%type;
  l_asset_record_type synergen.sa_asset.asset_record_type@wamprod.apd.com.ph%type;
  l_sp_id             ci_sp_mtr_hist.sp_id%type;
  l_acct_id           ci_sa.acct_id%type;
  l_pole_no           ci_sp_geo.geo_val%type;
  l_sp_cnt            number;
begin
  for mtr in (with meters as
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
                select m.badge_nbr,
                       m.mtr_id,
                       mc.mtr_config_id,
                       me.read_dttm,
                       mc.eff_dttm,
                       me.mr_id,
                       me.sp_mtr_hist_id,
                       me.sp_mtr_evt_flg
                  from meters m, mtr_config mc, mtr_event me
                 where m.dense_rank = 1
                   and m.mtr_id = mc.mtr_id
                   and mc.dense_rank = 1
                   and mc.mtr_config_id = me.mtr_config_id
                   and me.sp_mtr_evt_flg = 'I') loop
    --get sp id
    begin
      select sp_id
        into l_sp_id
        from ci_sp_mtr_hist
       where sp_mtr_hist_id = mtr.sp_mtr_hist_id;
    exception
      when no_data_found then
        null;
    end;
  
    -- validate installation meters
    with service_agreement as
     (select acct_id, sa_id
        from ci_sa
       where sa_status_flg = '20  '
         and sa_type_cd in ('E-RES   ', 'E-NRS-S ')
         and sa_type_cd <> 'NET-E   '),
    service_point as
     (select install_dt, sp_id
        from ci_sp
       where sp_type_cd in ('E-1PH-SC', 'E-3PH-SC'))
    select count(1)
      into l_sp_cnt
      from service_agreement sa, ci_sa_sp sasp, service_point sp
     where sa.sa_id = sasp.sa_id
       and sasp.sp_id = sp.sp_id
       and sp.sp_id = l_sp_id;
  
    if l_sp_cnt > 0 then
      --get ccb acct no.
      begin
        select aa.acct_id
          into l_acct_id
          from (select row_number() over(order by sp.install_dt desc nulls last, sasp.start_dttm desc nulls last, sa.start_dt desc nulls last, sasp.stop_dttm asc nulls first, sa.end_dt asc nulls first) as row_number_count,
                       sa.acct_id
                  from ci_sp sp, ci_sa_sp sasp, ci_sa sa
                 where sp.sp_id = sasp.sp_id
                   and sasp.sa_id = sa.sa_id
                   and sp.sp_id = l_sp_id
                   and sasp.usage_flg = '+ '
                   and sp.install_dt <= trunc(sysdate)
                   and trunc(sasp.start_dttm) <= trunc(sysdate)
                   and sa.start_dt <= trunc(sysdate) --  and trunc(nvl(sasp.stop_dttm,p_asof_date)) >= trunc(p_asof_date)
                --  and trunc(nvl(sa.end_dt,p_asof_date)) >= trunc(p_asof_date)
                ) aa
         where row_number_count = 1;
      
        --get pole no
        select aa.geo_val
          into l_pole_no
          from (select geo.geo_val,
                       row_number() over(order by geo.geo_type_cd desc) row_number_count
                  from ci_sp_geo geo
                 where geo.geo_type_cd in
                       ('POLENO  ', 'EMCPLNO ', 'MPNO    ')
                   and geo.sp_id = l_sp_id) aa
         where row_number_count = 1;
      
      exception
        when no_data_found then
          null;
      end;
      
      begin
        insert into wam_esb.cr1257_mtr_log@wamprod.apd.com.ph
          (plant, meter_no, acct_no, mtr_evt, read_dttm, pole_no)
        values
          (l_plant,
           mtr.badge_nbr,
           l_acct_id,
           mtr.sp_mtr_evt_flg,
           mtr.read_dttm,
           l_pole_no);
      exception
        when others then
          null;
      end;
      --dbms_output.put_line(mtr.badge_nbr || ' - ' || l_pole_no);
    end if;
  
    commit;
  end loop;

end;
