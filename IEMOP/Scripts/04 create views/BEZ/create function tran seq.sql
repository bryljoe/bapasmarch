create or replace function tran_numbers_bez return number is

  l_tran_no number;
begin
  select cs.payment_tran_numbers.nextval@dalag.aboitiz.net
    into l_tran_no
    from dual;

  return l_tran_no;

end;
