
update synergen.sa_asset
   set asset_status = 'ACTIVE'
 where plant = '03'
   and asset_status = 'INACTIVE'
   and asset_id in ('100000000196190',
                    '100000000196191',
                    '100000000196192',
                    '100000000196194',
                    '100000000062191');

commit;