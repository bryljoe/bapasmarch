update synergen.sa_asset 
   set asset_status = 'ACTIVE'
 where plant = '03' 
   and asset_record_type = 'G'
   and asset_id = '100000000028855'
   and asset_status = 'INACTIVE';
   
commit;
