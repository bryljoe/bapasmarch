 update synergen.sa_asset 
   set asset_status = 'ACTIVE'
 where plant = '03' 
   and asset_record_type = 'G'
   and asset_id in ('100000000098202','100000000250031','100000000250032','100000000250033')
   and asset_status = 'INACTIVE';
   
commit;