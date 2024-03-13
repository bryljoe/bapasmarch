create or replace trigger collection_files_trg before
  insert on collection_files
  for each row
  when(new.hdr_id is null)
begin
  select collection_files_seq.nextval
  into :new.hdr_id
  from dual;

exception
  when others then
    raise_application_error(-20001, sqlerrm);
end;
