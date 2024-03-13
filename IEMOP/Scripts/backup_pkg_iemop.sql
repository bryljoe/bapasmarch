create or replace package body iemop_pkg is

  function hex_to_decimal(p_hex_str in varchar2) return number as
    v_dec number;
    v_hex varchar2(16) := '0123456789ABCDEF';
  begin
    v_dec := 0;
    for indx in 1 .. length(p_hex_str) loop
      v_dec := v_dec * 16 + instr(v_hex, upper(substr(p_hex_str, indx, 1))) - 1;
    end loop;
    return v_dec;
  end hex_to_decimal;

  function get_batch_no(p_du_cd in varchar2) return number as
    l_batch_no number;
  begin
    if p_du_cd = 'VEC' then
      l_batch_no := batch_numbers_vec;
    elsif p_du_cd = 'DLP' then
      l_batch_no := batch_numbers_dlp;
    elsif p_du_cd = 'SEZ' then
      l_batch_no := batch_numbers_sez;
    elsif p_du_cd = 'CLP' then
      l_batch_no := batch_numbers_clp;
    elsif p_du_cd = 'BEZ' then
      l_batch_no := batch_numbers_bez;
    elsif p_du_cd = 'LEZ' then
      l_batch_no := batch_numbers_lez;
    elsif p_du_cd = 'MEZ' then
      l_batch_no := batch_numbers_mez;
    end if;
  
    return l_batch_no;
  end;

  function get_tran_no(p_du_cd in varchar2) return number as
    l_tran_no number;
  begin
    if p_du_cd = 'VEC' then
      l_tran_no := tran_numbers_vec;
    elsif p_du_cd = 'DLP' then
      l_tran_no := tran_numbers_dlp;
    elsif p_du_cd = 'SEZ' then
      l_tran_no := tran_numbers_sez;
    elsif p_du_cd = 'CLP' then
      l_tran_no := tran_numbers_clp;
    elsif p_du_cd = 'BEZ' then
      l_tran_no := tran_numbers_bez;
    elsif p_du_cd = 'LEZ' then
      l_tran_no := tran_numbers_lez;
    elsif p_du_cd = 'MEZ' then
      l_tran_no := tran_numbers_mez;
    end if;
  
    return l_tran_no;
  end;

  /*function get_batch_tran_no(p_tran_type in varchar2, p_du_cd in varchar2)
    return number as
    --l_tran_no number;
    l_return number;
  begin
    if p_tran_type = 'BATCH' then
      if p_du_cd = 'VEC' then
        l_return := batch_numbers_vec;
      elsif p_du_cd = 'DLP' then
        l_return := batch_numbers_dlp;
      elsif p_du_cd = 'SEZ' then
        l_return := batch_numbers_sez;
      elsif p_du_cd = 'CLP' then
        l_return := batch_numbers_clp;
      elsif p_du_cd = 'BEZ' then
        l_return := batch_numbers_bez;
      elsif p_du_cd = 'LEZ' then
        l_return := batch_numbers_lez;
      end if;
    
    elsif p_tran_type = 'TRAN' then
    
      if p_du_cd = 'VEC' then
        l_return := tran_numbers_vec;
      elsif p_du_cd = 'DLP' then
        l_return := tran_numbers_dlp;
      elsif p_du_cd = 'SEZ' then
        l_return := tran_numbers_sez;
      elsif p_du_cd = 'CLP' then
        l_return := tran_numbers_clp;
      elsif p_du_cd = 'BEZ' then
        l_return := tran_numbers_bez;
      elsif p_du_cd = 'LEZ' then
        l_return := tran_numbers_lez;
      end if;
    end if;
  
    return l_return;
  end;*/

  procedure cancel_file(p_hdr_id in number, p_du_cd in varchar2) as
    l_errmsg  varchar2(3000);
    l_errline number;
  
  begin
    l_errline := 10;
    update collection_files
       set status = 'C'
     where hdr_id = p_hdr_id
       and du_cd = p_du_cd;
  
    commit;
  exception
    when others then
      l_errmsg := 'Error in CANCEL_FILE @ line : ' || to_char(l_errline) || ' ' ||
                  sqlerrm;
      rollback;
      app_error_pkg.log_error(p_module           => 'IEMOP',
                              p_action           => 'CANCEL_FILE',
                              p_oracle_error_msg => sqlerrm,
                              p_custom_error_msg => l_errmsg,
                              p_table_name       => 'collection_files',
                              p_pk1              => '',
                              p_raise_error      => 0);
    
      raise_application_error(-20040, l_errmsg);
  end;

  procedure upload_data_transactions(p_batch_no            in number,
                                     p_du_cd               in varchar2,
                                     p_tran_no             out number,
                                     p_iemop_data_rec_type in iemop_data_rec_type) as
  
    --l_or_no    number;
    l_tran_no  number;
    l_errfound exception;
    l_errline  number;
    l_errmsg   varchar2(3000);
  begin
    l_tran_no := iemop_pkg.get_tran_no(p_du_cd => p_du_cd);
  
    --l_or_no := cs_singleacct_pkg.get_or_no('1', l_tran_no);
    l_errline := 10;
    insert into payment_transactions_tmp
      (tran_no,
       last_name,
       first_name,
       mid_name,
       address,
       or_no,
       or_date,
       or_status,
       remarks,
       bank_ref_no,
       batch_no,
       payer_id,
       payer_type,
       posted,
       cancel_reason,
       or_count,
       du_cd)
    values
      (l_tran_no,
       p_iemop_data_rec_type.last_name,
       p_iemop_data_rec_type.first_name,
       p_iemop_data_rec_type.mid_name,
       p_iemop_data_rec_type.address,
       p_iemop_data_rec_type.or_no,
       p_iemop_data_rec_type.or_date,
       'ISSUED',
       '',
       '',
       p_batch_no,
       trim(p_iemop_data_rec_type.payer_id),
       'CUSTOMER',
       '0',
       '',
       '1',
       p_du_cd)
    returning tran_no into l_tran_no;
  
    --insert paid_items
    begin
      if p_du_cd = 'VEC' then
      
        l_errline := 20;
        insert into paid_items_tmp
          (tran_no, seq_no, pay_code, amount_credit)
        values
          (l_tran_no, 1, 'AR', p_iemop_data_rec_type.sum_of_vatable_sales);
      
        l_errline := 30;
        insert into paid_items_tmp
          (tran_no, seq_no, pay_code, amount_credit)
        values
          (l_tran_no,
           2,
           'AR-VAT',
           p_iemop_data_rec_type.sum_of_vat_on_sales);
      
        l_errline := 40;
        insert into paid_items_tmp
          (tran_no, seq_no, pay_code, amount_credit)
        values
          (l_tran_no,
           3,
           'PPWTAX',
           p_iemop_data_rec_type.sum_of_witholding_tax);
      
        l_errline := 50;
        insert into paid_items_tmp
          (tran_no, seq_no, pay_code, amount_credit)
        values
          (l_tran_no,
           4,
           'VAT-0-RATED',
           (p_iemop_data_rec_type.sum_of_zero_rated_sales +
           p_iemop_data_rec_type.sum_of_zero_rated_ecozone));
      
        l_errline := 60;
        insert into paid_items_tmp
          (tran_no, seq_no, pay_code, amount_credit)
        values
          (l_tran_no, 5, 'NON-VAT-SALES', 0);
      
      elsif p_du_cd in ('DLP', 'SEZ', 'MEZ', 'BEZ', 'CLP', 'LEZ') then
      
        l_errline := 70;
        insert into paid_items_tmp
          (tran_no, seq_no, pay_code, amount_credit)
        values
          (l_tran_no,
           1,
           'VAT-SALES',
           p_iemop_data_rec_type.sum_of_vatable_sales);
      
        l_errline := 80;
        insert into paid_items_tmp
          (tran_no, seq_no, pay_code, amount_credit)
        values
          (l_tran_no, 2, 'NON-VAT-SALES', 0.00);
      
        l_errline := 90;
        insert into paid_items_tmp
          (tran_no, seq_no, pay_code, amount_credit)
        values
          (l_tran_no,
           3,
           'VAT-0-RATED',
           p_iemop_data_rec_type.sum_of_zero_rated_sales);
      
        l_errline := 100;
        insert into paid_items_tmp
          (tran_no, seq_no, pay_code, amount_credit)
        values
          (l_tran_no,
           4,
           'VAT-0-RATED',
           p_iemop_data_rec_type.sum_of_zero_rated_ecozone);
      
        l_errline := 110;
        insert into paid_items_tmp
          (tran_no, seq_no, pay_code, amount_credit)
        values
          (l_tran_no, 5, 'UC-FIT_ALL', 0.00);
      
        l_errline := 120;
        insert into paid_items_tmp
          (tran_no, seq_no, pay_code, amount_credit)
        values
          (l_tran_no,
           6,
           'AR-VAT',
           p_iemop_data_rec_type.sum_of_vat_on_sales);
      
        l_errline := 130;
        insert into paid_items_tmp
          (tran_no, seq_no, pay_code, amount_credit)
        values
          (l_tran_no, 7, 'BIR2306', 0.00);
      
        l_errline := 140;
        insert into paid_items_tmp
          (tran_no, seq_no, pay_code, amount_credit)
        values
          (l_tran_no,
           8,
           'PPWTAX',
           p_iemop_data_rec_type.sum_of_witholding_tax);
      
      elsif p_du_cd = 'LEZ' then
      
        l_errline := 70;
        insert into paid_items_tmp
          (tran_no, seq_no, pay_code, amount_credit)
        values
          (l_tran_no, 1, 'AR', p_iemop_data_rec_type.sum_of_vatable_sales);
      
        l_errline := 80;
        insert into paid_items_tmp
          (tran_no, seq_no, pay_code, amount_credit)
        values
          (l_tran_no,
           2,
           'AR',
           p_iemop_data_rec_type.sum_of_zero_rated_sales);
      
        l_errline := 90;
        insert into paid_items_tmp
          (tran_no, seq_no, pay_code, amount_credit)
        values
          (l_tran_no,
           3,
           'PPWTAX',
           p_iemop_data_rec_type.sum_of_witholding_tax);
      
        l_errline := 100;
        insert into paid_items_tmp
          (tran_no, seq_no, pay_code, amount_credit)
        values
          (l_tran_no,
           4,
           'AR-VAT',
           p_iemop_data_rec_type.sum_of_vat_on_sales);
      end if;
    
      p_tran_no := l_tran_no;
    exception
      when others then
        l_errmsg := 'Error in UPLOAD_DATA_TRANSACTIONS @ line : ' ||
                    to_char(l_errline) || ' ' || sqlerrm;
        rollback;
        app_error_pkg.log_error(p_module           => 'IEMOP Sale of Energy',
                                p_action           => 'UPLOAD_DATA_TRANSACTIONS',
                                p_oracle_error_msg => sqlerrm,
                                p_custom_error_msg => l_errmsg,
                                p_table_name       => 'paid_items_tmp',
                                p_pk1              => l_tran_no,
                                p_raise_error      => 0);
      
        raise_application_error(-20000, l_errmsg);
    end;
  
    -- insert paid acct facts
    begin
      l_errline := 150;
      insert into paid_acct_facts_tmp
        (tran_no,
         acct_no,
         acct_status,
         schedule,
         area_code,
         government_code,
         tin,
         cfnp_required_amt,
         last_date_paid,
         last_amount_paid,
         apply_for_recon)
      values
        (l_tran_no,
         trim(p_iemop_data_rec_type.payer_id),
         null,
         null,
         null,
         null,
         replace(trim(p_iemop_data_rec_type.tin), '-', ''),
         null,
         null,
         null,
         0);
    exception
      when others then
        l_errmsg := 'Error in UPLOAD_DATA_TRANSACTIONS @ line : ' ||
                    to_char(l_errline) || ' ' || sqlerrm;
        rollback;
        app_error_pkg.log_error(p_module           => 'IEMOP Sale of Energy',
                                p_action           => 'UPLOAD_DATA_TRANSACTIONS',
                                p_oracle_error_msg => sqlerrm,
                                p_custom_error_msg => l_errmsg,
                                p_table_name       => 'paid_acct_facts_tmp',
                                p_pk1              => l_tran_no,
                                p_raise_error      => 0);
      
        raise_application_error(-20000, l_errmsg);
    end;
  
    -- insert form_of_payment 
    begin
      l_errline := 160;
      insert into forms_of_payment_tmp
        (tran_no, seq_no, payment_type, amount_paid)
      values
        (l_tran_no, 1, 'CASH', p_iemop_data_rec_type.sum_of_total);
    
    exception
      when others then
        l_errmsg := 'Error in UPLOAD_DATA_TRANSACTIONS @ line : ' ||
                    to_char(l_errline) || ' ' || sqlerrm;
        rollback;
        app_error_pkg.log_error(p_module           => 'IEMOP Sale of Energy',
                                p_action           => 'UPLOAD_DATA_TRANSACTIONS',
                                p_oracle_error_msg => sqlerrm,
                                p_custom_error_msg => l_errmsg,
                                p_table_name       => 'forms_of_payment_tmp',
                                p_pk1              => l_tran_no,
                                p_raise_error      => 0);
      
        raise_application_error(-20000, l_errmsg);
    end;
  
    -- insert fop_cash
    begin
      l_errline := 170;
      insert into fop_cash_tmp
        (tran_no, seq_no, amount_tendered)
      values
        (l_tran_no, 1, p_iemop_data_rec_type.sum_of_total);
    
    exception
      when others then
        l_errmsg := 'Error in UPLOAD_DATA_TRANSACTIONS @ line : ' ||
                    to_char(l_errline) || ' ' || sqlerrm;
        rollback;
        app_error_pkg.log_error(p_module           => 'IEMOP Sale of Energy',
                                p_action           => 'UPLOAD_DATA_TRANSACTIONS',
                                p_oracle_error_msg => sqlerrm,
                                p_custom_error_msg => l_errmsg,
                                p_table_name       => 'fop_cash_tmp',
                                p_pk1              => l_tran_no,
                                p_raise_error      => 0);
      
        raise_application_error(-20000, l_errmsg);
    end;
  
    -- insert payers_tmp
    begin
      l_errline := 180;
      insert into payers_tmp
        (payer_type,
         payer_id,
         last_name,
         first_name,
         mid_name,
         address,
         du_cd)
      values
        ('CUSTOMER',
         trim(p_iemop_data_rec_type.payer_id),
         p_iemop_data_rec_type.last_name,
         p_iemop_data_rec_type.first_name,
         p_iemop_data_rec_type.mid_name,
         substr(trim(p_iemop_data_rec_type.address), 1, 95),
         p_du_cd);
    
    exception
      when dup_val_on_index then
        l_errmsg := 'Error in UPLOAD_DATA_TRANSACTIONS @ line : ' ||
                    to_char(l_errline) || ' ' || sqlerrm;
        rollback;
        app_error_pkg.log_error(p_module           => 'IEMOP Sale of Energy',
                                p_action           => 'UPLOAD_DATA_TRANSACTIONS',
                                p_oracle_error_msg => sqlerrm,
                                p_custom_error_msg => l_errmsg,
                                p_table_name       => 'payers_tmp',
                                p_pk1              => l_tran_no,
                                p_raise_error      => 0);
      
        raise_application_error(-20000, l_errmsg);
      
      when others then
        l_errmsg := 'Error in UPLOAD_DATA_TRANSACTIONS @ line : ' ||
                    to_char(l_errline) || ' ' || sqlerrm;
        rollback;
        app_error_pkg.log_error(p_module           => 'IEMOP Sale of Energy',
                                p_action           => 'UPLOAD_DATA_TRANSACTIONS',
                                p_oracle_error_msg => sqlerrm,
                                p_custom_error_msg => l_errmsg,
                                p_table_name       => 'payers_tmp',
                                p_pk1              => l_tran_no,
                                p_raise_error      => 0);
      
        raise_application_error(-20000, l_errmsg);
      
    end;
  
    -- insert crc_acct_no_mappings_tmp
    begin
      l_errline := 180;
      insert into crc_acct_no_mappings_tmp
        (crc,
         acct_no,
         acct_status,
         schedule,
         area_code,
         government_code,
         tin,
         cfnp_required_amt,
         last_date_paid,
         last_amount_paid,
         bd_required_amt,
         emp_acct,
         bus_add,
         bus_activity,
         du_cd)
      values
        (trim(p_iemop_data_rec_type.payer_id),
         trim(p_iemop_data_rec_type.payer_id),
         null,
         null,
         null,
         null,
         null,
         null,
         null,
         null,
         null,
         0,
         null,
         substr(trim(p_iemop_data_rec_type.bus_activity), 1, 95),
         p_du_cd);
    
    exception
      when others then
        l_errmsg := 'Error in UPLOAD_DATA_TRANSACTIONS @ line : ' ||
                    to_char(l_errline) || ' ' || sqlerrm;
        rollback;
        app_error_pkg.log_error(p_module           => 'IEMOP Sale of Energy',
                                p_action           => 'UPLOAD_DATA_TRANSACTIONS',
                                p_oracle_error_msg => sqlerrm,
                                p_custom_error_msg => l_errmsg,
                                p_table_name       => 'crc_acct_no_mappings_tmp',
                                p_pk1              => l_tran_no,
                                p_raise_error      => 0);
      
        raise_application_error(-20000, l_errmsg);
    end;
    commit;
  
  end upload_data_transactions;

  procedure upload_collection_batches(p_hdr_id    in number,
                                      p_batch_no  out number,
                                      p_du_cd     in varchar2,
                                      p_iemop_rec in iemop_rec_type) as
  
    l_errmsg  varchar2(3000);
    l_errline number;
    l_hdr_id  number;
    --l_batch_no number;
  begin
  
    p_batch_no := iemop_pkg.get_batch_no(p_du_cd => p_du_cd);
  
    insert into collection_batches_tmp
      (hdr_id,
       batch_no,
       site_code,
       booth,
       teller,
       mode_of_entry,
       created_by,
       created_on)
    values
      (p_hdr_id,
       p_batch_no,
       '1',
       '1',
       nvl(v('APP_USER'), user),
       'ON-LINE',
       nvl(v('APP_USER'), user),
       sysdate)
    returning batch_no into p_batch_no;
  
    --p_batch_no := l_batch_no;
    --p_hdr_id := l_hdr_id;
  
    commit;
  
  exception
    when others then
      l_errmsg := 'Error in UPLOAD_COLLECTION_BATCHES @ line : ' ||
                  to_char(l_errline) || ' ' || sqlerrm;
      rollback;
      app_error_pkg.log_error(p_module           => 'IEMOP',
                              p_action           => 'upload_collection_batches',
                              p_oracle_error_msg => sqlerrm,
                              p_custom_error_msg => l_errmsg,
                              p_table_name       => 'collection_batches_tmp',
                              p_pk1              => '',
                              p_raise_error      => 0);
    
      raise_application_error(-20040, l_errmsg);
    
  end upload_collection_batches;

  procedure upload_or_file(p_file_name in varchar2,
                           p_hdr_id    in out number,
                           p_batch_no  out number,
                           p_tran_no   out number,
                           p_du_cd     in varchar2) as
  
    l_file_name           varchar2(1000);
    v_blob_data           blob;
    v_blob_len            number;
    v_position            number;
    v_raw_chunk           raw(10000);
    v_char                char(1);
    c_chunk_len           number := 1;
    v_line                varchar2(32767) := null;
    v_field_ctr           number := 1;
    l_delimiter           varchar2(1) := ',';
    l_iemop_rec           iemop_rec_type;
    l_iemop_data_rec_type iemop_data_rec_type;
    l_batch_no            number;
    l_hdr_id              number;
    l_tran_no             number;
    l_row_no              number := 1;
    l_errfound            exception;
    l_errline             number;
    l_errmsg              varchar2(3000);
  begin
    l_errline := 10;
    -- read data from apex_application_temp_files
    select blob_content, filename
      into v_blob_data, l_file_name
      from apex_application_temp_files
     where name = p_file_name;
  
    l_errline := 20;
    insert into collection_files
      (du_cd,
       uploaded_by,
       attachment,
       uploaded_on,
       created_by,
       created_on,
       status,
       file_name)
    values
      (p_du_cd,
       nvl(v('APP_USER'), user),
       v_blob_data,
       sysdate,
       nvl(v('APP_USER'), user),
       sysdate,
       'P',
       l_file_name) return hdr_id into l_hdr_id;
  
    p_hdr_id := l_hdr_id;
  
    l_errline  := 30;
    v_blob_len := dbms_lob.getlength(v_blob_data);
    v_position := 1;
    l_errline  := 40;
  
    upload_collection_batches(p_hdr_id    => l_hdr_id,
                              p_batch_no  => l_batch_no,
                              p_du_cd     => p_du_cd,
                              p_iemop_rec => l_iemop_rec);
  
    --read and convert binary to char
    while (v_position <= v_blob_len) loop
      l_errline   := 50;
      v_raw_chunk := dbms_lob.substr(v_blob_data, c_chunk_len, v_position);
      v_char      := chr(hex_to_decimal(rawtohex(v_raw_chunk)));
      v_line      := v_line || v_char;
      v_position  := v_position + c_chunk_len;
      l_errline   := 60;
      -- when a whole line is retrieved
    
      if (v_char = l_delimiter) then
        v_line := replace(replace(replace(v_line, l_delimiter), '"'),
                          chr(10));
        if (l_row_no = 1)
        -- header of the detail records
         then
          null;
        elsif (l_row_no >= 2) -- for the detail records
         then
          l_errline := 70;
          if (v_field_ctr = 1) then
            l_errline                       := 80;
            l_iemop_data_rec_type.last_name := substr(trim(v_line), 1, 99);
          elsif (v_field_ctr = 2) then
            l_errline                        := 90;
            l_iemop_data_rec_type.first_name := substr(trim(v_line), 1, 49);
          elsif (v_field_ctr = 3) then
            l_errline                      := 100;
            l_iemop_data_rec_type.mid_name := substr(trim(v_line), 1, 49);
          elsif (v_field_ctr = 4) then
            l_errline                     := 110;
            l_iemop_data_rec_type.address := substr(trim(v_line), 1, 95);
          elsif (v_field_ctr = 5) then
            l_errline                   := 120;
            l_iemop_data_rec_type.or_no := v_line;
          elsif (v_field_ctr = 6) then
            l_errline                     := 130;
            l_iemop_data_rec_type.or_date := nvl(to_date(v_line, 'YYYYMMDD'),
                                                 sysdate);
          elsif (v_field_ctr = 7) then
            l_errline                      := 140;
            l_iemop_data_rec_type.payer_id := substr(trim(v_line), 1, 20);
          elsif (v_field_ctr = 8) then
            l_errline                                  := 150;
            l_iemop_data_rec_type.sum_of_vatable_sales := to_number(v_line,
                                                                    '9999.99');
          elsif (v_field_ctr = 9) then
            l_errline                                     := 160;
            l_iemop_data_rec_type.sum_of_zero_rated_sales := to_number(v_line,
                                                                       '9999.99');
          elsif (v_field_ctr = 10) then
            l_errline                                       := 170;
            l_iemop_data_rec_type.sum_of_zero_rated_ecozone := to_number(v_line,
                                                                         '9999.99');
          elsif (v_field_ctr = 11) then
            l_errline                                 := 180;
            l_iemop_data_rec_type.sum_of_vat_on_sales := to_number(v_line,
                                                                   '9999.99');
          elsif (v_field_ctr = 12) then
            l_errline                                   := 190;
            l_iemop_data_rec_type.sum_of_witholding_tax := to_number(v_line,
                                                                     '9999.99');
          
          elsif (v_field_ctr = 13) then
            l_errline                 := 200;
            l_iemop_data_rec_type.tin := substr(trim(v_line), 1, 20);
          
          elsif (v_field_ctr = 14) then
            l_errline                          := 210;
            l_iemop_data_rec_type.sum_of_total := to_number(v_line,
                                                            '9999.99');
          
          elsif (v_field_ctr = 15) then
            l_errline                          := 220;
            l_iemop_data_rec_type.bus_activity := substr(trim(v_line),
                                                         1,
                                                         100);
          end if;
        end if;
        v_line      := null;
        v_field_ctr := v_field_ctr + 1;
      end if;
    
      if v_char = chr(10) then
        l_errline := 170;
      
        l_errline := 110;
        if (l_row_no >= 2) then
        
          l_errline := 230;
          if (l_iemop_data_rec_type.payer_id is null) then
            l_errmsg := 'Payer ID cannot be empty. (row: ' || l_row_no || ')';
            raise l_errfound;
            /*l_errline := 150;
            elsif (l_iemop_rec.site_code is null) then
               l_errmsg := 'Site Code cannot be empty! (row: ' || l_row_no || ')';
               raise l_errfound;*/
            /*elsif (l_acu_rec.effdt is null) then
              l_errmsg := 'Effective Date cannot be empty! (row: ' ||
                          l_row_no || ')';
              raise l_errfound;
            elsif (l_acu_rec.char_val is null) then
              l_errmsg := 'Char Val cannot be empty! (row: ' || l_row_no || ')';
              raise l_errfound;
            end if;
            
            l_errline := 150;
            if (v_field_ctr = 5) then
              l_errline                := 160;
              v_line                   := replace(replace(replace(replace(v_line,
                                                                          l_delimiter),
                                                                  '"'),
                                                          chr(13)),
                                                  chr(10));
              l_acu_rec.adhoc_char_val := v_line;
            end if;*/
          end if;
        
          l_errline := 240;
          if (v_field_ctr > 1) then
            /*upload_collection_batches(p_hdr_id    => l_hdr_id,
            p_batch_no  => l_batch_no,
            p_du_cd     => p_du_cd,
            p_iemop_rec => l_iemop_rec);*/
          
            upload_data_transactions(p_batch_no            => l_batch_no,
                                     p_du_cd               => p_du_cd,
                                     p_tran_no             => l_tran_no,
                                     p_iemop_data_rec_type => l_iemop_data_rec_type);
          
          end if;
        end if;
      
        --increment row number
        l_row_no := l_row_no + 1;
      
        -- clear out
        v_field_ctr := 1;
        l_iemop_rec := null;
        v_line      := null;
        /*p_batch_no  := l_batch_no;
        p_tran_no   := l_tran_no;*/
      
      end if;
    end loop;
    p_batch_no := l_batch_no;
    p_tran_no  := l_tran_no;
    delete from apex_application_temp_files where name = p_file_name;
    commit;
  
  exception
    when others then
      l_errmsg := 'Error in UPLOAD_OR_FILE @ line : ' || to_char(l_errline) || ' ' ||
                  sqlerrm;
    
      rollback;
      app_error_pkg.log_error(p_module           => 'IEMOP',
                              p_action           => 'UPLOAD_OR_FILE',
                              p_oracle_error_msg => sqlerrm,
                              p_custom_error_msg => l_errmsg,
                              p_table_name       => 'collection_files',
                              p_pk1              => p_hdr_id,
                              p_raise_error      => 0);
      raise_application_error(-20000, l_errmsg);
    
  end upload_or_file;

  procedure posting_to_ors(p_du_cd in varchar2) as
  
    --l_batch_no number;
    l_schema   varchar2(50);
    l_errmsg  varchar2(3000);
    l_errline number;
    
  begin
    for l_hdr_data in (select hdr_id,
                              du_cd,
                              file_type,
                              file_name,
                              attachment,
                              created_by,
                              created_on,
                              uploaded_by,
                              uploaded_on,
                              status
                         from collection_files
                        where du_cd = p_du_cd
                          and status = 'P') loop
    
      if p_du_cd = 'VEC' then
      
        l_errline := 10;
        insert into cisadm_vec.collection_batches
          (batch_no,
           site_code,
           booth,
           teller,
           mode_of_entry,
           created_by,
           created_on,
           remitted_by,
           remitted_on,
           transmitted_by,
           transmitted_on,
           offline_or_date,
           or_count,
           requested_lt_min,
           granted_lt_min)
          select batch_no,
                 site_code,
                 booth,
                 teller,
                 mode_of_entry,
                 created_by,
                 created_on,
                 remitted_by,
                 remitted_on,
                 transmitted_by,
                 transmitted_on,
                 offline_or_date,
                 or_count,
                 requested_lt_min,
                 granted_lt_min
            from collection_batches_tmp
           where hdr_id = l_hdr_data.hdr_id;
      
        for l_batch_data in (select batch_no, site_code
                               from collection_batches_tmp
                              where hdr_id = l_hdr_data.hdr_id)
        
         loop
          l_errline := 20;
          insert into payment_transactions_vec
            (tran_no,
             last_name,
             first_name,
             mid_name,
             address,
             or_no,
             or_date,
             or_status,
             remarks,
             bank_ref_no,
             batch_no,
             payer_id,
             payer_type,
             posted,
             cancel_reason,
             or_count)
            select tran_no,
                   last_name,
                   first_name,
                   mid_name,
                   address,
                   or_no,
                   or_date,
                   or_status,
                   remarks,
                   bank_ref_no,
                   batch_no,
                   payer_id,
                   payer_type,
                   posted,
                   cancel_reason,
                   or_count
              from payment_transactions_tmp
             where batch_no = l_batch_data.batch_no
               and du_cd = p_du_cd;
        
          for l_tran_data in (select tran_no, payer_id
                                from payment_transactions_tmp
                               where du_cd = p_du_cd) loop
          
            l_errline := 30;
            insert into paid_items_vec
              (tran_no, seq_no, pay_code, amount_credit)
              select tran_no, seq_no, pay_code, amount_credit
                from paid_items_tmp
               where tran_no = l_tran_data.tran_no;
          
            l_errline := 40;
            insert into paid_acct_facts_vec
              (tran_no,
               acct_no,
               acct_status,
               schedule,
               area_code,
               government_code,
               tin,
               cfnp_required_amt,
               last_date_paid,
               last_amount_paid,
               apply_for_recon)
              select tran_no,
                     acct_no,
                     acct_status,
                     schedule,
                     area_code,
                     government_code,
                     tin,
                     cfnp_required_amt,
                     last_date_paid,
                     last_amount_paid,
                     apply_for_recon
                from paid_acct_facts_tmp
               where tran_no = l_tran_data.tran_no;
          
            l_errline := 50;
            insert into forms_of_payment_vec
              (tran_no, seq_no, payment_type, amount_paid)
              select tran_no, seq_no, payment_type, amount_paid
                from forms_of_payment_tmp
               where tran_no = l_tran_data.tran_no;
          
            l_errline := 60;
            insert into fop_cash_vec
              (tran_no, seq_no, amount_tendered)
              select tran_no, seq_no, amount_tendered
                from fop_cash_tmp
               where tran_no = l_tran_data.tran_no;
          
            l_errline := 70;
            insert into payers_vec
              (payer_type,
               payer_id,
               last_name,
               first_name,
               mid_name,
               address)
              select payer_type,
                     payer_id,
                     last_name,
                     first_name,
                     mid_name,
                     address
                from payers_tmp
               where payer_id = l_tran_data.payer_id
                 and du_cd = p_du_cd;
          
            l_errline := 80;
            insert into crc_acct_no_mappings_vec
              (crc,
               acct_no,
               acct_status,
               schedule,
               area_code,
               government_code,
               tin,
               cfnp_required_amt,
               last_date_paid,
               last_amount_paid,
               bd_required_amt,
               emp_acct,
               bus_add,
               bus_activity)
              select crc,
                     acct_no,
                     acct_status,
                     schedule,
                     area_code,
                     government_code,
                     tin,
                     cfnp_required_amt,
                     last_date_paid,
                     last_amount_paid,
                     bd_required_amt,
                     emp_acct,
                     bus_add,
                     bus_activity
                from crc_acct_no_mappings_tmp
               where acct_no = l_tran_data.payer_id
                 and du_cd = p_du_cd;
          end loop;
        end loop;
      
      elsif p_du_cd = 'SEZ' then
      
        l_errline := 90;
        insert into collection_batches_sez
          (batch_no,
           site_code,
           booth,
           teller,
           mode_of_entry,
           created_by,
           created_on,
           remitted_by,
           remitted_on,
           transmitted_by,
           transmitted_on,
           offline_or_date,
           or_count,
           requested_lt_min,
           granted_lt_min)
          select batch_no,
                 site_code,
                 booth,
                 teller,
                 mode_of_entry,
                 created_by,
                 created_on,
                 remitted_by,
                 remitted_on,
                 transmitted_by,
                 transmitted_on,
                 offline_or_date,
                 or_count,
                 requested_lt_min,
                 granted_lt_min
            from collection_batches_tmp
           where hdr_id = l_hdr_data.hdr_id;
      
        for l_batch_data in (select batch_no, site_code
                               from collection_batches_tmp
                              where hdr_id = l_hdr_data.hdr_id)
        
         loop
          l_errline := 100;
          insert into payment_transactions_sez
            (tran_no,
             last_name,
             first_name,
             mid_name,
             address,
             or_no,
             or_date,
             or_status,
             remarks,
             bank_ref_no,
             batch_no,
             payer_id,
             payer_type,
             posted,
             cancel_reason,
             or_count)
            select tran_no,
                   last_name,
                   first_name,
                   mid_name,
                   address,
                   or_no,
                   or_date,
                   or_status,
                   remarks,
                   bank_ref_no,
                   batch_no,
                   payer_id,
                   payer_type,
                   posted,
                   cancel_reason,
                   or_count
              from payment_transactions_tmp
             where batch_no = l_batch_data.batch_no
               and du_cd = p_du_cd;
        
          for l_tran_data in (select tran_no, payer_id
                                from payment_transactions_tmp
                               where du_cd = p_du_cd) loop
          
            l_errline := 110;
            insert into paid_items_sez
              (tran_no, seq_no, pay_code, amount_credit)
              select tran_no, seq_no, pay_code, amount_credit
                from paid_items_tmp
               where tran_no = l_tran_data.tran_no;
          
            l_errline := 120;
            insert into paid_acct_facts_sez
              (tran_no,
               acct_no,
               acct_status,
               schedule,
               area_code,
               government_code,
               tin,
               cfnp_required_amt,
               last_date_paid,
               last_amount_paid,
               apply_for_recon)
              select tran_no,
                     acct_no,
                     acct_status,
                     schedule,
                     area_code,
                     government_code,
                     tin,
                     cfnp_required_amt,
                     last_date_paid,
                     last_amount_paid,
                     apply_for_recon
                from paid_acct_facts_tmp
               where tran_no = l_tran_data.tran_no;
          
            l_errline := 130;
            insert into forms_of_payment_sez
              (tran_no, seq_no, payment_type, amount_paid)
              select tran_no, seq_no, payment_type, amount_paid
                from forms_of_payment_tmp
               where tran_no = l_tran_data.tran_no;
          
            l_errline := 140;
            insert into fop_cash_sez
              (tran_no, seq_no, amount_tendered)
              select tran_no, seq_no, amount_tendered
                from fop_cash_tmp
               where tran_no = l_tran_data.tran_no;
          
            l_errline := 150;
            insert into payers_sez
              (payer_type,
               payer_id,
               last_name,
               first_name,
               mid_name,
               address)
              select payer_type,
                     payer_id,
                     last_name,
                     first_name,
                     mid_name,
                     address
                from payers_tmp
               where payer_id = l_tran_data.payer_id
                 and du_cd = p_du_cd;
          
            l_errline := 160;
            insert into crc_acct_no_mappings_sez
              (crc,
               acct_no,
               acct_status,
               schedule,
               area_code,
               government_code,
               tin,
               cfnp_required_amt,
               last_date_paid,
               last_amount_paid,
               bd_required_amt,
               emp_acct,
               bus_add,
               bus_activity)
              select crc,
                     acct_no,
                     acct_status,
                     schedule,
                     area_code,
                     government_code,
                     tin,
                     cfnp_required_amt,
                     last_date_paid,
                     last_amount_paid,
                     bd_required_amt,
                     emp_acct,
                     bus_add,
                     bus_activity
                from crc_acct_no_mappings_tmp
               where acct_no = l_tran_data.payer_id
                 and du_cd = p_du_cd;
          end loop;
        end loop;
      
      elsif p_du_cd = 'DLP' then
      
        l_errline := 170;
        insert into collection_batches_dlp
          (batch_no,
           site_code,
           booth,
           teller,
           mode_of_entry,
           created_by,
           created_on,
           remitted_by,
           remitted_on,
           transmitted_by,
           transmitted_on,
           offline_or_date,
           or_count,
           requested_lt_min,
           granted_lt_min)
          select batch_no,
                 site_code,
                 booth,
                 teller,
                 mode_of_entry,
                 created_by,
                 created_on,
                 remitted_by,
                 remitted_on,
                 transmitted_by,
                 transmitted_on,
                 offline_or_date,
                 or_count,
                 requested_lt_min,
                 granted_lt_min
            from collection_batches_tmp
           where hdr_id = l_hdr_data.hdr_id;
      
        for l_batch_data in (select batch_no, site_code
                               from collection_batches_tmp
                              where hdr_id = l_hdr_data.hdr_id)
        
         loop
          l_errline := 180;
          insert into payment_transactions_dlp
            (tran_no,
             last_name,
             first_name,
             mid_name,
             address,
             or_no,
             or_date,
             or_status,
             remarks,
             bank_ref_no,
             batch_no,
             payer_id,
             payer_type,
             posted,
             cancel_reason,
             or_count)
            select tran_no,
                   last_name,
                   first_name,
                   mid_name,
                   address,
                   or_no,
                   or_date,
                   or_status,
                   remarks,
                   bank_ref_no,
                   batch_no,
                   payer_id,
                   payer_type,
                   posted,
                   cancel_reason,
                   or_count
              from payment_transactions_tmp
             where batch_no = l_batch_data.batch_no
               and du_cd = p_du_cd;
        
          for l_tran_data in (select tran_no, payer_id
                                from payment_transactions_tmp
                               where du_cd = p_du_cd) loop
          
            l_errline := 190;
            insert into paid_items_dlp
              (tran_no, seq_no, pay_code, amount_credit)
              select tran_no, seq_no, pay_code, amount_credit
                from paid_items_tmp
               where tran_no = l_tran_data.tran_no;
          
            l_errline := 200;
            insert into paid_acct_facts_dlp
              (tran_no,
               acct_no,
               acct_status,
               schedule,
               area_code,
               government_code,
               tin,
               cfnp_required_amt,
               last_date_paid,
               last_amount_paid,
               apply_for_recon)
              select tran_no,
                     acct_no,
                     acct_status,
                     schedule,
                     area_code,
                     government_code,
                     tin,
                     cfnp_required_amt,
                     last_date_paid,
                     last_amount_paid,
                     apply_for_recon
                from paid_acct_facts_tmp
               where tran_no = l_tran_data.tran_no;
          
            l_errline := 210;
            insert into forms_of_payment_dlp
              (tran_no, seq_no, payment_type, amount_paid)
              select tran_no, seq_no, payment_type, amount_paid
                from forms_of_payment_tmp
               where tran_no = l_tran_data.tran_no;
          
            l_errline := 220;
            insert into fop_cash_dlp
              (tran_no, seq_no, amount_tendered)
              select tran_no, seq_no, amount_tendered
                from fop_cash_tmp
               where tran_no = l_tran_data.tran_no;
          
            l_errline := 230;
            insert into payers_dlp
              (payer_type,
               payer_id,
               last_name,
               first_name,
               mid_name,
               address)
              select payer_type,
                     payer_id,
                     last_name,
                     first_name,
                     mid_name,
                     address
                from payers_tmp
               where payer_id = l_tran_data.payer_id
                 and du_cd = p_du_cd;
          
            l_errline := 240;
            insert into crc_acct_no_mappings_dlp
              (crc,
               acct_no,
               acct_status,
               schedule,
               area_code,
               government_code,
               tin,
               cfnp_required_amt,
               last_date_paid,
               last_amount_paid,
               bd_required_amt,
               emp_acct,
               bus_add,
               bus_activity)
              select crc,
                     acct_no,
                     acct_status,
                     schedule,
                     area_code,
                     government_code,
                     tin,
                     cfnp_required_amt,
                     last_date_paid,
                     last_amount_paid,
                     bd_required_amt,
                     emp_acct,
                     bus_add,
                     bus_activity
                from crc_acct_no_mappings_tmp
               where acct_no = l_tran_data.payer_id
                 and du_cd = p_du_cd;
          end loop;
        end loop;
      
      elsif p_du_cd = 'LEZ' then
      
        l_errline := 250;
        insert into collection_batches_lez
          (batch_no,
           site_code,
           booth,
           teller,
           mode_of_entry,
           created_by,
           created_on,
           remitted_by,
           remitted_on,
           transmitted_by,
           transmitted_on,
           offline_or_date,
           or_count,
           requested_lt_min,
           granted_lt_min)
          select batch_no,
                 site_code,
                 booth,
                 teller,
                 mode_of_entry,
                 created_by,
                 created_on,
                 remitted_by,
                 remitted_on,
                 transmitted_by,
                 transmitted_on,
                 offline_or_date,
                 or_count,
                 requested_lt_min,
                 granted_lt_min
            from collection_batches_tmp
           where hdr_id = l_hdr_data.hdr_id;
      
        for l_batch_data in (select batch_no, site_code
                               from collection_batches_tmp
                              where hdr_id = l_hdr_data.hdr_id)
        
         loop
          l_errline := 260;
          insert into payment_transactions_lez
            (tran_no,
             last_name,
             first_name,
             mid_name,
             address,
             or_no,
             or_date,
             or_status,
             remarks,
             bank_ref_no,
             batch_no,
             payer_id,
             payer_type,
             posted,
             cancel_reason,
             or_count)
            select tran_no,
                   last_name,
                   first_name,
                   mid_name,
                   address,
                   or_no,
                   or_date,
                   or_status,
                   remarks,
                   bank_ref_no,
                   batch_no,
                   payer_id,
                   payer_type,
                   posted,
                   cancel_reason,
                   or_count
              from payment_transactions_tmp
             where batch_no = l_batch_data.batch_no
               and du_cd = p_du_cd;
        
          for l_tran_data in (select tran_no, payer_id
                                from payment_transactions_tmp
                               where du_cd = p_du_cd) loop
          
            l_errline := 270;
            insert into paid_items_lez
              (tran_no, seq_no, pay_code, amount_credit)
              select tran_no, seq_no, pay_code, amount_credit
                from paid_items_tmp
               where tran_no = l_tran_data.tran_no;
          
            l_errline := 280;
            insert into paid_acct_facts_lez
              (tran_no,
               acct_no,
               acct_status,
               schedule,
               area_code,
               government_code,
               tin,
               cfnp_required_amt,
               last_date_paid,
               last_amount_paid,
               apply_for_recon)
              select tran_no,
                     acct_no,
                     acct_status,
                     schedule,
                     area_code,
                     government_code,
                     tin,
                     cfnp_required_amt,
                     last_date_paid,
                     last_amount_paid,
                     apply_for_recon
                from paid_acct_facts_tmp
               where tran_no = l_tran_data.tran_no;
          
            l_errline := 290;
            insert into forms_of_payment_lez
              (tran_no, seq_no, payment_type, amount_paid)
              select tran_no, seq_no, payment_type, amount_paid
                from forms_of_payment_tmp
               where tran_no = l_tran_data.tran_no;
          
            l_errline := 300;
            insert into fop_cash_lez
              (tran_no, seq_no, amount_tendered)
              select tran_no, seq_no, amount_tendered
                from fop_cash_tmp
               where tran_no = l_tran_data.tran_no;
          
            l_errline := 310;
            insert into payers_lez
              (payer_type,
               payer_id,
               last_name,
               first_name,
               mid_name,
               address)
              select payer_type,
                     payer_id,
                     last_name,
                     first_name,
                     mid_name,
                     address
                from payers_tmp
               where payer_id = l_tran_data.payer_id
                 and du_cd = p_du_cd;
          
            l_errline := 320;
            insert into crc_acct_no_mappings_lez
              (crc,
               acct_no,
               acct_status,
               schedule,
               area_code,
               government_code,
               tin,
               cfnp_required_amt,
               last_date_paid,
               last_amount_paid,
               bd_required_amt,
               emp_acct,
               bus_add,
               bus_activity)
              select crc,
                     acct_no,
                     acct_status,
                     schedule,
                     area_code,
                     government_code,
                     tin,
                     cfnp_required_amt,
                     last_date_paid,
                     last_amount_paid,
                     bd_required_amt,
                     emp_acct,
                     bus_add,
                     bus_activity
                from crc_acct_no_mappings_tmp
               where acct_no = l_tran_data.payer_id
                 and du_cd = p_du_cd;
          end loop;
        end loop;
      
      elsif p_du_cd = 'BEZ' then
      
        l_errline := 330;
        insert into collection_batches_bez
          (batch_no,
           site_code,
           booth,
           teller,
           mode_of_entry,
           created_by,
           created_on,
           remitted_by,
           remitted_on,
           transmitted_by,
           transmitted_on,
           offline_or_date,
           or_count,
           requested_lt_min,
           granted_lt_min)
          select batch_no,
                 site_code,
                 booth,
                 teller,
                 mode_of_entry,
                 created_by,
                 created_on,
                 remitted_by,
                 remitted_on,
                 transmitted_by,
                 transmitted_on,
                 offline_or_date,
                 or_count,
                 requested_lt_min,
                 granted_lt_min
            from collection_batches_tmp
           where hdr_id = l_hdr_data.hdr_id;
      
        for l_batch_data in (select batch_no, site_code
                               from collection_batches_tmp
                              where hdr_id = l_hdr_data.hdr_id)
        
         loop
          l_errline := 340;
          insert into payment_transactions_bez
            (tran_no,
             last_name,
             first_name,
             mid_name,
             address,
             or_no,
             or_date,
             or_status,
             remarks,
             bank_ref_no,
             batch_no,
             payer_id,
             payer_type,
             posted,
             cancel_reason,
             or_count)
            select tran_no,
                   last_name,
                   first_name,
                   mid_name,
                   address,
                   or_no,
                   or_date,
                   or_status,
                   remarks,
                   bank_ref_no,
                   batch_no,
                   payer_id,
                   payer_type,
                   posted,
                   cancel_reason,
                   or_count
              from payment_transactions_tmp
             where batch_no = l_batch_data.batch_no
               and du_cd = p_du_cd;
        
          for l_tran_data in (select tran_no, payer_id
                                from payment_transactions_tmp
                               where du_cd = p_du_cd) loop
          
            l_errline := 350;
            insert into paid_items_bez
              (tran_no, seq_no, pay_code, amount_credit)
              select tran_no, seq_no, pay_code, amount_credit
                from paid_items_tmp
               where tran_no = l_tran_data.tran_no;
          
            l_errline := 360;
            insert into paid_acct_facts_bez
              (tran_no,
               acct_no,
               acct_status,
               schedule,
               area_code,
               government_code,
               tin,
               cfnp_required_amt,
               last_date_paid,
               last_amount_paid,
               apply_for_recon)
              select tran_no,
                     acct_no,
                     acct_status,
                     schedule,
                     area_code,
                     government_code,
                     tin,
                     cfnp_required_amt,
                     last_date_paid,
                     last_amount_paid,
                     apply_for_recon
                from paid_acct_facts_tmp
               where tran_no = l_tran_data.tran_no;
          
            l_errline := 370;
            insert into forms_of_payment_bez
              (tran_no, seq_no, payment_type, amount_paid)
              select tran_no, seq_no, payment_type, amount_paid
                from forms_of_payment_tmp
               where tran_no = l_tran_data.tran_no;
          
            l_errline := 380;
            insert into fop_cash_bez
              (tran_no, seq_no, amount_tendered)
              select tran_no, seq_no, amount_tendered
                from fop_cash_tmp
               where tran_no = l_tran_data.tran_no;
          
            l_errline := 390;
            insert into payers_bez
              (payer_type,
               payer_id,
               last_name,
               first_name,
               mid_name,
               address)
              select payer_type,
                     payer_id,
                     last_name,
                     first_name,
                     mid_name,
                     address
                from payers_tmp
               where payer_id = l_tran_data.payer_id
                 and du_cd = p_du_cd;
          
            l_errline := 400;
            insert into crc_acct_no_mappings_bez
              (crc,
               acct_no,
               acct_status,
               schedule,
               area_code,
               government_code,
               tin,
               cfnp_required_amt,
               last_date_paid,
               last_amount_paid,
               bd_required_amt,
               emp_acct,
               bus_add,
               bus_activity)
              select crc,
                     acct_no,
                     acct_status,
                     schedule,
                     area_code,
                     government_code,
                     tin,
                     cfnp_required_amt,
                     last_date_paid,
                     last_amount_paid,
                     bd_required_amt,
                     emp_acct,
                     bus_add,
                     bus_activity
                from crc_acct_no_mappings_tmp
               where acct_no = l_tran_data.payer_id
                 and du_cd = p_du_cd;
          end loop;
        end loop;
      
      elsif p_du_cd = 'CLP' then
      
        l_errline := 410;
        insert into collection_batches_clp
          (batch_no,
           site_code,
           booth,
           teller,
           mode_of_entry,
           created_by,
           created_on,
           remitted_by,
           remitted_on,
           transmitted_by,
           transmitted_on,
           offline_or_date,
           or_count,
           requested_lt_min,
           granted_lt_min)
          select batch_no,
                 site_code,
                 booth,
                 teller,
                 mode_of_entry,
                 created_by,
                 created_on,
                 remitted_by,
                 remitted_on,
                 transmitted_by,
                 transmitted_on,
                 offline_or_date,
                 or_count,
                 requested_lt_min,
                 granted_lt_min
            from collection_batches_tmp
           where hdr_id = l_hdr_data.hdr_id;
      
        for l_batch_data in (select batch_no, site_code
                               from collection_batches_tmp
                              where hdr_id = l_hdr_data.hdr_id)
        
         loop
          l_errline := 420;
          insert into payment_transactions_clp
            (tran_no,
             last_name,
             first_name,
             mid_name,
             address,
             or_no,
             or_date,
             or_status,
             remarks,
             bank_ref_no,
             batch_no,
             payer_id,
             payer_type,
             posted,
             cancel_reason,
             or_count)
            select tran_no,
                   last_name,
                   first_name,
                   mid_name,
                   address,
                   or_no,
                   or_date,
                   or_status,
                   remarks,
                   bank_ref_no,
                   batch_no,
                   payer_id,
                   payer_type,
                   posted,
                   cancel_reason,
                   or_count
              from payment_transactions_tmp
             where batch_no = l_batch_data.batch_no
               and du_cd = p_du_cd;
        
          for l_tran_data in (select tran_no, payer_id
                                from payment_transactions_tmp
                               where du_cd = p_du_cd) loop
          
            l_errline := 430;
            insert into paid_items_clp
              (tran_no, seq_no, pay_code, amount_credit)
              select tran_no, seq_no, pay_code, amount_credit
                from paid_items_tmp
               where tran_no = l_tran_data.tran_no;
          
            l_errline := 440;
            insert into paid_acct_facts_clp
              (tran_no,
               acct_no,
               acct_status,
               schedule,
               area_code,
               government_code,
               tin,
               cfnp_required_amt,
               last_date_paid,
               last_amount_paid,
               apply_for_recon)
              select tran_no,
                     acct_no,
                     acct_status,
                     schedule,
                     area_code,
                     government_code,
                     tin,
                     cfnp_required_amt,
                     last_date_paid,
                     last_amount_paid,
                     apply_for_recon
                from paid_acct_facts_tmp
               where tran_no = l_tran_data.tran_no;
          
            l_errline := 450;
            insert into forms_of_payment_clp
              (tran_no, seq_no, payment_type, amount_paid)
              select tran_no, seq_no, payment_type, amount_paid
                from forms_of_payment_tmp
               where tran_no = l_tran_data.tran_no;
          
            l_errline := 460;
            insert into fop_cash_clp
              (tran_no, seq_no, amount_tendered)
              select tran_no, seq_no, amount_tendered
                from fop_cash_tmp
               where tran_no = l_tran_data.tran_no;
          
            l_errline := 470;
            insert into payers_clp
              (payer_type,
               payer_id,
               last_name,
               first_name,
               mid_name,
               address)
              select payer_type,
                     payer_id,
                     last_name,
                     first_name,
                     mid_name,
                     address
                from payers_tmp
               where payer_id = l_tran_data.payer_id
                 and du_cd = p_du_cd;
          
            l_errline := 480;
            insert into crc_acct_no_mappings_clp
              (crc,
               acct_no,
               acct_status,
               schedule,
               area_code,
               government_code,
               tin,
               cfnp_required_amt,
               last_date_paid,
               last_amount_paid,
               bd_required_amt,
               emp_acct,
               bus_add,
               bus_activity)
              select crc,
                     acct_no,
                     acct_status,
                     schedule,
                     area_code,
                     government_code,
                     tin,
                     cfnp_required_amt,
                     last_date_paid,
                     last_amount_paid,
                     bd_required_amt,
                     emp_acct,
                     bus_add,
                     bus_activity
                from crc_acct_no_mappings_tmp
               where acct_no = l_tran_data.payer_id
                 and du_cd = p_du_cd;
          end loop;
        end loop;
     
      elsif p_du_cd = 'MEZ' then
      
        l_errline := 490;
        insert into collection_batches_mez
          (batch_no,
           site_code,
           booth,
           teller,
           mode_of_entry,
           created_by,
           created_on,
           remitted_by,
           remitted_on,
           transmitted_by,
           transmitted_on,
           offline_or_date,
           or_count,
           requested_lt_min,
           granted_lt_min)
          select batch_no,
                 site_code,
                 booth,
                 teller,
                 mode_of_entry,
                 created_by,
                 created_on,
                 remitted_by,
                 remitted_on,
                 transmitted_by,
                 transmitted_on,
                 offline_or_date,
                 or_count,
                 requested_lt_min,
                 granted_lt_min
            from collection_batches_tmp
           where hdr_id = l_hdr_data.hdr_id;
      
        for l_batch_data in (select batch_no, site_code
                               from collection_batches_tmp
                              where hdr_id = l_hdr_data.hdr_id)
        
         loop
          l_errline := 500;
          insert into payment_transactions_mez
            (tran_no,
             last_name,
             first_name,
             mid_name,
             address,
             or_no,
             or_date,
             or_status,
             remarks,
             bank_ref_no,
             batch_no,
             payer_id,
             payer_type,
             posted,
             cancel_reason,
             or_count)
            select tran_no,
                   last_name,
                   first_name,
                   mid_name,
                   address,
                   or_no,
                   or_date,
                   or_status,
                   remarks,
                   bank_ref_no,
                   batch_no,
                   payer_id,
                   payer_type,
                   posted,
                   cancel_reason,
                   or_count
              from payment_transactions_tmp
             where batch_no = l_batch_data.batch_no
               and du_cd = p_du_cd;
        
          for l_tran_data in (select tran_no, payer_id
                                from payment_transactions_tmp
                               where du_cd = p_du_cd) loop
          
            l_errline := 510;
            insert into paid_items_mez
              (tran_no, seq_no, pay_code, amount_credit)
              select tran_no, seq_no, pay_code, amount_credit
                from paid_items_tmp
               where tran_no = l_tran_data.tran_no;
          
            l_errline := 520;
            insert into paid_acct_facts_mez
              (tran_no,
               acct_no,
               acct_status,
               schedule,
               area_code,
               government_code,
               tin,
               cfnp_required_amt,
               last_date_paid,
               last_amount_paid,
               apply_for_recon)
              select tran_no,
                     acct_no,
                     acct_status,
                     schedule,
                     area_code,
                     government_code,
                     tin,
                     cfnp_required_amt,
                     last_date_paid,
                     last_amount_paid,
                     apply_for_recon
                from paid_acct_facts_tmp
               where tran_no = l_tran_data.tran_no;
          
            l_errline := 530;
            insert into forms_of_payment_mez
              (tran_no, seq_no, payment_type, amount_paid)
              select tran_no, seq_no, payment_type, amount_paid
                from forms_of_payment_tmp
               where tran_no = l_tran_data.tran_no;
          
            l_errline := 540;
            insert into fop_cash_mez
              (tran_no, seq_no, amount_tendered)
              select tran_no, seq_no, amount_tendered
                from fop_cash_tmp
               where tran_no = l_tran_data.tran_no;
          
            l_errline := 550;
            insert into payers_mez
              (payer_type,
               payer_id,
               last_name,
               first_name,
               mid_name,
               address)
              select payer_type,
                     payer_id,
                     last_name,
                     first_name,
                     mid_name,
                     address
                from payers_tmp
               where payer_id = l_tran_data.payer_id
                 and du_cd = p_du_cd;
          
            l_errline := 560;
            insert into crc_acct_no_mappings_mez
              (crc,
               acct_no,
               acct_status,
               schedule,
               area_code,
               government_code,
               tin,
               cfnp_required_amt,
               last_date_paid,
               last_amount_paid,
               bd_required_amt,
               emp_acct,
               bus_add,
               bus_activity)
              select crc,
                     acct_no,
                     acct_status,
                     schedule,
                     area_code,
                     government_code,
                     tin,
                     cfnp_required_amt,
                     last_date_paid,
                     last_amount_paid,
                     bd_required_amt,
                     emp_acct,
                     bus_add,
                     bus_activity
                from crc_acct_no_mappings_tmp
               where acct_no = l_tran_data.payer_id
                 and du_cd = p_du_cd;
          end loop;
        end loop;
    
      end if;
    
      l_errline := 570;
      update cisadm_apps.collection_files
         set status = 'U'
       where hdr_id = l_hdr_data.hdr_id
         and du_cd = l_hdr_data.du_cd;
    end loop;
  
    commit;
  exception
    when others then
      l_errmsg := 'Error in POSTING_TO_ORS @ line : ' || to_char(l_errline) || ' ' ||
                  sqlerrm;
      /*p_is_success     := FALSE;
      p_return_message := 'Error in POSTING_TO_ORS @ line : ' ||
                          to_char(l_errline) || ' ' || sqlerrm;*/
      rollback;
      app_error_pkg.log_error(p_module           => 'IEMOP',
                              p_action           => 'POSTING_TO_ORS',
                              p_oracle_error_msg => sqlerrm,
                              p_custom_error_msg => l_errmsg,
                              p_table_name       => 'collection_files',
                              p_pk1              => '',
                              p_raise_error      => 0);
      raise_application_error(-20000, l_errmsg);
  end posting_to_ors;

end iemop_pkg;
