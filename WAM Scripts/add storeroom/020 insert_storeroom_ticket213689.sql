insert into synergen.sa_storeroom
  (plant,
   stock_code,
   storeroom,
   storeroom_status,
   inventory_quantity,
   average_unit_price,
   standard_price,
   stock_type,
   created_by,
   created_date)
  select plant,
         stock_code,
         'S28',
         'ACTIVE',
         1000,
         100,
         100,
         'INVENTORY',
         'INTERFACE',
         sysdate
    from synergen.sa_catalog
   where plant = '06'
     and catalog_status = 'ACTIVE'
     and stock_code in ('0165378',
                        '0166399',
                        '0166390',
                        '0166393',
                        '0166394',
                        '0166398',
                        '0165377',
                        '0166392',
                        '0166395',
                        '0166396',
                        '0166401',
                        '0166397',
                        '0165101',
                        '0091641',
                        '0165375',
                        '0165383',
                        '0166391',
                        '0166402',
                        '0166400',
                        '0166412');

commit;