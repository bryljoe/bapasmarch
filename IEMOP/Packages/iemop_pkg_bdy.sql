create or replace package iemop_pkg authid current_user is

  type iemop_data_rec_type is record(
    last_name                 varchar2(100),
    first_name                varchar2(50),
    mid_name                  varchar2(50),
    address                   varchar2(200),
    or_date                   date,
    payer_id                  varchar2(20),
    sum_of_vatable_sales      number(15, 2),
    sum_of_zero_rated_sales   number(15, 2),
    sum_of_zero_rated_ecozone number(15, 2),
    sum_of_vat_on_sales       number(15, 2),
    sum_of_witholding_tax     number(15, 2),
    tin                       varchar2(20),
    sum_of_total              number(15, 2),
    bus_activity              varchar2(100));

  type iemop_rec_type is record(
    site_code varchar2(20));

  /*function get_tran_no(p_du_cd in varchar2) return number;*/
  /*function get_batch_no(p_du_cd in varchar2) return number;*/
  procedure cancel_file(p_hdr_id in number, p_du_cd in varchar2);

  procedure upload_data_transactions(p_batch_no            in number,
                                     p_du_cd               in varchar2,
                                     p_tran_no             out number,
                                     p_iemop_data_rec_type in iemop_data_rec_type);

  procedure upload_collection_batches(p_hdr_id    in number,
                                      p_batch_no  out number,
                                      p_du_cd     in varchar2,
                                      p_iemop_rec in iemop_rec_type);

  procedure upload_or_file(p_file_name in varchar2,
                           p_hdr_id    in out number,
                           p_batch_no  out number,
                           p_tran_no   out number,
                           p_du_cd     in varchar2);

  procedure posting_to_ors(p_du_cd in varchar2);

end iemop_pkg;
