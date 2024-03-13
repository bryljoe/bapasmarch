create or replace function batch_numbers_vec return number is

  l_batch_no number;
begin
  select cs.batch_numbers.nextval@tamarong.aboitiz.net
    into l_batch_no
    from dual;

  return l_batch_no;

end;
/
