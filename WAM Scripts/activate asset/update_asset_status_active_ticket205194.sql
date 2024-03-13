update sa_asset
   set asset_status = 'ACTIVE'
 where plant = '01'
   and asset_id in ('100000000076909',
                    '100000000234940',
                    '100000000081151',
                    '100000000170554');
            
                    
commit;