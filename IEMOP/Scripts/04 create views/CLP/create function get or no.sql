create or replace function get_or_no_clp(p_site_code in varchar2)
  return number as

  --pragma autonomous_transaction;
  l_or_no        number(10);
  l_last_3_digit varchar2(3);
  l_seq_no       number;
  l_errfound     exception;
begin
    -- Official Receipt
    begin
      select seq.seq_no, seq.last_3_digit
        into l_seq_no, l_last_3_digit
        from cs.pop_sites_tin@molmol.aboitiz.net tin,
             cs.pop_sites_seq@molmol.aboitiz.net seq
       where tin.last_3_digit = seq.last_3_digit
         and tin.site_code = p_site_code
         for update;

      l_or_no := l_seq_no;
    exception
      when no_data_found then
        l_or_no := -2;
    end;

    if l_or_no > 0 then
      update cs.pop_sites_seq@molmol.aboitiz.net
         set seq_no = seq_no + 1
       where last_3_digit = l_last_3_digit;

      insert into cs.used_or_numbers@molmol.aboitiz.net
        (or_no, used_by, site_code, receipt_type)
      values
        (l_or_no, user, p_site_code, 'OR');

    end if;

  -- commit;
  return l_or_no;

exception
  when l_errfound then
    return l_or_no;

end get_or_no_clp;
