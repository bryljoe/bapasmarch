update synergen.sa_asset 
   set asset_status = 'ACTIVE'
 where plant = '03' 
   and asset_record_type = 'G'
   and asset_id in ('100000000006118','100000004356708','100000004362329')
   and asset_status = 'INACTIVE';
   
commit;