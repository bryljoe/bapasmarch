create or replace package sd_refund_pkg is

  /*--  Revisions History
           See package body
  */ --  End of Revisions History

  function get_deposits(p_acct_id in varchar2, p_period in varchar2)
    return varchar2;
  procedure retrieve_special_deposit_sa;
  procedure retrieve_special_deposit_accts;
  procedure summarize_revenue;
  /*procedure prepare_sa_adjustments;
  procedure apply_adjustments_v2;
  procedure apply_adjustments;*/
  procedure special_deposit_msgs;
  procedure sd_scheduler;
  procedure log_error(p_errmsg     in varchar2,
                      p_ora_errmsg in varchar2 default null);

end sd_refund_pkg;
