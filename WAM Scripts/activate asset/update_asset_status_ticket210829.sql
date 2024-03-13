 update synergen.sa_asset 
   set asset_status = 'ACTIVE'
 where plant = '01' 
   and asset_record_type = 'G'
   and asset_id in ('100000000080181','100000000216295','100000000270647')
   and asset_status = 'INACTIVE';
   
commit;