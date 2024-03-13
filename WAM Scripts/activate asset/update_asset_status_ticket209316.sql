update synergen.sa_asset 
   set asset_status = 'ACTIVE'
 where plant = '03' 
   and asset_id = '100000000017896' 
   and asset_status = 'INACTIVE';
   
 commit;
   