create or replace package body esb.cr_mtr_asset_migration_pkg is
  /* ============================================================
  Author  : Bryl Apas and Aldwin Carcallas
  Purpose :
  
  REVISION HISTORY
  version v1.0.0 by bapas & acarcallas on March 31, 2023
     Purpose of Change :
     Affected Objects  : new:main
                         new:process_meter
                         new:set_meter_asset
                         new:set_meter_component
                         new:valid_installation
                         new:valid_removal
                         new:has_asset_id
                         new:get_sp_id
                         new:get_mtr_install_dt
                         new:log_error
     Remarks           :
  ============================================================ */

  procedure log_error(p_errmsg in varchar2) is
    pragma autonomous_transaction;
  
  begin
    insert into error_logs
      (logged_by, logged_on, module, custom_error_msg)
    values
      (user, sysdate, 'CR_MTR_ASSET_MIGRATION_PKG', p_errmsg);
    commit;
  end log_error;

  function get_acct_id(p_col_id    in varchar2,
                       p_val_id    in char,
                       p_asof_date in date) return ci_sa.acct_id%type as
    --Declare Variable
    v_return ci_sa.acct_id%type;
  begin
    --If Parameter Given is 'SA_ID'
    if p_col_id = 'SA_ID' then
      select a.acct_id into v_return from ci_sa a where a.sa_id = p_val_id;
      --If Parameter Given is 'SP_ID'
    elsif p_col_id = 'SP_ID' then
      select aa.acct_id
        into v_return
        from (select row_number() over(order by sp.install_dt desc nulls last, sasp.start_dttm desc nulls last, sa.start_dt desc nulls last, sasp.stop_dttm asc nulls first, sa.end_dt asc nulls first) as row_number_count,
                     sa.acct_id
                from ci_sp sp, ci_sa_sp sasp, ci_sa sa
               where sp.sp_id = sasp.sp_id
                 and sasp.sa_id = sa.sa_id
                 and sp.sp_id = p_val_id
                 and sasp.usage_flg = '+ '
                 and sp.install_dt <= trunc(p_asof_date)
                 and trunc(sasp.start_dttm) <= trunc(p_asof_date)
                 and sa.start_dt <= trunc(p_asof_date) --  and trunc(nvl(sasp.stop_dttm,p_asof_date)) >= trunc(p_asof_date)
              --  and trunc(nvl(sa.end_dt,p_asof_date)) >= trunc(p_asof_date)
              ) aa
       where row_number_count = 1;
    else
      null;
    end if;
  
    return v_return;
  exception
    when others then
      return 0;
  end get_acct_id;

  function get_acct_poleno(p_col_id    in varchar2,
                           p_val_id    in char,
                           p_asof_date in date) return ci_sp_geo.geo_val%type as
    --Declare Variable
    v_return ci_sp_geo.geo_val%type;
  begin
    --If Given Parameter is 'SP_ID'
    if p_col_id = 'SP_ID' then
      select aa.geo_val
        into v_return
        from (select geo.geo_val,
                     row_number() over(order by geo.geo_type_cd desc) row_number_count
                from ci_sp_geo geo
               where geo.geo_type_cd in ('POLENO  ', 'EMCPLNO ', 'MPNO    ')
                 and geo.sp_id = p_val_id) aa
       where row_number_count = 1;
      --If Given Parameter is 'SA_ID'
    elsif p_col_id = 'SA_ID' then
      select aa.geo_val
        into v_return
        from (select geo.geo_val,
                     row_number() over(order by ss.start_dttm desc, geo.geo_type_cd desc nulls last, stop_dttm nulls first) row_number_count
                from ci_sp_geo geo, ci_sa_sp ss
               where geo.geo_type_cd in ('POLENO  ', 'EMCPLNO ', 'MPNO    ')
                 and geo.sp_id = ss.sp_id
                 and ss.usage_flg = '+'
                 and ss.sa_id = p_val_id
                 and ss.start_dttm <= p_asof_date) aa
       where row_number_count = 1;
    elsif p_col_id = 'ACCT_ID' then
      select aa.geo_val
        into v_return
        from (select geo.geo_val,
                     row_number() over(order by ss.start_dttm desc, geo.geo_type_cd desc nulls last, stop_dttm nulls first) row_number_count
                from ci_sp_geo geo, ci_sa_sp ss, ci_sa sa
               where geo.geo_type_cd in ('POLENO  ', 'EMCPLNO ', 'MPNO    ')
                 and geo.sp_id = ss.sp_id
                 and ss.sa_id = sa.sa_id
                 and ss.usage_flg = '+'
                 and sa.acct_id = p_val_id
                 and ss.start_dttm <= p_asof_date) aa
       where row_number_count = 1;
    else
      null;
    end if;
  
    return v_return;
  exception
    when others then
      return null;
  end get_acct_poleno;

  function get_mtr_install_dt(p_col_id in varchar2, p_val_id in char)
    return date is
  
    l_mtr_install_dt ci_mr.read_dttm%type;
  
  begin
    if p_col_id = 'MTR_CONFIG_ID' then
      select max(read_dttm) read_dttm
        into l_mtr_install_dt
        from ci_mr
       where mtr_config_id = p_val_id;
    elsif p_col_id = 'MR_ID' then
      select max(read_dttm) read_dttm
        into l_mtr_install_dt
        from ci_mr
       where mr_id = p_val_id;
    else
      l_mtr_install_dt := null;
    end if;
  
    return l_mtr_install_dt;
  
  end get_mtr_install_dt;

  function get_sp_id(p_sp_mtr_hist_id in ci_sp_mtr_hist.sp_mtr_hist_id%type)
    return char is
  
    l_sp_id ci_sp_mtr_hist.sp_id%type;
  
  begin
    select sp_id
      into l_sp_id
      from ci_sp_mtr_hist
     where sp_mtr_hist_id = p_sp_mtr_hist_id;
  
    return l_sp_id;
  
  end get_sp_id;

  function has_asset_id(p_plant in varchar2, p_badge_nbr in varchar2)
    return boolean is
    l_record_cnt integer;
  begin
    select count(1)
      into l_record_cnt
      from synergen.sa_asset@wam.davaolight.com
     where plant = p_plant
       and asset_type = '1I01'
       and trim(manufacturer_part_no) = p_badge_nbr;
  
    if l_record_cnt > 0 then
      return true;
    else
      return false;
    end if;
  end has_asset_id;

  function valid_installation(p_sp_id ci_sp.sp_id%type) return boolean is
    /* ------------------------------------------------------------
        REVISION HISTORY
        v1.0.0 by acarcallas on March 31, 2023
          Remarks : Verify if included in the parameters:
                    1. Service Agreement = ACTIVE and ELECTRIC (E-RES and E-NRS-S)
                    2. Service Point = 1PH Self Contained & 3PH Self Contained
                    3. Exclude NET-METERING
    ------------------------------------------------------------ */
    l_record_cnt integer;
  begin
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
      into l_record_cnt
      from service_agreement sa, ci_sa_sp sasp, service_point sp
     where sa.sa_id = sasp.sa_id
       and sasp.sp_id = sp.sp_id
       and sp.sp_id = p_sp_id;
  
    if l_record_cnt > 0 then
      return true;
    else
      return false;
    end if;
  end valid_installation;

  function valid_removal(p_sp_id ci_sa_sp.sp_id%type) return boolean is
    /* ------------------------------------------------------------
        REVISION HISTORY
        v1.0.0 by acarcallas on March 31, 2023
          Remarks : Verify if included in the parameters:
                    1. Service Agreement = ACTIVE and ELECTRIC (E-RES and E-NRS-S)
                    2. Field Activity = Complete and METER REMOVAL & CFNP METER REMOVAL
                    3. Exclude NET-METERING
    ------------------------------------------------------------ */
    l_record_cnt integer;
  begin
    with service_agreement as
     (select acct_id, sa_id
        from ci_sa
       where sa_status_flg = '40  '
         and sa_type_cd in ('E-RES   ', 'E-NRS-S ')
         and sa_type_cd <> 'NET-E   '),
    field_activity as
     (select fa_id, sp_id
        from ci_fa
       where fa_status_flg = 'C '
         and fa_type_cd in ('M-REMMTR', 'M-MTRDSC'))
    select count(1)
      into l_record_cnt
      from service_agreement sa, ci_sa_sp sasp, field_activity fa
     where sa.sa_id = sasp.sa_id
       and sasp.sp_id = fa.sp_id
       and fa.sp_id = p_sp_id;
  
    if l_record_cnt > 0 then
      return true;
    else
      return false;
    end if;
  end valid_removal;

  procedure set_meter_asset(p_plant             in varchar2,
                            p_acct_id           in varchar2,
                            p_badge_nbr         in varchar2,
                            p_install_dt        in date,
                            p_pole_no           in varchar2,
                            p_asset_id          out varchar2,
                            p_asset_record_type in out varchar2,
                            p_action            in varchar2) is
    /* ------------------------------------------------------------
        REVISION HISTORY
        v1.0.0 by acarcallas on April 3, 2023
          Remarks : This procedure will create new asset id and insert in wam asset table.
    ------------------------------------------------------------ */
    l_errmsg   varchar(3000);
    l_errline  number;
    l_asset_id synergen.sa_asset.asset_id@wam.davaolight.com%type;
  begin
    if p_action = 'I' then
      l_errline := 10;
      if not has_asset_id(p_plant => p_plant, p_badge_nbr => p_badge_nbr) then
        l_errline := 20;
        select nvl(max(asset_id),100000010000000)
          into l_asset_id
          from synergen.sa_asset@wam.davaolight.com
         where plant = p_plant
           and created_by = 'MIGRATED'
           and asset_id > '100000010000000';
      
        l_asset_id := l_asset_id + 1;
        p_asset_id := l_asset_id;
        p_asset_record_type := 'I';
        
        l_errline := 30;
        insert into synergen.sa_asset@wam.davaolight.com
          (plant,
           attribute3,
           manufacturer_part_no,
           original_install_date,
           last_install_date,
           asset_status,
           asset_record_type,
           asset_id,
           asset_type,
           asset_class,
           asset_desc,
           specification_no,
           specification_type,
           specification_category,
           point_id,
           creation_date,
           created_by,
           asset_segment1,
           asset_segment2,
           asset_segment3,
           asset_segment5)
        values
          (p_plant,
           p_acct_id, -- acct_id in CCB
           p_badge_nbr,
           p_install_dt, -- install dt in function
           p_install_dt, -- install dt in function
           'ACTIVE',
           p_asset_record_type,
           l_asset_id, -- asset generated
           '1I01',
           '1I00',
           'METER, KILOWATT HOUR',
           '',
           'ASSET',
           'METER',
           p_pole_no, --poleno,
           sysdate,
           'MIGRATED',
           'NET',
           'R',
           '220',
           'N/A');
      
      else
      
        l_errline := 40;
        update synergen.sa_asset@wam.davaolight.com
           set asset_status     = 'ACTIVE',
               last_update_date = sysdate,
               last_update_user = 'MIGRATED'
         where plant = p_plant
           and asset_type = '1I01'
           and manufacturer_part_no = p_badge_nbr;
      
        select max(asset_id) asset_id, asset_record_type
          into p_asset_id, p_asset_record_type
          from synergen.sa_asset@wam.davaolight.com
         where plant = p_plant
           and asset_type = '1I01'
           and manufacturer_part_no = p_badge_nbr
         group by asset_id, asset_record_type;
      
      end if;
    
    elsif p_action = 'R' then
      if has_asset_id(p_plant => p_plant, p_badge_nbr => p_badge_nbr) then
        update synergen.sa_asset@wam.davaolight.com
           set asset_status     = 'INACTIVE',
               last_update_date = sysdate,
               last_update_user = 'MIGRATED'
         where plant = p_plant
           and asset_type = '1I01'
           and manufacturer_part_no = p_badge_nbr;
      else
        null; --to follow
      end if;
    end if;
  
  exception
    when others then
      l_errmsg := 'Error in procedure set_meter_asset @Line: ' || l_errline ||
                  ' - ' || sqlerrm;
      log_error(l_errmsg);
      raise_application_error(-20000, l_errmsg);
  end set_meter_asset;

  procedure set_meter_component(p_plant             in varchar2,
                                p_badge_nbr         in varchar2,
                                p_action            in varchar2,
                                p_effective_date    in date,
                                p_asset_id          in varchar2,
                                p_asset_record_type in varchar2) is
    /* ------------------------------------------------------------
        REVISION HISTORY
        v1.0.0 by acarcallas on April 3, 2023
          Remarks : This procedure will update the wam component table.
    ------------------------------------------------------------ */
    l_errmsg       varchar(3000);
    l_errline      number;
    l_record_count integer;
  begin
    l_errline := 10;

    if p_action = 'I' then
      l_errline := 20;
    
      update synergen.sa_component_id@wam.davaolight.com
         set asset_id            = p_asset_id,
             asset_record_type   = p_asset_record_type,
             component_id_status = 'INSTALLED',
             last_update_date    = sysdate,
             last_update_user    = 'INTERFACE'
       where plant = p_plant
         and component_id = p_badge_nbr;
    
      /*if p_effective_date <= to_date('12/31/2018', 'MM/DD/YYYY') then
        update synergen.sa_component_id@wam.davaolight.com
           set component_id_status = 'INSTALLED',
               last_update_date    = sysdate,
               last_update_user    = 'INTERFACE'
         where plant = p_plant
           and component_id = lpad(p_badge_nbr, 15, '0');
      end if;*/
    
    elsif p_action = 'R' then
      l_errline := 30;
      update synergen.sa_component_id@wam.davaolight.com
         set component_id_status = 'IN STORES',
             last_update_date    = sysdate,
             last_update_user    = 'INTERFACE',
             asset_id            = '',
             asset_record_type   = ''
       where plant = p_plant
         and component_id = p_badge_nbr;
    
      if p_effective_date <= to_date('12/31/2018', 'MM/DD/YYYY') then
        update synergen.sa_component_id@wam.davaolight.com
           set component_id_status = 'IN STORES',
               last_update_date    = sysdate,
               last_update_user    = 'INTERFACE',
               asset_id            = '',
               asset_record_type   = ''
         where plant = p_plant
           and component_id = lpad(p_badge_nbr, 15, '0');
      
      end if;
    
    end if;
    /*else
      if p_action = 'I' then
        null; --to follow
      elsif p_action = 'R' then
        null; --to follow
      end if;
    end if;*/
  
  exception
    when others then
      l_errmsg := 'Error in procedure set_meter_component @Line: ' ||
                  l_errline || ' - ' || sqlerrm;
      log_error(l_errmsg);
      raise_application_error(-20000, l_errmsg);
  end set_meter_component;

  procedure process_meter(p_plant in varchar2) is
    /* ------------------------------------------------------------
        REVISION HISTORY
        v1.0.0 by acarcallas on April 3, 2023
          Remarks : This procedure will process the meter data of the day.
    ------------------------------------------------------------ */
    l_errmsg            varchar(3000);
    l_errline           number;
    l_sp_id             ci_sp_mtr_hist.sp_id%type;
    l_install_dt        ci_mr.read_dttm%type;
    l_asset_id          synergen.sa_asset.asset_id@wam.davaolight.com%type;
    l_asset_record_type synergen.sa_asset.asset_record_type@wam.davaolight.com%type;
  
    cursor cur_mtr is
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
           and mr.read_dttm >= trunc(sysdate)
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
         and mc.mtr_config_id = me.mtr_config_id;
  
  begin
    l_errline := 10;
    for rec_mtr in cur_mtr loop
      begin
        l_errline := 20;
        l_sp_id   := get_sp_id(p_sp_mtr_hist_id => rec_mtr.sp_mtr_hist_id);
      
        --Process if meter is installed.
        if rec_mtr.sp_mtr_evt_flg = 'I' then
          l_errline := 30;
          if valid_installation(p_sp_id => l_sp_id) then
            l_errline    := 35;
            l_install_dt := rec_mtr.read_dttm;
            l_errline    := 40;
            set_meter_asset(p_plant             => p_plant,
                            p_acct_id           => get_acct_id(p_col_id    => 'SP_ID',
                                                               p_val_id    => l_sp_id,
                                                               p_asof_date => sysdate),
                            p_badge_nbr         => rec_mtr.badge_nbr,
                            p_install_dt        => l_install_dt,
                            p_pole_no           => get_acct_poleno(p_col_id    => 'SP_ID',
                                                                   p_val_id    => l_sp_id,
                                                                   p_asof_date => sysdate),
                            p_asset_id          => l_asset_id,
                            p_asset_record_type => l_asset_record_type,
                            p_action            => rec_mtr.sp_mtr_evt_flg);
          
            l_errline := 50;
            set_meter_component(p_plant             => p_plant,
                                p_badge_nbr         => rec_mtr.badge_nbr,
                                p_action            => rec_mtr.sp_mtr_evt_flg,
                                p_effective_date    => rec_mtr.eff_dttm,
                                p_asset_id          => l_asset_id,
                                p_asset_record_type => l_asset_record_type);
          end if;
          --Process if meter is removed.
        elsif rec_mtr.sp_mtr_evt_flg = 'R' then
          l_errline := 60;
          if valid_removal(p_sp_id => l_sp_id) then
            l_errline := 70;
            set_meter_asset(p_plant             => p_plant,
                            p_acct_id           => get_acct_id(p_col_id    => 'SP_ID',
                                                               p_val_id    => l_sp_id,
                                                               p_asof_date => sysdate),
                            p_badge_nbr         => rec_mtr.badge_nbr,
                            p_install_dt        => null,
                            p_pole_no           => get_acct_poleno(p_col_id    => 'SP_ID',
                                                                   p_val_id    => l_sp_id,
                                                                   p_asof_date => sysdate),
                            p_asset_id          => l_asset_id,
                            p_asset_record_type => l_asset_record_type,
                            p_action            => rec_mtr.sp_mtr_evt_flg);
            l_errline := 80;
            set_meter_component(p_plant             => p_plant,
                                p_badge_nbr         => rec_mtr.badge_nbr,
                                p_action            => rec_mtr.sp_mtr_evt_flg,
                                p_effective_date    => rec_mtr.eff_dttm,
                                p_asset_id          => l_asset_id,
                                p_asset_record_type => l_asset_record_type);
          end if;
        end if;
      
      exception
        when others then
          rollback;
          l_errmsg := 'Error in procedure process_meter @Line: ' ||
                      l_errline || ' - ' || sqlerrm ||
                      '. @Param: badge_nbr: ' || rec_mtr.badge_nbr;
          log_error(l_errmsg);
      end;
    end loop;
  end process_meter;

  procedure main(p_plant in varchar2) is
    /* ------------------------------------------------------------
        REVISION HISTORY
        v1.0.0 by acarcallas on March 31, 2023
          Remarks :
    ------------------------------------------------------------ */
  begin
    process_meter(p_plant);
  end main;

end cr_mtr_asset_migration_pkg;
