update synergen.sa_asset
   set asset_status = 'ACTIVE'
 where plant = '01'
   and asset_record_type = 'G'
   and asset_id in ('100000001201663',
                    '100000001201664',
                    '100000001201665',
                    '100000001201666');


commit;