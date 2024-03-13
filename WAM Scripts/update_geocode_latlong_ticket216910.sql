update sa_asset
   set point_id          = '0102010',
       gis_gps_latitude  = '7.0938848030165',
       gis_gps_longitude = '125.49310259036'
 where plant = '01'
   and asset_id in ('100000000987885', '100000003002975');

commit;