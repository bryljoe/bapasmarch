update synergen.sa_asset 
   set asset_status = 'ACTIVE'
 where plant = '03' 
   and asset_record_type = 'G'
   and asset_id in ('100000000082049','100000000321130')
   and asset_status = 'INACTIVE';
   
commit;

