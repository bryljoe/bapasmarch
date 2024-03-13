update sa_sequence_numbers
   set sequence_no = 100000003000000
where table_name = 'ASSET'
  and plant = '01';
  
commit;