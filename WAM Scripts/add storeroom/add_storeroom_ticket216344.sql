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
         'D33',
         'ACTIVE',
         1000,
         100,
         100,
         'INVENTORY',
         'INTERFACE',
         sysdate
    from synergen.sa_catalog
   where plant = '01'
     and catalog_status = 'ACTIVE'
     and stock_code = '0166836';

commit;