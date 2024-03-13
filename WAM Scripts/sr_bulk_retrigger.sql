declare
  l_found number;
begin

  for wo_fa in (with wo_sr as
                   (select sr.plant,
                          wo.work_order_no,
                          wo.work_status,
                          sr.fa_id
                     from synergen.sa_service_request sr,
                          synergen.sa_work_order      wo
                    where sr.plant = wo.plant
                      and sr.work_order_no = wo.work_order_no
                      and wo.work_status = 'ACTIVE'),
                  fa as
                   (select fa_dlp.fa_id, fa_dlp.fa_ext_id
                     from cisadm.ci_fa@ccbprod.dlp.apd.com.ph fa_dlp
                   union all
                   select fa_vec.fa_id, fa_vec.fa_ext_id
                     from cisadm.ci_fa@ccbprod.vec.apd.com.ph fa_vec
                   union all
                   select fa_sez.fa_id, fa_sez.fa_ext_id
                     from cisadm.ci_fa@ccbprod.sez.apd.com.ph fa_sez
                   union all
                   select fa_clp.fa_id, fa_clp.fa_ext_id
                     from cisadm.ci_fa@ccbprod.clp.apd.com.ph fa_clp)
                  select a.plant,
                         a.work_order_no,
                         b.fa_id,
                         a.fa_id fa_ext_id
                    from wo_sr a, fa b
                   where a.fa_id = b.fa_ext_id)
  
   loop
    begin
      select 1
        into l_found
        from (select fa_id
                from cisadm.ci_fa_char@ccbprod.dlp.apd.com.ph fchr
               where char_type_cd = 'CM-WONUM'
              union all
              select fa_id
                from cisadm.ci_fa_char@ccbprod.vec.apd.com.ph fchr
               where char_type_cd = 'CM-WONUM'
              union all
              select fa_id
                from cisadm.ci_fa_char@ccbprod.sez.apd.com.ph fchr
               where char_type_cd = 'CM-WONUM'
              union all
              select fa_id
                from cisadm.ci_fa_char@ccbprod.clp.apd.com.ph fchr
               where char_type_cd = 'CM-WONUM') a
       where a.fa_id = wo_fa.fa_id;
    
    exception
      when no_data_found then
        l_found := 0;
      when too_many_rows then
        l_found := 1;
    end;
  
    if l_found = 0 then
      update synergen.sa_work_order
         set work_status = 'ACTIVE'
       where plant = wo_fa.plant
         and work_status = 'ACTIVE'
         and work_order_no = wo_fa.work_order_no;
    end if;
  
  end loop;
  commit;
end;
