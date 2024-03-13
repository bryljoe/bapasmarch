create or replace function tran_numbers_lez return number is

  l_tran_no number;
begin
  select cs.payment_tran_numbers.nextval@maliputo.aboitiz.net
    into l_tran_no
    from dual;

  return l_tran_no;

end;
