declare
  l_plant     varchar2(10) := '02';
  l_storeroom varchar2(20) := 'C28';
  l_store_cnt number;
  l_cat_cnt   number;
begin
  for st in (select a.stock_code,
                    a.stock_desc,
                    a.uom,
                    sum(a.inventory_quantity) inventory_quantity,
                    max(a.avg_price) avg_price
               from wam_esb.temp_ticket211767 a
              where plant = l_plant
              group by a.stock_code, a.stock_desc, a.uom) loop
  
    -- check if catalog exists in wam
    select count(1)
      into l_cat_cnt
      from synergen.sa_catalog
     where plant = l_plant
       and stock_code = st.stock_code;
  
    if l_cat_cnt > 0 then
      -- check if storeroom exists in wam
      select count(1)
        into l_store_cnt
        from synergen.sa_storeroom
       where plant = l_plant
         and stock_code = st.stock_code
         and storeroom = l_storeroom;
    
      if l_store_cnt > 0 then
        update synergen.sa_storeroom
           set inventory_quantity = st.inventory_quantity,
               average_unit_price = st.avg_price,
               standard_price     = st.avg_price
         where plant = l_plant
           and stock_code = st.stock_code
           and storeroom_status = 'ACTIVE';
      else
        insert into synergen.sa_storeroom
          (plant,
           stock_code,
           storeroom,
           storeroom_status,
           inventory_quantity,
           average_unit_price,
           standard_price,
           stock_type)
        values
          (l_plant,
           st.stock_code,
           l_storeroom,
           'ACTIVE',
           st.inventory_quantity,
           st.avg_price,
           st.avg_price,
           'INVENTORY');
      
      end if;
    else
      insert into synergen.sa_catalog
        (plant,
         stock_code,
         stock_type,
         stock_desc,
         capital_ind,
         do_not_substitute_ind,
         unit_of_issue,
         unit_of_purchase,
         created_date,
         bom_ind,
         created_by,
         restricted_issue_ind,
         catalog_status,
         quality_item_ind)
      values
        (l_plant,
         st.stock_code,
         'INVENTORY',
         st.stock_desc,
         'N',
         'N',
         st.uom,
         st.uom,
         sysdate,
         '',
         '',
         'N',
         'ACTIVE',
         'N');
    
      insert into synergen.sa_storeroom
        (plant,
         stock_code,
         storeroom,
         storeroom_status,
         inventory_quantity,
         average_unit_price,
         standard_price,
         stock_type)
      values
        (l_plant,
         st.stock_code,
         l_storeroom,
         'ACTIVE',
         st.inventory_quantity,
         st.avg_price,
         st.avg_price,
         'INVENTORY');
    
    end if;
    commit;
  end loop;

end;
