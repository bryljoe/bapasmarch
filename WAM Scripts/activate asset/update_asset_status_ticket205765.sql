update sa_asset
   set asset_status = 'ACTIVE'
 where plant = '01'
   and asset_record_type = 'G'
   and asset_id = '100000002145923';

commit;
