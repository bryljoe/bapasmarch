update sa_asset
   set specification_no = 'S00000P25C'
 where plant = '01'
   and asset_id = '100000000073116'
   and asset_record_type = 'G';

commit;
