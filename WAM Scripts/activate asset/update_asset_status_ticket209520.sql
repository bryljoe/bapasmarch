update sa_asset
   set asset_status = 'ACTIVE'
 where plant = '03'
   and asset_status = 'PLANNED'
   and asset_id in ('100000005235194',
                    '100000005235001',
                    '100000005235000',
                    '100000005235002',
                    '100000005235003',
                    '100000005235004',
                    '100000005235005',
                    '100000005235006',
                    '100000005235007',
                    '100000005235008',
                    '100000005235009');

commit;