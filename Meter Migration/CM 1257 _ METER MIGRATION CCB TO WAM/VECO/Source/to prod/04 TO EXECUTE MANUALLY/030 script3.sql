-- script 3 to execute wam_esb
declare
  l_plant             varchar2(10) := '03';
  l_asset_id          synergen.sa_asset.asset_id%type;
  l_max_asset_id      synergen.sa_asset.asset_id%type;
  l_asset_record_type synergen.sa_asset.asset_record_type%type;
  l_component_id      synergen.sa_component_id.component_id%type;
  l_status            varchar2(20);
  l_update_cnt        number;
begin
  -- get installed meters from Temp Table
  for mtr in (select cml.log_id,
                     cml.plant,
                     cml.meter_no,
                     cml.acct_no,
                     cml.mtr_evt,
                     cml.read_dttm,
                     cml.pole_no,
                     cml.status
                from wam_esb.cr1257_mtr_log cml
               where cml.plant = l_plant
                 and nvl(cml.status, 'P') = 'P') loop
  
    begin
      select asset_id, asset_record_type, asset_status
        into l_asset_id, l_asset_record_type, l_status
        from synergen.sa_asset
       where asset_type = '1I01'
         and plant = l_plant
         and manufacturer_part_no = mtr.meter_no;
    
    exception
      when dup_val_on_index then
        l_status := 'Duplicate';
      
      when others then
        l_status := null;
      
    end;
  
    if l_status is null then
    
      -- check if naay component, if naay component insert data , if wala walay buhaton or update temp nga walay na update (add notes column in temp table) 
      select count(1)
        into l_component_id
        from synergen.sa_component_id
       where plant = l_plant
         and component_id = mtr.meter_no;
    
      if l_component_id > 0 then
        -- get max asset id
        select nvl(max(asset_id), 100000010000000)
          into l_max_asset_id
          from synergen.sa_asset
         where plant = l_plant
           and created_by = 'MIGRATED'
           and asset_id > '100000010000000';
      
        l_max_asset_id      := l_max_asset_id + 1;
        l_asset_record_type := 'I';
      
        insert into synergen.sa_asset
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
           last_update_user,
           last_update_date,
           asset_segment1,
           asset_segment2,
           asset_segment3,
           asset_segment5)
        values
          (l_plant,
           mtr.acct_no, -- acct_id in CCB
           mtr.meter_no,
           mtr.read_dttm, -- install dt in function
           mtr.read_dttm, -- install dt in function
           'ACTIVE',
           l_asset_record_type,
           l_max_asset_id, -- asset generated
           '1I01',
           '1I00',
           'METER, KILOWATT HOUR',
           '',
           'ASSET',
           'METER',
           mtr.pole_no, --poleno,
           sysdate,
           'MIGRATED',
           'INTERFACE2',
           sysdate,
           'NET',
           'R',
           '220',
           'N/A');
      
        update synergen.sa_component_id
           set asset_id            = l_max_asset_id,
               asset_record_type   = l_asset_record_type,
               component_id_status = 'INSTALLED',
               last_update_date    = sysdate,
               last_update_user    = 'INTERFACE2'
         where plant = l_plant
           and component_id = mtr.meter_no;
      
        l_update_cnt := SQL%rowcount;
        dbms_output.put_line(l_update_cnt);
      else
        update wam_esb.cr1257_mtr_log
           set note = 'NO UPDATES FOR METER : ' || mtr.meter_no
         where plant = l_plant
           and meter_no = mtr.meter_no;
      end if;
    
    elsif l_status = 'INACTIVE' then
      update synergen.sa_asset
         set asset_status     = 'ACTIVE',
             last_update_date = sysdate,
             last_update_user = 'INTERFACE2'
       where plant = l_plant
         and asset_type = '1I01'
         and manufacturer_part_no = mtr.meter_no;
    
      update synergen.sa_component_id
         set asset_id            = l_asset_id,
             asset_record_type   = l_asset_record_type,
             component_id_status = 'INSTALLED',
             last_update_date    = sysdate,
             last_update_user    = 'INTERFACE2'
       where plant = l_plant
         and component_id = mtr.meter_no;
         
    elsif l_status = 'Duplicate' then
      update wam_esb.cr1257_mtr_log
         set note = 'Duplicate Meter : ' || mtr.meter_no
       where plant = l_plant
         and meter_no = mtr.meter_no;
    end if;
  
    update wam_esb.cr1257_mtr_log
       set status = 'C'
     where plant = l_plant
       and meter_no = mtr.meter_no;
  
  commit;
  end loop;

end;
