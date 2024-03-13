update synergen.sa_asset 
   set asset_status = 'ACTIVE'
 where plant = '03' 
   and asset_record_type = 'G'
   and asset_id = '100000000077110'
   and asset_status = 'INACTIVE';
   
commit;