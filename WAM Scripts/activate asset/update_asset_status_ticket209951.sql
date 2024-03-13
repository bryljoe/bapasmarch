update synergen.sa_asset 
   set asset_status = 'ACTIVE'
 where plant = '01' 
   and asset_id = '100000000712032' 
   and asset_status = 'INACTIVE';
   
 commit;
   