create or replace package esb.cr_mtr_asset_migration_pkg is

  function get_acct_id(p_col_id    in varchar2,
                       p_val_id    in char,
                       p_asof_date in date) return ci_sa.acct_id%type;

  function get_acct_poleno(p_col_id    in varchar2,
                           p_val_id    in char,
                           p_asof_date in date) return ci_sp_geo.geo_val%type;

  function get_mtr_install_dt(p_col_id in varchar2, p_val_id in char)
    return date;

  function get_sp_id(p_sp_mtr_hist_id in ci_sp_mtr_hist.sp_mtr_hist_id%type)
    return char;

  function has_asset_id(p_plant in varchar2, p_badge_nbr in varchar2)
    return boolean;

  function valid_installation(p_sp_id ci_sp.sp_id%type) return boolean;

  function valid_removal(p_sp_id ci_sa_sp.sp_id%type) return boolean;

  procedure main(p_plant in varchar2);

end cr_mtr_asset_migration_pkg;
