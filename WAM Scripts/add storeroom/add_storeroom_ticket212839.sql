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
   created_date
)
  select plant, stock_code, 'D33', 'ACTIVE', 1000, 100, 100, 'INVENTORY','INTERFACE',sysdate
    from synergen.sa_catalog
   where plant = '01'
     and catalog_status = 'ACTIVE'
     and stock_code in ('0166481','0166111','0165595');
      
update synergen.sa_storeroom
   set inventory_quantity = 1000,
       average_unit_price = 100,
       standard_price    = 100
 where plant = '01'
   and storeroom_status = 'ACTIVE'
   and stock_code in ('0166293','0166422','0166423','0166424','0166425');
 
 update synergen.sa_catalog
    set stock_type = 'INVENTORY',
        catalog_status = 'ACTIVE'
  where plant = '01'
    and stock_code = '0065943';
    
commit;