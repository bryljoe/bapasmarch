-- script 2 to execute in wam_esb
declare
  l_plant             varchar2(10) := '01';
  l_asset_id          synergen.sa_asset.asset_id%type;
  l_asset_record_type synergen.sa_asset.asset_record_type%type;
  l_mtr               varchar2(20);
  l_mtr_cnt           number;
begin
  for asset in (select plant,
                       asset_record_type,
                       asset_id,
                       asset_type,
                       asset_desc,
                       last_update_date,
                       asset_status,
                       point_id,
                       creation_date,
                       attribute3,
                       last_update_user,
                       created_by,
                       manufacturer_part_no
                  from synergen.sa_asset
                 where plant = l_plant
                   and asset_type = '1I01'
                   and asset_status = 'ACTIVE') loop
  
    -- checked if data is in temporary table
    select count(1)
      into l_mtr_cnt
      from wam_esb.cr1257_mtr_log cml
     where cml.plant = asset.plant
       and cml.meter_no = asset.manufacturer_part_no;
  
    if l_mtr_cnt = 0 then
      update synergen.sa_asset
         set asset_status     = 'INACTIVE',
             last_update_date = sysdate,
             last_update_user = 'INTERFACE2'
       where plant = asset.plant
         and asset_type = '1I01'
         and asset_id = asset.asset_id
         and asset_record_type = asset.asset_record_type
         and manufacturer_part_no = asset.manufacturer_part_no;
    
      update synergen.sa_component_id
         set asset_id            = '',
             asset_record_type   = '',
             component_id_status = 'IN STORES', -- disassociate asset_id, asset_record_type
             last_update_date    = sysdate,
             last_update_user    = 'INTERFACE2'
       where plant = asset.plant
         and component_id = asset.manufacturer_part_no;
    end if;
  
  commit;
  end loop;

end;
