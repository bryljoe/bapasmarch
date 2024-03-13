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
  select plant, stock_code, 'V53', 'ACTIVE', 1000, 100, 100, 'INVENTORY',         'INTERFACE',
         sysdate
    from synergen.sa_catalog
   where plant = '03'
     and catalog_status = 'ACTIVE'
     and stock_code in ('0165111', '0165113', '0165112');

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
  select plant, stock_code, 'D33', 'ACTIVE', 1000, 100, 100, 'INVENTORY',         'INTERFACE',
         sysdate
    from synergen.sa_catalog
   where plant = '01'
     and catalog_status = 'ACTIVE'
     and stock_code in ('0165111', '0165113', '0165112');

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
  select plant, stock_code, 'C28', 'ACTIVE', 1000, 100, 100, 'INVENTORY',         'INTERFACE',
         sysdate
    from synergen.sa_catalog
   where plant = '02'
     and catalog_status = 'ACTIVE'
     and stock_code in ('0165111', '0165113', '0165112');

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
  select plant, stock_code, 'S28', 'ACTIVE', 1000, 100, 100, 'INVENTORY',         'INTERFACE',
         sysdate
    from synergen.sa_catalog
   where plant = '06'
     and catalog_status = 'ACTIVE'
     and stock_code in ('0165111', '0165113', '0165112');


commit;