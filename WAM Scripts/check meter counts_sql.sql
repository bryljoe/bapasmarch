-- get installed meters in CCB
 select count(1) from wam_esb.cr1257_mtr_log a where plant = '01';

-- get active asset wam meters in WAM 
 select count(1) from synergen.sa_asset where plant = '01' and asset_type = '1I01' and asset_status = 'ACTIVE'; 



------------------------------------------------------------------------------
   
select count(1) from synergen.sa_asset where plant = '01' and asset_type = '1I01'; 
select count(1) from synergen.sa_asset where plant = '01' and last_update_user = 'INTERFACE2';
select count(1)
  from wam_esb.cr1257_mtr_log a
 where exists (select 1
          from sa_asset sa
         where sa.plant = '01'
           and asset_type = '1I01'
           and sa.plant = a.plant
           and a.meter_no = sa.manufacturer_part_no);

select count(1)
  from sa_asset
 where plant = '01'
   and asset_type = '1I01'
   and manufacturer_part_no is not null
   and asset_status = 'ACTIVE';

    select count(1)
   -- into l_mtr_cnt_wam
    from synergen.sa_asset sa
   where plant = '01'
     and asset_type = '1I01'
     and asset_status = 'ACTIVE';


select count(1)
  from wam_esb.cr1257_mtr_log a
 where a.plant = '01'
   and not exists (select 1
          from synergen.sa_asset b
         where asset_type = '1I01'
           and a.plant = b.plant
           and a.meter_no = b.manufacturer_part_no)
   and not exists (select 1
          from synergen.sa_component_id c
         where a.plant = c.plant
           and a.meter_no = c.component_id);
  
 
