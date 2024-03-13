update synergen.sa_asset 
   set asset_status = 'ACTIVE'
 where plant = '01' 
   and asset_id in ('100000000738899','100000000167493')
   and asset_status = 'INACTIVE';
   
 commit;