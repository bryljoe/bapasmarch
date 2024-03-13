
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
     and stock_code in ('0165381',
                        '0165382',
                        '0165384',
                        '0165421',
                        '0165390',
                        '0165391',
                        '0165380',
                        '0165376',
                        '0165386');

commit;
