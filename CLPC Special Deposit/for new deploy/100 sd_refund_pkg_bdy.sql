create or replace package body sd_refund_pkg is
  /*--  Revisions History
           v1.0.4 by bapas on November 03, 2022
            -> revise procedure RETRIEVE_SPECIAL_DEPOSIT_SA
               - fetch and run all special deposit SA_ID in a month basing sa birthdate
               - Check and add if there is APT Refund, APT WriteOff, APT AR
               - add validation if there is APT Refund, process of special deposit will proceed

            ->  revised procedure PREPARE_SA_ADJUSTMENTS
               - Add adj type XFER-CA and XFER-PYO into staging table
               - Add columns apt_balance_amt, apwo_balance_amt, apar_balance_amt in driving query
                 - Add Customer Contact for Refund, Bill Deposit, Refund + Bill Deposit, Write Off and AR

            -> add procedure apply_adjustment_v2
               - this is to add adjustment staging table to be posted in CCB for adjustment XFER-PYO and XFER-CA

            -> revise procedure special_deposit_msgs
               - add column apt_balance_amt and apwo_balance_amt in sql


           v1.0.3 by rreston on October 21, 2019
           Purpose of Change : to run special deposit in everyday (birthdate of the sa_id)
           Affected objects  :
                        old  : retrieve_special_deposit_sa
                        new  : sd_scheduler
                        new  : special_deposit_msgs
           Remarks           :

           v1.0.2 by jlcomeros on January 30, 2019
              - revise procedure PREPARE_SA_ADJUSTMENTS
                  - add check and balance
           v1.0.1 by jlcomeros on January 14, 2019
              - transfer computation of SA adjustment to procedure SUMMARIZE_REVENUE;
           v1.0.0 by jlcomeros on January 14, 2019
              - production release
  */ --  End of Revisions History

  g_sysdate_override date;
  g_period           varchar2(8);
  g_du               varchar2(10);
  g_ar_dst_id        char(10);
  g_bd_sa_type_cd    ci_sa_type.sa_type_cd%type;

  procedure log_error(p_errmsg     in varchar2,
                      p_ora_errmsg in varchar2 default null) is
    pragma autonomous_transaction;
  begin
    insert into error_logs
      (logged_by, logged_on, module, custom_error_msg, oracle_error_msg)
    values
      (user,
       sysdate,
       'SD_REFUND_PKG',
       substr(p_errmsg, 1, 500),
       substr(p_ora_errmsg, 1, 500));
    commit;
  end log_error;

  procedure load_global_variables is
  begin
    begin
      select nvl(to_date(reg_value, 'MM/DD/YYYY'), sysdate)
        into g_sysdate_override
        from sd_refund_registry
       where reg_code = 'SYSDATEOVERRIDE';
    exception
      when no_data_found then
        g_sysdate_override := sysdate;
    end;

    if to_char(trunc(g_sysdate_override, 'MM'), 'MM') = '01' then
      g_period := to_char(g_sysdate_override, 'YYYY');
    else
      g_period := to_char(add_months(g_sysdate_override, -1), 'YYYY');
    end if;

    select trim(cis_division) into g_du from ci_cis_division_l;

    select max(rpad(value, 10, ' ')) keep(dense_rank first order by effective_on desc)
      into g_ar_dst_id
      from du_registry
     where reg_code = 'AR_ELEC_DST_ID'
       and effective_on <= sysdate;

    select max(value) keep(dense_rank first order by effective_on desc)
      into g_bd_sa_type_cd
      from du_registry
     where reg_code = 'BD_SA_TYPE_CD'
       and effective_on <= sysdate;

  end load_global_variables;

  function get_deposits(p_acct_id in varchar2, p_period in varchar2)
    return varchar2 as

    l_amount number;

  begin
    select nvl(sum(ft.tot_amt), 0) tot_amt
      into l_amount
      from ci_sa sa, ci_ft ft
     where sa.sa_id = ft.sa_id
       and sa.sa_type_cd like 'D-%'
       and sa.sa_type_cd <> 'D-BILL'
       and sa.acct_id = p_acct_id
       and not exists (select 1
              from sd_refund_sa b
             where period = p_period
               and sa.sa_id = b.sd_sa_id);

    return l_amount;

  end get_deposits;

  -->> RETRIEVING SPECIAL DEPOSIT SAs
  procedure retrieve_special_deposit_sa is
    l_last_refund_date    date;
    l_sd_balance_amt      number;
    l_sd_curr_balance_amt number;
    l_custom_msg          varchar2(1000);
    l_ora_errmsg          varchar2(1000);
    l_start_dt            varchar2(10);
    l_sa_ref_id           varchar2(15);
    l_sa_wo_id            varchar2(15);
    l_sa_ar_id            varchar2(15);
    l_ap_amt              varchar2(15);
    l_apwo_amt            varchar2(15);
    l_apar_amt            varchar2(15);
  begin
    load_global_variables;
    l_custom_msg := 'retrieving special deposit SAs';
    l_start_dt   := to_char(trunc(sysdate, 'MM'), 'MMDD');
    for sd in (select acct_id,
                      sd_sa_id,
                      sd_sa_type_cd,
                      start_dt sd_sa_start_dt,
                      sd_sa_month,
                      sd_sa_status_flg
                 from (select acct_id,
                              sa_id sd_sa_id,
                              sa_type_cd sd_sa_type_cd,
                              to_char(trunc(start_dt, 'MM'), 'MMDD') sd_sa_start_dt,
                              to_char(trunc(start_dt, 'MM'), 'MM') sd_sa_month,
                              start_dt,
                              sa_status_flg sd_sa_status_flg
                         from ci_sa sa
                        where sa_type_cd like 'D-%'
                          and sa_type_cd <> g_bd_sa_type_cd)
                where sd_sa_start_dt = l_start_dt) loop

      l_custom_msg := 'retrieving total balance for sa id ' || sd.sd_sa_id;

      select nvl(sum(b.tot_amt), 0)
        into l_sd_balance_amt
        from ci_ft b
       where b.sa_id = sd.sd_sa_id
         and b.freeze_sw = 'Y'
         and ((b.parent_id not like 'CM-TTMP%' and exists
              (select 1 from ci_ft_gl g where g.ft_id = b.ft_id)) or
             (b.parent_id like 'CM-TTMP%' and not exists
              (select 1 from ci_ft_gl g where g.ft_id = b.ft_id)));

      l_custom_msg := 'retrieving current balance for sa id ' ||
                      sd.sd_sa_id;
      select nvl(sum(b.cur_amt), 0)
        into l_sd_curr_balance_amt
        from ci_ft b
       where b.sa_id = sd.sd_sa_id
         and b.freeze_sw = 'Y';

      l_custom_msg := ('Check if there is apt refund ' || sd.acct_id);
      begin

        select max(sa_id) keep(dense_rank first order by start_dt desc) sa_id
          into l_sa_ref_id
          from ci_sa a
         where acct_id = sd.acct_id
           and a.sa_status_flg = '20'
           and a.sa_type_cd = 'A/P-REF ';

      exception
        when no_data_found then
          null;
      end;

      l_custom_msg := ('Check if there is existing WO ' || sd.acct_id);
      begin

        select max(sa_id) keep(dense_rank first order by start_dt desc) sa_id
          into l_sa_wo_id
          from ci_sa a
         where acct_id = sd.acct_id
           and a.sa_status_flg = '20'
           and a.sa_type_cd = 'A/P-WO  ';

      exception
        when no_data_found then
          null;
      end;

      l_custom_msg := ('Check if there is existing AR ' || sd.acct_id);
      begin

        select max(sa_id) keep(dense_rank first order by start_dt desc) sa_id
          into l_sa_ar_id
          from ci_sa a
         where acct_id = sd.acct_id
           and a.sa_status_flg = '20'
           and a.sa_type_cd = 'A/P-AR  ';

      exception
        when no_data_found then
          null;
      end;

      l_custom_msg := ('Retrieve APT Ref Balance : ' || l_sa_ref_id);
      begin
        select (nvl(sum(a.tot_amt), 0) * -1)
          into l_ap_amt
          from ci_ft a
         where a.sa_id = l_sa_ref_id;
      exception
        when no_data_found then
          null;
      end;

      l_custom_msg := ('Retrieve WO Balance : ' || l_sa_wo_id);
      begin
        select (nvl(sum(a.tot_amt), 0) * -1)
          into l_apwo_amt
          from ci_ft a
         where a.sa_id = l_sa_wo_id;
      exception
        when no_data_found then
          null;
      end;

      l_custom_msg := ('Retrieve AR Balance : ' || l_sa_ar_id);
      begin
        select (nvl(sum(a.tot_amt), 0) * -1)
          into l_apar_amt
          from ci_ft a
         where a.sa_id = l_sa_ar_id;
      exception
        when no_data_found then
          null;
      end;

      if l_sd_balance_amt < 0 or l_ap_amt > 0 then
        l_custom_msg := 'saving account id for special deposit sa id ' ||
                        sd.sd_sa_id;
        begin
          insert into sd_refund_accts_sa
            (period,
             acct_id,
             sa_month,
             apt_balance_amt,
             apwo_balance_amt,
             apar_balance_amt)
          values
            (g_period, sd.acct_id, sd.sd_sa_month ,l_ap_amt, l_apwo_amt, l_apar_amt);
        exception
          when dup_val_on_index then
            null;
        end;

        l_custom_msg := 'retrieving last refund date for sa id ' ||
                        sd.sd_sa_id;
        if g_du in ('25', '28') then
          select max(freeze_dttm)
            into l_last_refund_date
            from ci_ft ft
          --where  parent_id = 'SDREFUND'
           where parent_id in (rpad('SDREFUND', 12, ' '),
                               rpad('XFER-PYO', 12, ' '),
                               rpad('XFER', 12, ' '))
             and freeze_sw = 'Y'
             and ft_type_flg = 'AD'
             and sa_id = sd.sd_sa_id
             and not exists (select 1
                    from ci_ft a
                   where a.parent_id = ft.parent_id
                     and a.sibling_id = ft.sibling_id
                     and a.sa_id = ft.sa_id
                     and a.freeze_sw = ft.freeze_sw
                     and a.ft_type_flg = 'AX');
        elsif g_du in ('20', '21') then
          select max(freeze_dttm)
            into l_last_refund_date
            from ci_ft ft
          --where  parent_id in ( 'REF-SD','SDREFAP')
           where parent_id in (rpad('REF-SD', 12, ' '),
                               rpad('SDREFAP', 12, ' '),
                               rpad('XFER-PYO', 12, ' '),
                               rpad('XFER', 12, ' '))
             and freeze_sw = 'Y'
             and ft_type_flg = 'AD'
             and sa_id = sd.sd_sa_id
             and not exists (select 1
                    from ci_ft a
                   where a.parent_id = ft.parent_id
                     and a.sibling_id = ft.sibling_id
                     and a.sa_id = ft.sa_id
                     and a.freeze_sw = freeze_sw
                     and a.ft_type_flg = 'AX');
        end if;

        l_custom_msg := 'saving special deposit sa id ' || sd.sd_sa_id;

        begin
          insert into sd_refund_sa
            (period,
             acct_id,
             sd_sa_id,
             sd_sa_type_cd,
             sd_sa_start_dt,
             sd_sa_status_flg,
             sd_balance_amt,
             sd_curr_balance_amt,
             last_refund_date)
          values
            (g_period,
             sd.acct_id,
             sd.sd_sa_id,
             sd.sd_sa_type_cd,
             sd.sd_sa_start_dt,
             sd.sd_sa_status_flg,
             l_sd_balance_amt,
             l_sd_curr_balance_amt,
             l_last_refund_date);
        exception
          when dup_val_on_index then
            null;
        end;

        begin

          insert into deposit_sas
            (period, acct_id, sa_id, sa_month, sa_type_cd, tot_amt, cur_amt, bal_amt)
          values
            (g_period,
             sd.acct_id,
             sd.sd_sa_id,
             sd.sd_sa_month,
             sd.sd_sa_type_cd,
             abs(l_sd_balance_amt),
             abs(l_sd_curr_balance_amt),
             abs(l_sd_balance_amt));

        exception
          when dup_val_on_index then
            null;
        end;

      end if;
    end loop;
    commit;
  exception
    when others then
      l_custom_msg := 'Error @ procedure RETRIEVE_SPECIAL_DEPOSIT_SA when ' ||
                      l_custom_msg;
      l_ora_errmsg := sqlerrm;
      log_error(l_custom_msg, l_ora_errmsg);
      raise_application_error(-20012,
                              l_custom_msg || ' : ' || l_ora_errmsg);
  end retrieve_special_deposit_sa;

  -->> RETRIEVING SD ACCT DETAILS
  procedure retrieve_special_deposit_accts is
    l_sd_sa_start_dt         date;
    l_sd_balance_amt         number;
    l_last_refund_date       date;
    l_last_applied_rev_month date;
    l_rev_period_from        date;
    l_rev_period_to          date;
    l_rev_cutoff_day         number := 0;
    l_status                 varchar2(10);
    l_start_dt               varchar2(10);

    l_acct_name      varchar2(100);
    l_person_type    varchar2(100);
    l_bill_cyc_cd    char(4);
    l_mr_rte_cd      char(16);
    l_address        varchar2(500);
    l_bd_msgr        varchar2(10);
    l_bd_seq         varchar2(10);
    l_prem_id        char(10);
    l_parent_prem_id char(10);
    l_active         varchar2(2);

    l_ar_sa_id char(10);
    l_remarks  varchar2(100);

    l_total_rev_amt  number;
    l_wo_balance_amt number;
    l_bd_balance_amt number;
    l_avg_bill_amt   number;
    l_ar_balance_amt number;
    l_bd_refund_amt  number;
    l_apwo_amt       number;
    l_bd_refund_dt   date;
    --l_sd_total_for_bd_amt number;
    l_latest_surcharge_dt date;
    l_prompt_payor        varchar2(1);

    l_eligible_for_bd_topup varchar2(1);
    l_custom_msg            varchar2(1000);
    l_ora_errmsg            varchar2(1000);
    l_errline               number;

  begin
    l_start_dt   := to_char(trunc(sysdate, 'MM'), 'MM');
    load_global_variables;

    for sd in (select period, acct_id, sa_month
                 from sd_refund_accts_sa
                where status is null
                  and period = g_period
                  and sa_month = l_start_dt) loop

      l_custom_msg := 'retrieving the start date, last refund date and balance for acct id ' ||
                      sd.acct_id;

      select min(sd_sa_start_dt),
             sum(sd_balance_amt),
             max(last_refund_date)
        into l_sd_sa_start_dt, l_sd_balance_amt, l_last_refund_date
        from sd_refund_sa
       where period = sd.period
         and acct_id = sd.acct_id
         and to_char(trunc(sd_sa_start_dt, 'MM'), 'MM') = l_start_dt
       group by acct_id;

      l_custom_msg := 'retrieving the last applied revenue month for acct id ' ||
                      sd.acct_id;
      --l_last_applied_rev_month := null;
      select max(rev_period_to)
        into l_last_applied_rev_month
        from sd_refund_accts_sa
       where status = 'UPLOADED'
         and period < sd.period
         and acct_id = sd.acct_id;

      select sum(nvl(apwo_balance_amt, 0))
        into l_apwo_amt
        from sd_refund_accts_sa
       where acct_id = sd.acct_id
         and period = sd.period;

      if l_last_refund_date is null and l_last_applied_rev_month is null then
        l_rev_period_from := trunc(l_sd_sa_start_dt, 'MM');
      else
        if l_last_applied_rev_month is null then
          if g_du in ('20', '21') and sd.period < '2018' then
            l_last_applied_rev_month := trunc(add_months(l_last_refund_date,
                                                         -1),
                                              'MM');
          else
            l_last_applied_rev_month := to_date(to_char(trunc(l_sd_sa_start_dt,
                                                              'MM'),
                                                        'MMDD') ||
                                                to_char(l_last_refund_date,
                                                        'YYYY'),
                                                'MMDDYYYY');
            if trunc(l_last_refund_date, 'MM') <= l_last_applied_rev_month then
              l_last_applied_rev_month := add_months(l_last_applied_rev_month,
                                                     -12);
            end if;
          end if;
        end if;
        l_rev_period_from := trunc(add_months(l_last_applied_rev_month, 1),
                                   'MM');
      end if;

      -->> anniversary date
      l_rev_period_to := last_day(to_date(to_char(trunc(l_sd_sa_start_dt,
                                                        'MM'),
                                                  'MMDD') || g_period,
                                          'MMDDYYYY'));
      --l_rev_period_to := last_day(to_date(to_char(trunc(l_sd_sa_start_dt,'MM'),'MMDD')||to_char(l_sysdate_override,'YYYY'),'MMDDYYYY'));

      -->> anniversary date month should be lower than the current month

      if months_between(trunc(l_rev_period_to, 'MM'),
                        trunc(g_sysdate_override, 'MM')) >= 0 then
        l_rev_period_to := add_months(l_rev_period_to, -12);
      end if;

      -->> validate revenue month against the current month
      if l_rev_period_to <= trunc(g_sysdate_override, 'MM') and
         trunc(l_rev_period_to, 'MM') > l_rev_period_from --and to_char(g_sysdate_override,'DD') >= l_rev_cutoff_day
       then
        l_status  := 'PENDING';
        l_remarks := null;
      else
        l_status  := 'REJECTED';
        l_remarks := 'INVALID REVENUE PERIOD ';
      end if;

      l_custom_msg := 'retrieving the name for acct id ' || sd.acct_id;
      begin
        select trim(replace(replace(replace(replace(replace(replace(entity_name,
                                                                    ',',
                                                                    ' '),
                                                            chr(10)),
                                                    chr(13)),
                                            '?',
                                            'N'),
                                    '?',
                                    'E'),
                            chr(9),
                            ' '))
          into l_acct_name
          from ci_acct_per ap, ci_per_name pn
         where ap.per_id = pn.per_id
           and ap.acct_rel_type_cd = 'MAINCU  ' -->> main Customer
           and ap.main_cust_sw = 'Y'
           and pn.name_type_flg = 'PRIM' -->> primary Person
           and ap.acct_id = sd.acct_id;
      exception
        when no_data_found then
          l_acct_name := null;
      end;

      l_custom_msg := 'retrieving the person type for acct id ' ||
                      sd.acct_id;
      begin
        select (select descr
                  from ci_lookup_val_l
                 where field_name = 'PER_OR_BUS_FLG'
                   and field_value = rpad(pr.per_or_bus_flg, 4, ' '))
          into l_person_type
          from ci_acct_per ap, ci_per pr
         where ap.per_id = pr.per_id
           and ap.acct_rel_type_cd = 'MAINCU  ' -->> main Customer
           and ap.main_cust_sw = 'Y'
           and ap.acct_id = sd.acct_id;
      exception
        when no_data_found then
          l_person_type := null;
      end;

      l_custom_msg := 'retrieving the premise id and bill cycle for acct id ' ||
                      sd.acct_id;
      begin
        select mailing_prem_id, bill_cyc_cd
          into l_prem_id, l_bill_cyc_cd
          from ci_acct
         where acct_id = sd.acct_id;
      exception
        when no_data_found then
          l_prem_id     := null;
          l_bill_cyc_cd := null;
      end;

      begin
        select trim(prnt_prem_id),
               address1 || nvl2(address1, nvl2(address2, ',', ''), '') ||
               address2 || nvl2(address2,
                                nvl2(address3, ', ', ''),
                                nvl2(address3, ', ', '')) || address3
          into l_parent_prem_id, l_address
          from ci_prem
         where prem_id = l_prem_id;
      exception
        when no_data_found then
          l_parent_prem_id := null;
          l_address        := null;
      end;

      l_custom_msg := 'retrieving the route no for acct id ' || sd.acct_id;
      select max(trim(sp.mr_rte_cd)) keep(dense_rank first order by nvl(sasp.stop_dttm, g_sysdate_override) desc)
        into l_mr_rte_cd
        from ci_sp sp, ci_sa_sp sasp, ci_sa sa, ci_sa_type sat
       where sasp.sp_id = sp.sp_id
         and sasp.sa_id = sa.sa_id
            --and    sa.sa_type_cd like 'E-%' -->> Electric Meter
         and sa.sa_type_cd = sat.sa_type_cd
         and sat.svc_type_cd = 'EL'
         and sa.acct_id = sd.acct_id
         and sat.dst_id = g_ar_dst_id;

      l_custom_msg := 'retrieving the messenger for acct id ' || sd.acct_id;
      select max(trim(nvl(trim(char_val), trim(adhoc_char_val)))) keep(dense_rank first order by nvl(effdt, g_sysdate_override) desc)
        into l_bd_msgr
        from ci_acct_char
       where acct_id = sd.acct_id
         and char_type_cd = 'CM_BDMSR';

      l_custom_msg := 'retrieving the messenger sequence for acct id ' ||
                      sd.acct_id;
      select max(trim(nvl(trim(char_val), trim(adhoc_char_val)))) keep(dense_rank first order by nvl(effdt, g_sysdate_override) desc)
        into l_bd_seq
        from ci_acct_char
       where acct_id = sd.acct_id
         and char_type_cd = 'CM_BDSEQ';

      l_custom_msg := 'retrieving the writeoff total amount for acct id ' ||
                      sd.acct_id;
      select nvl(sum(tot_amt), 0)
        into l_wo_balance_amt
        from ci_ft
       where sa_id in (select sa_id
                         from ci_sa
                        where sa_type_cd in ('WRITEOFF', 'M-WOALL ')
                          and acct_id = sd.acct_id)
         and freeze_sw = 'Y';

    l_custom_msg := 'saving balance sas for acct id write off ' || sd.acct_id;
      insert into balance_sas
        (period, acct_id, sa_id, sa_month, sa_type_cd, tot_amt, cur_amt, bal_amt)
        select sd.period,
               sd.acct_id,
               ft.sa_id,
               sd.sa_month,
               sa.sa_type_cd,
               nvl(sum(ft.tot_amt), 0) tot_amt,
               nvl(sum(ft.cur_amt), 0) cur_amt,
               nvl(sum(ft.tot_amt), 0) bal_amt
          from ci_ft ft, ci_sa sa
         where ft.sa_id = sa.sa_id
           and ft.sa_id in (select sa_id
                              from ci_sa
                             where sa_type_cd in ('WRITEOFF', 'M-WOALL ')
                               and acct_id = sd.acct_id)
           and ft.freeze_sw = 'Y'
         group by ft.sa_id, sa.sa_type_cd;

      l_custom_msg := 'retrieving the bill deposit total amount for acct id ' ||
                      sd.acct_id;
      select nvl(sum(tot_amt), 0)
        into l_bd_balance_amt
        from ci_ft
       where sa_id in (select sa_id
                         from ci_sa
                        where sa_type_cd = g_bd_sa_type_cd
                          and acct_id = sd.acct_id
                          and sa_status_flg in ('20', '40', '50'))
         and freeze_sw = 'Y';

      /*l_ar_balance_amt := 0;
      l_avg_bill_amt := 0;
      declare
          l_balance_amt number;
          l_avg_amt number;
      begin
          l_active := 'N';
          for ar in ( select sa_id
                      from   ci_sa saa, ci_sa_type sat
                      where  saa.sa_type_cd = sat.sa_type_cd
                      and    sat.svc_type_cd = 'EL'
                      and    saa.sa_type_cd like 'E-%'
                      and    saa.sa_type_cd not like 'NET-%'
                      and    saa.sa_status_flg in ('20','50')
                      and    sat.dst_id = g_ar_dst_id
                      and    saa.acct_id = sd.acct_id)
          loop
              select nvl(sum (b.tot_amt),0)
              into   l_balance_amt
              from   ci_ft b
              where  b.sa_id = ar.sa_id
              and    b.freeze_sw = 'Y';

              l_ar_balance_amt := l_ar_balance_amt + l_balance_amt;

              select nvl(round(avg(bill_amt),2),0)
              into   l_avg_amt
              from   (
                      select bl.bill_id, sum(bc.calc_amt) bill_amt
                      from   ci_bseg bs, ci_bseg_calc bc, ci_bill bl
                      where  bs.bseg_id = bc.bseg_id
                      and    bs.bill_id = bl.bill_id
                      and    bc.header_seq = 1
                      and    bs.bseg_stat_flg in ('50', '70')
                      and    bl.bill_stat_flg = 'C'
                      --and    bs.bill_id = p_bill_id
                      and    bl.acct_id = sd.acct_id
                      and    bs.sa_id = ar.sa_id
                      and    bs.end_dt > add_months(trunc(g_sysdate_override),-12)
                      and    bs.end_dt <= trunc(g_sysdate_override)
                      group by bl.bill_id
                      );

              l_avg_bill_amt := l_avg_bill_amt + l_avg_amt;

              if trim(l_bill_cyc_cd) is not null
              then
                  l_active := 'Y';
              end if;
          end loop;

          if l_active = 'N'
          then
          end if;

      end;
      */

      l_custom_msg := 'retrieving the AR SA ID for acct id ' || sd.acct_id;
      select max(sa_id) keep(dense_rank first order by sa_status_flg)
        into l_ar_sa_id
        from ci_sa saa, ci_sa_type sat
       where saa.sa_type_cd = sat.sa_type_cd
         and sat.svc_type_cd = 'EL'
         and saa.sa_type_cd like 'E-%'
         and saa.sa_type_cd not like 'NET-%'
         and saa.sa_status_flg in ('20', '50')
         and sat.dst_id = g_ar_dst_id
         and saa.acct_id = sd.acct_id;

      l_custom_msg := 'retrieving the AR total amount for acct id ' ||
                      sd.acct_id;
      select nvl(sum(b.tot_amt), 0)
        into l_ar_balance_amt
        from ci_ft b
       where b.sa_id in (select sa_id
                           from ci_sa saa, ci_sa_type sat
                          where saa.sa_type_cd = sat.sa_type_cd
                            and sat.svc_type_cd = 'EL'
                            and saa.sa_type_cd like 'E-%'
                            and saa.sa_type_cd not like 'NET-%'
                            and saa.sa_status_flg in ('20', '40', '50')
                            and sat.dst_id = g_ar_dst_id
                            and saa.acct_id = sd.acct_id)
         and b.freeze_sw = 'Y';

      l_custom_msg := 'saving balance SA ' || sd.acct_id;
      insert into balance_sas
        (period, acct_id, sa_id, sa_month, sa_type_cd, tot_amt, cur_amt, bal_amt)
        select sd.period,
               sd.acct_id,
               ft.sa_id,
               sd.sa_month,
               sa.sa_type_cd,
               nvl(sum(ft.tot_amt), 0) tot_amt,
               nvl(sum(ft.cur_amt), 0) cur_amt,
               nvl(sum(ft.tot_amt), 0) bal_amt
          from ci_ft ft, ci_sa sa
         where ft.sa_id = sa.sa_id
           and ft.sa_id in (select saa.sa_id
                              from ci_sa saa, ci_sa_type sat
                             where saa.sa_type_cd = sat.sa_type_cd
                               and sat.svc_type_cd = 'EL'
                               and saa.sa_type_cd like 'E-%'
                               and saa.sa_type_cd not like 'NET-%'
                               and saa.sa_status_flg in ('20', '40', '50')
                               and sat.dst_id = g_ar_dst_id
                               and saa.acct_id = sd.acct_id)
           and ft.freeze_sw = 'Y'
         group by ft.sa_id, sa.sa_type_cd;

      if l_ar_sa_id is not null and trim(l_bill_cyc_cd) is not null then
        l_active := 'Y';
      else
        l_active := 'N';
      end if;

      l_custom_msg := 'retrieving the average total bill for acct id ' ||
                      sd.acct_id;
      select nvl(round(avg(bill_amt), 2), 0)
        into l_avg_bill_amt
        from (select bl.bill_id, sum(bc.calc_amt) bill_amt
                from ci_bseg bs, ci_bseg_calc bc, ci_bill bl
               where bs.bseg_id = bc.bseg_id
                 and bs.bill_id = bl.bill_id
                 and bc.header_seq = 1
                 and bs.bseg_stat_flg in ('50', '70')
                 and bl.bill_stat_flg = 'C'
                    --and    bs.bill_id = p_bill_id
                 and bl.acct_id = sd.acct_id
                 and bs.sa_id = l_ar_sa_id
                    /*and bs.end_dt > to_date('03/18/2019', 'MM/DD/YYYY') --add_months(trunc(g_sysdate_override), -12)
                    and bs.end_dt < to_date('03/19/2020', 'MM/DD/YYYY')*/ --trunc(g_sysdate_override) + 1
                 and bs.end_dt > add_months(trunc(g_sysdate_override), -12)
                 and bs.end_dt < trunc(g_sysdate_override) + 1
               group by bl.bill_id);

      l_custom_msg := 'retrieving the latest surcharge date for acct id ' ||
                      sd.acct_id;
      select max(freeze_dttm)
        into l_latest_surcharge_dt
        from ci_ft f
       where ft_type_flg like 'A%'
         and f.parent_id = 'SURCHADJ'
         and f.sa_id = l_ar_sa_id
         and f.freeze_sw = 'Y'
         and not exists (select 1
                from ci_ft fx
               where fx.sa_id = f.sa_id
                 and fx.ft_type_flg = 'AX'
                 and fx.sibling_id = f.sibling_id
                 and fx.parent_id = f.parent_id);

      /*
      select min (start_dt)
      into   l_ar_sa_start_dt
      from   ci_sa sae
      where  sae.acct_id = sd.acct_id
      and    sae.sa_id = l_ar_sa_id;

      select max (end_dt)
      into   l_ar_sa_end_dt
      from   ci_sa sae
      where  sae.acct_id = sd.acct_id
      and    sae.sa_id = l_ar_sa_id;


      if sd.sd_sa_start_dt between to_date('02/01/2006','MM/DD/YYYY') and to_date('02/21/2010','MM/DD/YYYY')
      then
          l_dsor := 'Y';

          select sum (tot_amt)
          into   l_dsor_amt
          from   ci_ft
          where  sa_id = sd.sd_sa_id
          and    freeze_sw = 'Y';
      else
          l_dsor := 'N';
      end;
      */

      l_custom_msg := 'retrieving the BD refund details for acct id ' ||
                      sd.acct_id;
      if g_du in ('25', '28') then
        select sum(tot_amt), max(freeze_dttm)
          into l_bd_refund_amt, l_bd_refund_dt
          from ci_ft f
         where ft_type_flg like 'A%'
           and f.parent_id in ('BDREFCHK', 'BDREFUND')
           and f.sa_id in ((select sa_id
                             from ci_sa
                            where sa_type_cd = g_bd_sa_type_cd
                              and acct_id = sd.acct_id))
           and f.freeze_sw = 'Y';
      elsif g_du in ('20', '21') then
        select sum(tot_amt), max(freeze_dttm)
          into l_bd_refund_amt, l_bd_refund_dt
          from ci_ft f
         where ft_type_flg like 'A%'
           and f.parent_id in ('REF-BDCH', 'REF-BDCS')
           and f.sa_id in ((select sa_id
                             from ci_sa
                            where sa_type_cd = g_bd_sa_type_cd
                              and acct_id = sd.acct_id))
           and f.freeze_sw = 'Y';
      end if;

      if l_latest_surcharge_dt is null or
         l_latest_surcharge_dt < add_months(g_sysdate_override, -36) then
        l_prompt_payor := 'Y';
      else
        l_prompt_payor := 'N';
      end if;

      if l_bd_refund_dt is not null or
         l_bd_refund_dt < add_months(g_sysdate_override, -12) and
         l_prompt_payor = 'Y' then
        l_eligible_for_bd_topup := 'N';
      else
        l_eligible_for_bd_topup := 'Y';
      end if;

      l_custom_msg := 'retrieving the revenue for acct id ' || sd.acct_id;
      if g_du in ('25', '28') then
        select nvl(sum(calc_amt), 0)
          into l_total_rev_amt
          from ci_bseg_calc_ln
         where (bseg_id, header_seq) in
               (select bs.bseg_id, bc.header_seq
                  from ci_bseg bs, ci_bseg_calc bc
                 where bs.bseg_id = bc.bseg_id
                   and bc.header_seq = 1
                   and bs.bseg_stat_flg in ('50', '70')
                   and bs.sa_id in
                       (select sa_id
                          from ci_sa saa, ci_sa_type sat
                         where saa.sa_type_cd = sat.sa_type_cd
                           and sat.svc_type_cd = 'EL'
                           and saa.sa_type_cd like 'E-%'
                           and saa.sa_type_cd not like 'NET-%'
                           and saa.sa_status_flg in ('20', '40', '50')
                           and sat.dst_id = g_ar_dst_id
                           and saa.acct_id = sd.acct_id)
                   and bs.end_dt >= l_rev_period_from
                   and bs.end_dt <= l_rev_period_to
                   and bs.bill_id in
                       (select bill_id
                          from ci_bill
                         where acct_id = sd.acct_id
                           and bill_stat_flg = 'C'))
           and (dst_id like '_-DIST%' or dst_id like '_-SFX%' or
               dst_id like '_-MFX%' or dst_id like '_-CRA%' or
               dst_id like '_-ICR%');
      elsif g_du in ('20', '21') then
        select nvl(sum(calc_amt), 0)
          into l_total_rev_amt
          from ci_bseg_calc_ln
         where (bseg_id, header_seq) in
               (select bs.bseg_id, bc.header_seq
                  from ci_bseg bs, ci_bseg_calc bc
                 where bs.bseg_id = bc.bseg_id
                   and bc.header_seq = 1
                   and bs.bseg_stat_flg in ('50', '70')
                   and bs.sa_id in
                       (select sa_id
                          from ci_sa saa, ci_sa_type sat
                         where saa.sa_type_cd = sat.sa_type_cd
                           and sat.svc_type_cd = 'EL'
                           and saa.sa_type_cd like 'E-%'
                           and saa.sa_type_cd not like 'NET-%'
                           and saa.sa_status_flg in ('20', '40', '50')
                           and sat.dst_id = g_ar_dst_id
                           and saa.acct_id = sd.acct_id)
                   and bs.end_dt >= l_rev_period_from
                   and bs.end_dt <= l_rev_period_to
                   and bs.bill_id in
                       (select bill_id
                          from ci_bill
                         where acct_id = sd.acct_id
                           and bill_stat_flg = 'C'))
           and (dst_id like 'RV-DIS%' or dst_id like 'RV-SFX%' or
               dst_id like 'RV-MFX%');
      end if;

      l_custom_msg := 'saving details for acct id ' || sd.acct_id;
      update sd_refund_accts_sa
         set acct_name               = l_acct_name,
             person_type             = l_person_type,
             bill_cyc_cd             = l_bill_cyc_cd,
             mr_rte_cd               = l_mr_rte_cd,
             address                 = l_address,
             bd_msgr                 = l_bd_msgr,
             bd_seq                  = l_bd_seq,
             prem_id                 = l_prem_id,
             parent_prem_id          = l_parent_prem_id,
             active                  = l_active,
             ar_balance_amt          = l_ar_balance_amt,
             ar_avg_bill_amt         = l_avg_bill_amt,
             prompt_payor            = l_prompt_payor,
             bd_balance_amt          = l_bd_balance_amt,
             bd_refund_amt           = l_bd_refund_amt,
             bd_refund_dt            = l_bd_refund_dt,
             wo_balance_amt          = l_wo_balance_amt,
             last_applied_rev_month  = l_last_applied_rev_month,
             rev_period_from         = l_rev_period_from,
             rev_period_to           = l_rev_period_to,
             sd_total_balance_amt    = l_sd_balance_amt,
             sd_total_parent_rev_amt = l_total_rev_amt,
             sd_total_rev_amt        = l_total_rev_amt,
             eligible_for_bd_topup   = l_eligible_for_bd_topup,
             status                  = l_status,
             remarks                 = l_remarks
       where period = sd.period
         and acct_id = sd.acct_id
         and sa_month = l_start_dt;

      commit;
    end loop;
  exception
    when others then
      l_custom_msg := 'Error @ procedure RETRIEVE_SPECIAL_DEPOSIT_ACCTS when ' ||
                      l_custom_msg;
      l_ora_errmsg := sqlerrm;
      sd_refund_pkg.log_error(l_custom_msg, l_ora_errmsg);
      raise_application_error(-20012,
                              l_custom_msg || ' : ' || l_ora_errmsg);
  end retrieve_special_deposit_accts;

  -->> SUMMARIZES PARENT CHILD REVENUE AND AMOUNT FOR REFUND
  procedure summarize_revenue is
    l_acct_name           varchar2(100);
    l_rev_amt             number;
    l_total_rev_amt       number;
    l_total_child_rev_amt number;
    l_sd_total_rev_amt    number;
    l_start_dt            varchar2(10);

    l_total_refundable_amt number;
    l_sd_total_for_bd_amt  number;
    l_sd_total_for_ar_amt  number;
    l_sd_total_for_wo_amt  number;
    l_bd_deficient_amt     number;

    l_applied_amt   number;
    l_remaining_amt number;

    l_custom_msg varchar2(1000);
    l_ora_errmsg varchar2(1000);

    l_errfound exception;
  begin
    l_start_dt   := to_char(trunc(sysdate, 'MM'), 'MM');
    load_global_variables;
    for sd in (select period,
                      acct_id,
                      sa_month,
                      prem_id,
                      rev_period_from,
                      rev_period_to,
                      sd_total_rev_amt,
                      active,
                      eligible_for_bd_topup,
                      (sd_total_balance_amt * -1) sd_total_balance_amt,
                      (nvl(bd_balance_amt, 0) * -1) bd_balance_amt,
                      ar_avg_bill_amt,
                      wo_balance_amt,
                      ar_balance_amt,
                      apt_balance_amt,
                      apwo_balance_amt,
                      apar_balance_amt
                 from sd_refund_accts_sa
                where period = g_period
                  and status = 'PENDING'
                  and sa_month = l_start_dt) loop

      l_total_child_rev_amt := 0;
      l_custom_msg          := 'retrieving the child account for acct id ' ||
                               sd.acct_id;
      for chd in (select ac.acct_id, pr.prem_id
                    from ci_prem pr, ci_acct ac
                   where ac.mailing_prem_id = pr.prem_id
                     and pr.prnt_prem_id = sd.prem_id
                     and trim(pr.prnt_prem_id) is not null) loop
        l_custom_msg := 'retrieving the name for child acct id ' ||
                        chd.acct_id;
        select trim(replace(replace(replace(replace(replace(replace(entity_name,
                                                                    ',',
                                                                    ' '),
                                                            chr(10)),
                                                    chr(13)),
                                            '?',
                                            'N'),
                                    '?',
                                    'E'),
                            chr(9),
                            ' '))
          into l_acct_name
          from ci_acct_per ap, ci_per_name pn
         where ap.per_id = pn.per_id
           and ap.acct_rel_type_cd = 'MAINCU  ' -->> main Customer
           and ap.main_cust_sw = 'Y'
           and pn.name_type_flg = 'PRIM' -->> primary Person
           and ap.acct_id = chd.acct_id;

        l_total_rev_amt := 0;
        l_custom_msg    := 'retrieving the revenue for child acct id ' ||
                           chd.acct_id;
        for ar in (select sa_id
                     from ci_sa saa, ci_sa_type sat
                    where saa.sa_type_cd = sat.sa_type_cd
                      and sat.svc_type_cd = 'EL'
                      and saa.sa_type_cd like 'E-%'
                      and saa.sa_type_cd not like 'NET-%'
                      and saa.sa_status_flg in ('20', '40', '50')
                      and sat.dst_id = g_ar_dst_id
                      and saa.acct_id = chd.acct_id)

         loop
          if g_du in ('25', '28') then
            select nvl(sum(calc_amt), 0)
              into l_rev_amt
              from ci_bseg_calc_ln
             where (bseg_id, header_seq) in
                   (select bs.bseg_id, bc.header_seq
                      from ci_bseg bs, ci_bseg_calc bc
                     where bs.bseg_id = bc.bseg_id
                       and bc.header_seq = 1
                       and bs.bseg_stat_flg in ('50', '70')
                       and bs.sa_id = ar.sa_id
                       and bs.end_dt >= sd.rev_period_from
                       and bs.end_dt <= sd.rev_period_to
                       and bs.bill_id in
                           (select bill_id
                              from ci_bill
                             where acct_id = chd.acct_id
                               and bill_stat_flg = 'C'))
               and (dst_id like '_-DIST%' or dst_id like '_-SFX%' or
                   dst_id like '_-MFX%' or dst_id like '_-CRA%' or
                   dst_id like '_-ICR%');
          elsif g_du in ('20', '21') then
            select nvl(sum(calc_amt), 0)
              into l_rev_amt
              from ci_bseg_calc_ln
             where (bseg_id, header_seq) in
                   (select bs.bseg_id, bc.header_seq
                      from ci_bseg bs, ci_bseg_calc bc
                     where bs.bseg_id = bc.bseg_id
                       and bc.header_seq = 1
                       and bs.bseg_stat_flg in ('50', '70')
                       and bs.sa_id = ar.sa_id
                       and bs.end_dt >= sd.rev_period_from
                       and bs.end_dt <= sd.rev_period_to
                       and bs.bill_id in
                           (select bill_id
                              from ci_bill
                             where acct_id = chd.acct_id
                               and bill_stat_flg = 'C'))
               and (dst_id like 'RV-DIS%' or dst_id like 'RV-SFX%' or
                   dst_id like 'RV-MFX%');
          end if;
          l_total_rev_amt := l_total_rev_amt + nvl(l_rev_amt, 0);
        end loop;

        l_custom_msg := 'saving details for child acct id ' || chd.acct_id;
        if l_total_rev_amt > 0 then
          l_total_child_rev_amt := l_total_child_rev_amt + l_total_rev_amt;
          insert into sd_refund_parent_child_accts
            (period,
             acct_id,
             prem_id,
             child_acct_id,
             child_prem_id,
             child_acct_name,
             child_tot_rev_amt)
          values
            (sd.period,
             sd.acct_id,
             sd.prem_id,
             chd.acct_id,
             chd.prem_id,
             l_acct_name,
             l_total_rev_amt);
        end if;
      end loop;

      l_sd_total_rev_amt := nvl(sd.sd_total_rev_amt, 0) +
                            l_total_child_rev_amt;

      l_custom_msg           := 'computing refundable amount for acct id ' ||
                                sd.acct_id;
      l_sd_total_for_bd_amt  := 0;
      l_sd_total_for_ar_amt  := 0;
      l_sd_total_for_wo_amt  := 0;
      l_total_refundable_amt := sd.sd_total_balance_amt;

      if sd.active = 'N' then
        if l_total_refundable_amt > 0 then
          if sd.wo_balance_amt > 0 then
            if l_total_refundable_amt > sd.wo_balance_amt then
              l_sd_total_for_wo_amt := sd.wo_balance_amt;
            else
              l_sd_total_for_wo_amt := l_total_refundable_amt;
            end if;
          end if;

          l_total_refundable_amt := l_total_refundable_amt -
                                    l_sd_total_for_wo_amt;

        end if;

        if l_total_refundable_amt > 0 then
          if sd.ar_balance_amt > 0 then
            if l_total_refundable_amt > sd.ar_balance_amt then
              l_sd_total_for_ar_amt := sd.ar_balance_amt;
            else
              l_sd_total_for_ar_amt := l_total_refundable_amt;
            end if;
          end if;
          l_total_refundable_amt := l_total_refundable_amt -
                                    l_sd_total_for_ar_amt;

        end if;

        l_total_refundable_amt := least(round((l_sd_total_rev_amt * .75), 2),
                                        l_total_refundable_amt);

      else
        if l_total_refundable_amt > 0 or sd.apt_balance_amt > 0 then
          if (sd.ar_avg_bill_amt * 0.90) > nvl(sd.bd_balance_amt, 0) and
             sd.active = 'Y' and sd.eligible_for_bd_topup = 'Y' then
            l_bd_deficient_amt := sd.ar_avg_bill_amt -
                                  nvl(sd.bd_balance_amt, 0);
            if l_total_refundable_amt > l_bd_deficient_amt then
              l_sd_total_for_bd_amt := l_bd_deficient_amt;
            else
              l_sd_total_for_bd_amt := l_total_refundable_amt;
            end if;
          end if;

          l_total_refundable_amt := l_total_refundable_amt -
                                    l_sd_total_for_bd_amt;

          l_total_refundable_amt := least(round((l_sd_total_rev_amt * .75),
                                                2),
                                          l_total_refundable_amt);

        end if;
      end if;

      l_custom_msg := 'saving details for acct id ' || sd.acct_id;
      update sd_refund_accts_sa
         set sd_total_child_rev_amt  = nvl(l_total_child_rev_amt, 0),
             sd_total_rev_amt        = nvl(l_sd_total_rev_amt, 0),
             sd_total_for_bd_amt     = nvl(l_sd_total_for_bd_amt, 0),
             sd_total_for_ar_amt     = nvl(l_sd_total_for_ar_amt, 0),
             sd_total_for_wo_amt     = nvl(l_sd_total_for_wo_amt, 0),
             sd_total_for_refund_amt = nvl(l_total_refundable_amt, 0),
             status                  = 'FORUPLOAD'
       where period = sd.period
         and acct_id = sd.acct_id
         and sa_month = sd.sa_month;

      for tot in (select 'WO' atype, l_sd_total_for_wo_amt amount
                    from dual
                  union all
                  select 'AR' atype, l_sd_total_for_ar_amt amount
                    from dual
                  union all
                  select 'BD' atype, l_sd_total_for_bd_amt amount
                    from dual
                  union all
                  select 'REFUND' atype, l_total_refundable_amt amount
                    from dual) loop
        if tot.amount > 0 then
          l_applied_amt   := 0;
          l_remaining_amt := tot.amount;
          l_custom_msg    := 'computing ' || tot.atype ||
                             ' adjustment for acct id ' || sd.acct_id;
          for sdsa in (select sd_sa_id,
                              (sd_balance_amt * -1) - nvl(sd_for_bd_amt, 0) -
                              nvl(sd_for_ar_amt, 0) - nvl(sd_for_wo_amt, 0) -
                              nvl(sd_for_refund_amt, 0) sd_balance_amt,
                              decode(sd_balance_amt,
                                     sd_curr_balance_amt,
                                     'N',
                                     'Y') unmatched
                         from sd_refund_sa
                        where period = sd.period
                          and acct_id = sd.acct_id
                        order by sd_sa_start_dt) loop

            l_custom_msg := 'computing ' || tot.atype ||
                            ' adjustment for SA ID ' || sdsa.sd_sa_id;

            if l_remaining_amt > 0 and sdsa.sd_balance_amt > 0 then
              if l_remaining_amt > sdsa.sd_balance_amt then
                l_applied_amt := sdsa.sd_balance_amt;
              else
                l_applied_amt := l_remaining_amt;
              end if;
              l_remaining_amt := l_remaining_amt - l_applied_amt;

              if tot.atype = 'WO' then
                update sd_refund_sa
                   set sd_for_wo_amt = l_applied_amt
                 where period = sd.period
                   and acct_id = sd.acct_id
                   and sd_sa_id = sdsa.sd_sa_id;
              end if;
              if tot.atype = 'AR' then
                update sd_refund_sa
                   set sd_for_ar_amt = l_applied_amt
                 where period = sd.period
                   and acct_id = sd.acct_id
                   and sd_sa_id = sdsa.sd_sa_id;
              end if;
              if tot.atype = 'BD' then
                update sd_refund_sa
                   set sd_for_bd_amt = l_applied_amt
                 where period = sd.period
                   and acct_id = sd.acct_id
                   and sd_sa_id = sdsa.sd_sa_id;

              end if;
              if tot.atype = 'REFUND' then
                update sd_refund_sa
                   set sd_for_refund_amt = l_applied_amt
                 where period = sd.period
                   and acct_id = sd.acct_id
                   and sd_sa_id = sdsa.sd_sa_id;

              end if;
            end if;
          end loop;

          if l_remaining_amt > 0 then
            l_custom_msg := 'Acct ID ' || sd.acct_id ||
                            ' has insufficient ' || tot.atype || ' amount. ' || l_remaining_amt || ' - ' || l_applied_amt || ' -- ' || l_total_refundable_amt;
            raise l_errfound;
          end if;
        end if;
      end loop;
    end loop;
    commit;
  exception
    when l_errfound then
      raise_application_error(-20011, l_custom_msg);
    when others then
      l_custom_msg := 'Error @ procedure SUMMARIZE_REVENUE when ' ||
                      l_custom_msg;
      l_ora_errmsg := sqlerrm;
      log_error(l_custom_msg, l_ora_errmsg);
      raise_application_error(-20012,
                              l_custom_msg || ' : ' || l_ora_errmsg);
  end summarize_revenue;

  -->> PREPARE SA AND COMPUTE ADJUSTMENTS
  procedure prepare_sa_adjustments is
    /*l_acct_name varchar2(100);*/

    l_env_id       f1_installation.env_id%type;
    l_cis_division ci_acct.cis_division%type;
    l_old_acct_id  ci_sa.old_acct_id%type;
    l_bd_sa_id     ci_sa.sa_id%type;
    l_dep_cl_cd    ci_sa_type.dep_cl_cd%type;

    l_cc_id    ci_cc.cc_id%type;
    l_cc_line1 varchar2(3000);
    l_cc_line2 varchar2(3000);
    l_cc_line3 varchar2(3000);
    l_cc_line4 varchar2(3000);
    l_cc_line5 varchar2(3000);

    l_apref_per_id        ci_acct_per.per_id%type;
    l_apbd_per_id         ci_acct_per.per_id%type;
    l_apbdrf_per_id       ci_acct_per.per_id%type;
    l_apwo_per_id         ci_acct_per.per_id%type;
    l_apar_per_id         ci_acct_per.per_id%type;
    l_sd_balance_amt      number;
    l_sd_curr_balance_amt number;
    l_start_dt            varchar2(10);

    l_remaining_amt number;
    l_amount        number;

    l_adj_type_cd sd_refund_adjustment_trans.adj_type_cd%type;

    l_msg        varchar2(1000);
    l_err_found  exception;
    l_custom_msg varchar2(1000);
    l_ora_errmsg varchar2(1000);
  begin
    load_global_variables;
    l_start_dt   := to_char(trunc(sysdate, 'MM'), 'MM');

    select env_id into l_env_id from f1_installation;

    for sd in (select period,
                      acct_id,
                      sa_month,
                      prem_id,
                      rev_period_from,
                      rev_period_to,
                      active,
                      nvl(abs(sd_total_balance_amt), 0) sd_total_balance_amt,
                      ar_balance_amt,
                      ar_avg_bill_amt,
                      wo_balance_amt,
                      (case
                        when nvl(abs(sd_total_balance_amt), 0) >
                             nvl(wo_balance_amt, 0) then
                         nvl(abs(sd_total_balance_amt), 0) -
                         nvl(wo_balance_amt, 0)
                        else
                         nvl(abs(sd_total_balance_amt), 0) -
                         nvl(abs(sd_total_balance_amt), 0)
                      end) sd_applied_wo,
                      (case
                        when nvl(abs(sd_total_balance_amt), 0) >
                             nvl(ar_balance_amt, 0) then
                         nvl(abs(sd_total_balance_amt), 0) -
                         nvl(ar_balance_amt, 0)
                        else
                         nvl(abs(sd_total_balance_amt), 0) -
                         nvl(abs(sd_total_balance_amt), 0)
                      end) sd_applied_ar,
                      (nvl(bd_balance_amt, 0) * -1) bd_balance_amt, --active, eligible_for_bd_topup,
                      --sd_total_rev_amt, (sd_total_balance_amt * -1) sd_total_balance_amt, (nvl(bd_balance_amt,0) * -1) bd_balance_amt, ar_avg_bill_amt, wo_balance_amt, ar_balance_amt
                      nvl(sd_total_for_bd_amt, 0) sd_total_for_bd_amt,
                      nvl(sd_total_for_wo_amt, 0) sd_total_for_wo_amt,
                      nvl(sd_total_for_ar_amt, 0) sd_total_for_ar_amt,
                      nvl(sd_total_for_refund_amt, 0) sd_total_for_refund_amt,
                      nvl(apt_balance_amt, 0) apt_balance_amt,
                      nvl(apwo_balance_amt, 0) apwo_balance_amt,
                      nvl(apar_balance_amt, 0) apar_balance_amt
                 from sd_refund_accts_sa
                where period = g_period
                  and status = 'FORUPLOAD'
                  and sa_month = l_start_dt) loop

      select cis_division, ' '
        into l_cis_division, l_old_acct_id
        from ci_acct
       where acct_id = sd.acct_id;

      -->> CREATE BD SA
      if sd.sd_total_for_bd_amt > 0 then
        l_custom_msg := 'retrieving existing BD SA for acct id ' ||
                        sd.acct_id;
        select max(sa_id) keep(dense_rank first order by sa_status_flg)
          into l_bd_sa_id
          from ci_sa
         where sa_type_cd = g_bd_sa_type_cd
           and acct_id = sd.acct_id
           and sa_status_flg in ('20', '50');

        if l_bd_sa_id is null then
          loop
            begin
              select substr(sd.acct_id, 1, 6) ||
                     lpad(trunc(dbms_random.value(0000, 9999)), 4, '0')
                into l_bd_sa_id
                from dual;
              insert into ci_sa_k
                (sa_id, env_id)
              values
                (l_bd_sa_id, l_env_id);

              exit;
            exception
              when dup_val_on_index then
                null;
            end;
          end loop;

          l_custom_msg := 'creating new BD SA for acct id ' || sd.acct_id;
          insert into ci_sa
            (sa_id,
             prop_dcl_rsn_cd,
             prop_sa_id,
             cis_division,
             sa_type_cd,
             start_opt_cd,
             start_dt,
             sa_status_flg,
             acct_id,
             end_dt,
             old_acct_id,
             cust_read_flg,
             allow_est_sw,
             sic_cd,
             char_prem_id,
             tot_to_bill_amt,
             currency_cd,
             version,
             sa_rel_id,
             strt_rsn_flg,
             stop_rsn_flg,
             strt_reqed_by,
             stop_reqed_by,
             high_bill_amt,
             int_calc_dt,
             ciac_review_dt,
             bus_activity_desc,
             ib_sa_cutoff_tm,
             ib_base_tm_day_flg,
             enrl_id,
             special_usage_flg,
             prop_sa_stat_flg,
             nbr_pymnt_periods,
             nb_rule_cd,
             expire_dt,
             renewal_dt,
             nb_apay_flg)
          values
            (l_bd_sa_id,
             ' ', --prop_dcl_rsn_cd,
             ' ', --prop_sa_id,
             l_cis_division,
             g_bd_sa_type_cd,
             ' ', --start_opt_cd,
             trunc(sysdate), --start_dt,
             '20', --sa_status_flg,
             sd.acct_id,
             null, --end_dt,
             l_old_acct_id,
             'N', --cust_read_flg,
             'N', --allow_est_sw,
             ' ', --sic_cd,
             ' ', --char_prem_id,
             sd.sd_total_for_bd_amt + sd.bd_balance_amt, --tot_to_bill_amt,
             'PHP', --currency_cd,
             1, --version,
             ' ', --sa_rel_id,
             'S', --strt_rsn_flg,
             ' ', --stop_rsn_flg,
             'SYSTEM', --strt_reqed_by,
             ' ', --stop_reqed_by,
             0, --high_bill_amt,
             null, --int_calc_dt,
             null, --ciac_review_dt,
             ' ', --bus_activity_desc,
             null, --ib_sa_cutoff_tm,
             ' ', --ib_base_tm_day_flg,
             ' ', --enrl_id,
             ' ', --special_usage_flg,
             ' ', --prop_sa_stat_flg,
             0, --nbr_pymnt_periods,
             ' ', --nb_rule_cd,
             null, --expire_dt,
             null, --renewal_dt,
             ' ' --nb_apay_flg
             );

        else
          select sat.dep_cl_cd
            into l_dep_cl_cd
            from ci_sa sa, ci_sa_type sat
           where sa.cis_division = sat.cis_division(+)
             and sa.sa_type_cd = sat.sa_type_cd(+)
             and sa.sa_id = l_bd_sa_id;

          update ci_dep_rvw
             set dep_amt_on_hand = sd.sd_total_for_bd_amt +
                                   sd.bd_balance_amt
           where acct_id = sd.acct_id
             and dep_cl_cd = l_dep_cl_cd;

          update ci_sa
             set tot_to_bill_amt = sd.sd_total_for_bd_amt +
                                   sd.bd_balance_amt
           where sa_id = l_bd_sa_id;
        end if;

        l_remaining_amt := sd.sd_total_for_bd_amt;
        l_custom_msg    := 'preparing BD adjustment for acct id ' ||
                           sd.acct_id;
        for sdsa in (select sd_sa_id,
                            sd_for_bd_amt amount,
                            decode(sd_balance_amt,
                                   sd_curr_balance_amt,
                                   'N',
                                   'Y') unmatched
                       from sd_refund_sa
                      where period = sd.period
                        and acct_id = sd.acct_id
                        and sd_for_bd_amt > 0
                      order by sd_sa_start_dt) loop
          if sdsa.unmatched = 'Y' then
            l_adj_type_cd := 'XFER-PYO';
          else
            l_adj_type_cd := 'XFER';
          end if;

          l_remaining_amt := l_remaining_amt - sdsa.amount;

          insert into sd_refund_adjustment_trans
            (period,
             acct_id,
             sa_id,
             adj_type_cd,
             bill_msg_cd,
             bill_cyc_cd,
             eff_dt,
             amount,
             remarks,
             status)
          values
            (sd.period,
             sd.acct_id,
             sdsa.sd_sa_id,
             l_adj_type_cd,
             '',
             '',
             trunc(sysdate),
             sdsa.amount,
             'Amount from SD to BD',
             'PENDING');
        end loop;

        if l_remaining_amt > 0 then
          l_msg := 'Acct ID ' || sd.acct_id ||
                   ' has an unbalanced BD amount for reclass.';
          raise l_err_found;
        else
          insert into sd_refund_adjustment_trans
            (period,
             acct_id,
             sa_id,
             adj_type_cd,
             bill_msg_cd,
             bill_cyc_cd,
             eff_dt,
             amount,
             remarks,
             status)
          values
            (sd.period,
             sd.acct_id,
             l_bd_sa_id,
             'XFER-PYO',
             '',
             '',
             trunc(sysdate),
             sd.sd_total_for_bd_amt * -1,
             'Amount from SD to BD',
             'PENDING');
        end if;
      end if;

      if sd.sd_total_for_wo_amt > 0 then

        l_custom_msg := 'preparing WO adjustment for acct id ' ||
                        sd.acct_id;

        select nvl(sum(sd_balance_amt), 0) tot_amt,
               nvl(sum(sd_curr_balance_amt), 0) cur_amt
          into l_sd_balance_amt, l_sd_curr_balance_amt
          from sd_refund_sa
         where period = sd.period
           and acct_id = sd.acct_id
           and sd_for_ar_amt > 0
         order by sd_sa_start_dt;

        if (l_sd_curr_balance_amt = l_sd_balance_amt) then
          l_adj_type_cd := 'XFER-CA';
        else
          l_adj_type_cd := 'XFER-PYO';
        end if;

        begin
          for l_bal_cur in (select period,
                                   acct_id,
                                   sa_id,
                                   sa_month,
                                   sa_type_cd,
                                   tot_amt,
                                   cur_amt,
                                   bal_amt
                              from balance_sas
                             where period = sd.period
                               and acct_id = sd.acct_id
                               and sa_month = sd.sa_month
                               and bal_amt > 0) loop

            declare
              l_bal_amount number;
            begin
              l_bal_amount := l_bal_cur.bal_amt;

              for l_cur_bd in (select period,
                                      acct_id,
                                      sa_id,
                                      sa_type_cd,
                                      tot_amt,
                                      cur_amt,
                                      bal_amt
                                 from deposit_sas
                                where period = sd.period
                                  and acct_id = sd.acct_id
                                  and sa_month = sd.sa_month
                                  and bal_amt > 0) loop

                declare
                  l_adj_amount number;
                begin
                  if (l_bal_amount >= l_cur_bd.bal_amt) then
                    l_adj_amount := l_cur_bd.bal_amt;
                  elsif (l_bal_amount < l_cur_bd.bal_amt) then
                    l_adj_amount := l_bal_amount;
                  end if;

                  insert into sd_adj_trans
                    (period,
                     acct_id,
                     sa_id_from,
                     sa_id_to,
                     adj_type_cd_from,
                     adj_type_cd_to,
                     amount,
                     remarks,
                     status,
                     created_on,
                     created_by)
                  values
                    (sd.period,
                     sd.acct_id,
                     l_cur_bd.sa_id,
                     l_bal_cur.sa_id,
                     l_adj_type_cd,
                     'XFER-CA',
                     l_adj_amount,
                     'Amount from SD to AP WO',
                     'PENDING',
                     sysdate,
                     'SYSUSER');

                  update deposit_sas
                     set bal_amt = bal_amt - l_adj_amount
                   where period = l_cur_bd.period
                     and acct_id = l_cur_bd.acct_id
                     and sa_id = l_cur_bd.sa_id;

                  update balance_sas
                     set bal_amt = bal_amt - l_adj_amount
                   where period = l_cur_bd.period
                     and acct_id = l_cur_bd.acct_id
                     and sa_id = l_bal_cur.sa_id;

                  l_bal_amount := l_bal_amount - l_adj_amount;

                  if l_bal_amount <= 0 then
                    exit;
                  end if;
                end;

              end loop;

            end;

          end loop;
        end;
      end if;

      if sd.sd_total_for_ar_amt > 0 then
        l_remaining_amt := sd.sd_total_for_ar_amt;
        l_custom_msg    := 'preparing AR adjustment for acct id ' ||
                           sd.acct_id;

        select nvl(sum(sd_balance_amt), 0) tot_amt,
               nvl(sum(sd_curr_balance_amt), 0) cur_amt
          into l_sd_balance_amt, l_sd_curr_balance_amt
          from sd_refund_sa
         where period = sd.period
           and acct_id = sd.acct_id
           and sd_for_ar_amt > 0
         order by sd_sa_start_dt;

        if (l_sd_curr_balance_amt = l_sd_balance_amt) then
          l_adj_type_cd := 'XFER-CA';
        else
          l_adj_type_cd := 'XFER-PYO';
        end if;

        begin
          for l_bal_cur in (select period,
                                   acct_id,
                                   sa_id,
                                   sa_type_cd,
                                   tot_amt,
                                   cur_amt,
                                   bal_amt
                              from balance_sas
                             where period = sd.period
                               and acct_id = sd.acct_id
                               and sa_month = sd.sa_month
                               and bal_amt > 0) loop

            declare
              l_bal_amount number;
            begin
              l_bal_amount := l_bal_cur.bal_amt;

              for l_cur_bd in (select period,
                                      acct_id,
                                      sa_id,
                                      sa_type_cd,
                                      tot_amt,
                                      cur_amt,
                                      bal_amt
                                 from deposit_sas
                                where period = sd.period
                                  and acct_id = sd.acct_id
                                  and sa_month = sd.sa_month
                                  and bal_amt > 0) loop

                declare
                  l_adj_amount number;
                begin
                  if (l_bal_amount >= l_cur_bd.bal_amt) then
                    l_adj_amount := l_cur_bd.bal_amt;
                  elsif (l_bal_amount < l_cur_bd.bal_amt) then
                    l_adj_amount := l_bal_amount;
                  end if;

                  insert into sd_adj_trans
                    (period,
                     acct_id,
                     sa_id_from,
                     sa_id_to,
                     adj_type_cd_from,
                     adj_type_cd_to,
                     amount,
                     remarks,
                     status,
                     created_on,
                     created_by)
                  values
                    (sd.period,
                     sd.acct_id,
                     l_cur_bd.sa_id,
                     l_bal_cur.sa_id,
                     l_adj_type_cd,
                     'XFER-CA',
                     l_adj_amount,
                     'Amount from SD to AR SA',
                     'PENDING',
                     sysdate,
                     'SYSUSER');

                  update deposit_sas
                     set bal_amt = bal_amt - l_adj_amount
                   where period = l_cur_bd.period
                     and acct_id = l_cur_bd.acct_id
                     and sa_id = l_cur_bd.sa_id;

                  update balance_sas
                     set bal_amt = bal_amt - l_adj_amount
                   where period = l_bal_cur.period
                     and acct_id = l_bal_cur.acct_id
                     and sa_id = l_bal_cur.sa_id;

                  l_bal_amount := l_bal_amount - l_adj_amount;

                  if l_bal_amount <= 0 then
                    exit;
                  end if;
                end;

              end loop;

            end;

          end loop;
        end;
      end if;

      --> customer contact
      if sd.active = 'Y' then
        --> For refund only Customer Contact
        if (sd.sd_total_for_refund_amt > 0 or sd.apt_balance_amt > 0) and
           sd.sd_total_for_bd_amt = 0 then
          l_custom_msg := 'retrieving per id for A/P-REF for populating customer contact ' ||
                          sd.acct_id;

          -->> CREATE Customer Contact
          select cap.per_id
            into l_apref_per_id
            from ci_acct_per cap
           where cap.acct_rel_type_cd = 'MAINCU  '
             and cap.main_cust_sw = 'Y'
             and acct_id = sd.acct_id;

          if l_apref_per_id is not null then
            l_custom_msg := 'creating A/P-REF CC ID SA for acct id ' ||
                            sd.acct_id;

            l_cc_line1 := 'Account ID : ' || sd.acct_id || chr(13) ||
                          'Special Deposit Refund Amt. : ' ||
                          sd.sd_total_for_refund_amt;
            l_cc_line2 := 'Existing APT Refund : ' || sd.apt_balance_amt;
            l_cc_line3 := 'Total SD for Refund : ' ||
                          (sd.sd_total_for_refund_amt + sd.apt_balance_amt);
            l_cc_line4 := l_cc_line1 || chr(13) || chr(10) || l_cc_line2 ||
                          chr(13) || chr(10) || l_cc_line3;

            l_cc_id := substr(l_apref_per_id, 1, 6) ||
                       trunc(dbms_random.value(1000, 9999));

            insert into ci_cc_k (cc_id, env_id) values (l_cc_id, l_env_id);

            insert into ci_cc
              (cc_id,
               user_id,
               per_id,
               cc_dttm,
               cc_cl_cd,
               cc_type_cd,
               print_letter_sw,
               batch_nbr,
               --cc_status_flg,
               descrlong)
            values
              (l_cc_id,
               'SYSUSER',
               l_apref_per_id, --l_per_id,
               sysdate,
               'INQY',
               '14',
               'N',
               0,
               --'    ',
               l_cc_line4);
          else
            l_msg := 'Acct ID ' || sd.acct_id || ' has no Person ID.';
            raise l_err_found;
          end if;
        end if;

        --> For BD Customer Contact
        if sd.sd_total_for_bd_amt > 0 and
           (sd.sd_total_for_refund_amt = 0 and sd.apt_balance_amt = 0) then
          l_custom_msg := 'retrieving per id for BD for populating customer contact ' ||
                          sd.acct_id;

          -->> CREATE Customer Contact
          select cap.per_id
            into l_apbd_per_id
            from ci_acct_per cap
           where cap.acct_rel_type_cd = 'MAINCU  '
             and cap.main_cust_sw = 'Y'
             and acct_id = sd.acct_id;

          if l_apbd_per_id is not null then
            l_custom_msg := 'creating BD CC ID SA for acct id ' ||
                            sd.acct_id;

            l_cc_line1 := 'Account ID : ' || sd.acct_id || chr(13) ||
                          'BD Topup amount (YR) : ' ||
                          sd.sd_total_for_bd_amt;
            l_cc_line2 := 'Existing BD Balance Prior to Top up : ' ||
                          sd.bd_balance_amt;
            l_cc_line3 := 'Total BD after Top up : ' ||
                          (sd.sd_total_for_bd_amt + sd.bd_balance_amt);
            l_cc_line4 := l_cc_line1 || chr(13) || chr(10) || l_cc_line2 ||
                          chr(13) || chr(10) || l_cc_line3;

            l_cc_id := substr(l_apbd_per_id, 1, 6) ||
                       trunc(dbms_random.value(1000, 9999));

            insert into ci_cc_k (cc_id, env_id) values (l_cc_id, l_env_id);

            insert into ci_cc
              (cc_id,
               user_id,
               per_id,
               cc_dttm,
               cc_cl_cd,
               cc_type_cd,
               print_letter_sw,
               batch_nbr,
               --cc_status_flg,
               descrlong)
            values
              (l_cc_id,
               'SYSUSER',
               l_apbd_per_id, --l_per_id,
               sysdate,
               'INQY',
               '14',
               'N',
               0,
               --'    ',
               l_cc_line4);
          else
            l_msg := 'Acct ID ' || sd.acct_id || ' has no Person ID.';
            raise l_err_found;
          end if;
        end if;

        -- For BD + Refund Customer Contact
        if sd.sd_total_for_bd_amt > 0 and
           (sd.sd_total_for_refund_amt > 0 or sd.apt_balance_amt > 0) then
          l_custom_msg := 'retrieving per id for BD for populating customer contact ' ||
                          sd.acct_id;

          -->> CREATE Customer Contact
          select cap.per_id
            into l_apbdrf_per_id
            from ci_acct_per cap
           where cap.acct_rel_type_cd = 'MAINCU  '
             and cap.main_cust_sw = 'Y'
             and acct_id = sd.acct_id;

          if l_apbdrf_per_id is not null then
            l_custom_msg    := 'creating BD CC ID SA for acct id ' ||
                               sd.acct_id;
            l_remaining_amt := sd.sd_total_for_refund_amt;

            l_remaining_amt := l_remaining_amt - l_amount;

            l_cc_line1 := 'Special Deposit Refund Amt. : ' ||
                          sd.sd_total_for_refund_amt;
            l_cc_line2 := 'Existing APT Refund : ' || sd.apt_balance_amt;
            l_cc_line3 := 'Total SD for Refund : ' ||
                          (sd.sd_total_for_refund_amt + sd.apt_balance_amt);
            l_cc_line4 := l_cc_line1 || chr(13) || chr(10) || l_cc_line2 ||
                          chr(13) || chr(10) || l_cc_line3;
            l_cc_line5 := l_cc_line4;

            l_cc_line1 := 'Account ID : ' || sd.acct_id || chr(13) ||
                          'BD Topup amount (YR) : ' ||
                          sd.sd_total_for_bd_amt;
            l_cc_line2 := 'Existing BD Balance Prior to Top up : ' ||
                          sd.bd_balance_amt;
            l_cc_line3 := 'Total BD after Top up : ' ||
                          (sd.sd_total_for_bd_amt + sd.bd_balance_amt);
            l_cc_line4 := l_cc_line1 || chr(13) || chr(10) || l_cc_line2 ||
                          chr(13) || chr(10) || l_cc_line3;

            l_cc_id := substr(l_apbdrf_per_id, 1, 6) ||
                       trunc(dbms_random.value(1000, 9999));

            insert into ci_cc_k (cc_id, env_id) values (l_cc_id, l_env_id);

            insert into ci_cc
              (cc_id,
               user_id,
               per_id,
               cc_dttm,
               cc_cl_cd,
               cc_type_cd,
               print_letter_sw,
               batch_nbr,
               --cc_status_flg,
               descrlong)
            values
              (l_cc_id,
               'SYSUSER',
               l_apbdrf_per_id, --l_per_id,
               sysdate,
               'INQY',
               '14',
               'N',
               0,
               --'    ',
               l_cc_line4 || chr(13) || chr(13) || chr(13) || chr(10) ||
               chr(13) || chr(10) || l_cc_line5);
          else
            l_msg := 'Acct ID ' || sd.acct_id || ' has no Person ID.';
            raise l_err_found;
          end if;
        end if;

      else
        -->For WO Customer Contact
        if (sd.sd_total_for_wo_amt > 0 or sd.apwo_balance_amt > 0) and
           sd.sd_total_for_refund_amt = 0 then
          l_custom_msg := 'retrieving per id for A/P-WO for populating customer contact ' ||
                          sd.acct_id;

          -->> CREATE Customer Contact
          select cap.per_id
            into l_apwo_per_id
            from ci_acct_per cap
           where cap.acct_rel_type_cd = 'MAINCU  '
             and cap.main_cust_sw = 'Y'
             and acct_id = sd.acct_id;

          if l_apwo_per_id is not null then
            l_custom_msg := 'creating A/P-WO CC ID SA for acct id ' ||
                            sd.acct_id;

            l_cc_line1 := 'Account ID : ' || sd.acct_id || chr(13) ||
                          'SD Apply to WO (YR) : ' ||
                          sd.sd_total_balance_amt;
            l_cc_line2 := 'Existing WO Balance : ' || sd.wo_balance_amt;
            l_cc_line3 := 'Total SD Amount after application to WO SA : ' ||
                          sd.sd_applied_wo;
            l_cc_line4 := l_cc_line1 || chr(13) || chr(10) || l_cc_line2 ||
                          chr(13) || chr(10) || l_cc_line3;

            l_cc_id := substr(l_apwo_per_id, 1, 6) ||
                       trunc(dbms_random.value(1000, 9999));

            insert into ci_cc_k (cc_id, env_id) values (l_cc_id, l_env_id);

            insert into ci_cc
              (cc_id,
               user_id,
               per_id,
               cc_dttm,
               cc_cl_cd,
               cc_type_cd,
               print_letter_sw,
               batch_nbr,
               --cc_status_flg,
               descrlong)
            values
              (l_cc_id,
               'SYSUSER',
               l_apwo_per_id, --l_per_id,
               sysdate,
               'INQY',
               '14',
               'N',
               0,
               --'    ',
               l_cc_line4);
          else
            l_msg := 'Acct ID ' || sd.acct_id || ' has no Person ID. here ';
            raise l_err_found;
          end if;
        end if;

        -->For WO Customer Contact + Refund
        if (sd.sd_total_for_wo_amt > 0 or sd.apwo_balance_amt > 0) and
           sd.sd_total_for_refund_amt > sd.sd_total_for_wo_amt then
          l_custom_msg := 'retrieving per id for A/P-WO for populating customer contact ' ||
                          sd.acct_id;

          -->> CREATE Customer Contact
          select cap.per_id
            into l_apwo_per_id
            from ci_acct_per cap
           where cap.acct_rel_type_cd = 'MAINCU  '
             and cap.main_cust_sw = 'Y'
             and acct_id = sd.acct_id;

          if l_apwo_per_id is not null then
            l_custom_msg := 'creating WO CC ID SA for acct id ' ||
                            sd.acct_id;

            l_cc_line1 := 'Special Deposit Refund Amt. : ' ||
                          sd.sd_total_for_refund_amt;
            l_cc_line2 := 'Existing APT Refund : ' || sd.apt_balance_amt;
            l_cc_line3 := 'Total SD for Refund : ' ||
                          (sd.sd_total_for_refund_amt + sd.apt_balance_amt);
            l_cc_line4 := l_cc_line1 || chr(13) || chr(10) || l_cc_line2 ||
                          chr(13) || chr(10) || l_cc_line3;
            l_cc_line5 := l_cc_line4;

            l_cc_line1 := 'Account ID : ' || sd.acct_id || chr(13) ||
                          'SD Apply to WO (YR) : ' ||
                          sd.sd_total_balance_amt;
            l_cc_line2 := 'Existing WO Balance : ' || sd.wo_balance_amt;
            l_cc_line3 := 'Total SD Amount after application to WO SA : ' ||
                          sd.sd_applied_wo;
            l_cc_line4 := l_cc_line1 || chr(13) || chr(10) || l_cc_line2 ||
                          chr(13) || chr(10) || l_cc_line3;

            l_cc_id := substr(l_apwo_per_id, 1, 6) ||
                       trunc(dbms_random.value(1000, 9999));

            insert into ci_cc_k (cc_id, env_id) values (l_cc_id, l_env_id);

            insert into ci_cc
              (cc_id,
               user_id,
               per_id,
               cc_dttm,
               cc_cl_cd,
               cc_type_cd,
               print_letter_sw,
               batch_nbr,
               --cc_status_flg,
               descrlong)
            values
              (l_cc_id,
               'SYSUSER',
               l_apwo_per_id, --l_per_id,
               sysdate,
               'INQY',
               '14',
               'N',
               0,
               --'    ',
               l_cc_line4 || chr(13) || chr(13) || chr(13) || chr(10) ||
               chr(13) || chr(10) || l_cc_line5);
          else
            l_msg := 'Acct ID ' || sd.acct_id || ' has no Person ID. here';
            raise l_err_found;
          end if;

        end if;

        -- For refund with no AR
        if sd.sd_total_for_refund_amt > 0 and sd.sd_total_for_ar_amt = 0 and
           sd.sd_total_for_wo_amt = 0 and sd.apwo_balance_amt = 0 then
          l_custom_msg := 'retrieving per id for AR for populating customer contact ' ||
                          sd.acct_id;

          -->> CREATE Customer Contact
          select cap.per_id
            into l_apref_per_id
            from ci_acct_per cap
           where cap.acct_rel_type_cd = 'MAINCU  '
             and cap.main_cust_sw = 'Y'
             and acct_id = sd.acct_id;

          if l_apref_per_id is not null then
            l_custom_msg := 'creating AR CC ID SA for acct id ' ||
                            sd.acct_id;

            l_cc_line1 := 'Account ID : ' || sd.acct_id || chr(13) ||
                          'Special Deposit Refund Amt : ' ||
                          sd.sd_total_for_refund_amt;
            l_cc_line2 := 'Existing APT Refund : ' || sd.apt_balance_amt;
            l_cc_line3 := 'Total SD for Refund : ' ||
                          (sd.sd_total_for_refund_amt + sd.apt_balance_amt);
            l_cc_line4 := l_cc_line1 || chr(13) || chr(10) || l_cc_line2 ||
                          chr(13) || chr(10) || l_cc_line3;

            l_cc_id := substr(l_apref_per_id, 1, 6) ||
                       trunc(dbms_random.value(1000, 9999));

            insert into ci_cc_k (cc_id, env_id) values (l_cc_id, l_env_id);

            insert into ci_cc
              (cc_id,
               user_id,
               per_id,
               cc_dttm,
               cc_cl_cd,
               cc_type_cd,
               print_letter_sw,
               batch_nbr,
               --cc_status_flg,
               descrlong)
            values
              (l_cc_id,
               'SYSUSER',
               l_apref_per_id, --l_per_id,
               sysdate,
               'INQY',
               '14',
               'N',
               0,
               --'    ',
               l_cc_line4);
          else
            l_msg := 'Acct ID ' || sd.acct_id || ' has no Person ID.';
            raise l_err_found;
          end if;
        end if;

        -- For AR Customer Contact
        if sd.sd_total_for_ar_amt > 0 and
           sd.sd_total_for_refund_amt < sd.sd_total_for_ar_amt and
           sd.sd_total_for_wo_amt = 0 then
          l_custom_msg := 'retrieving per id for AR for populating customer contact ' ||
                          sd.acct_id;

          -->> CREATE Customer Contact
          select cap.per_id
            into l_apar_per_id
            from ci_acct_per cap
           where cap.acct_rel_type_cd = 'MAINCU  '
             and cap.main_cust_sw = 'Y'
             and acct_id = sd.acct_id;

          if l_apar_per_id is not null then
            l_custom_msg := 'creating AR CC ID SA for acct id ' ||
                            sd.acct_id;

            l_cc_line1 := 'Account ID : ' || sd.acct_id || chr(13) ||
                          'SD Apply to AR (YR) : ' ||
                          sd.sd_total_balance_amt;
            l_cc_line2 := 'Existing AR (ELEC SA) : ' || sd.ar_balance_amt;
            l_cc_line3 := 'Total SD Amount after application to AR (ELEC SA) : ' ||
                          sd.sd_applied_ar;
            l_cc_line4 := l_cc_line1 || chr(13) || chr(10) || l_cc_line2 ||
                          chr(13) || chr(10) || l_cc_line3;

            l_cc_id := substr(l_apar_per_id, 1, 6) ||
                       trunc(dbms_random.value(1000, 9999));

            insert into ci_cc_k (cc_id, env_id) values (l_cc_id, l_env_id);

            insert into ci_cc
              (cc_id,
               user_id,
               per_id,
               cc_dttm,
               cc_cl_cd,
               cc_type_cd,
               print_letter_sw,
               batch_nbr,
               --cc_status_flg,
               descrlong)
            values
              (l_cc_id,
               'SYSUSER',
               l_apar_per_id, --l_per_id,
               sysdate,
               'INQY',
               '14',
               'N',
               0,
               --'    ',
               l_cc_line4);
          else
            l_msg := 'Acct ID ' || sd.acct_id || ' has no Person ID.';
            raise l_err_found;
          end if;
        end if;

        -- For AR + Refund Customer Contact
        if sd.sd_total_for_ar_amt > 0 and
           sd.sd_total_for_refund_amt > sd.sd_total_for_ar_amt and
           sd.sd_total_for_wo_amt = 0 then
          l_custom_msg := 'retrieving per id for BD for populating customer contact ' ||
                          sd.acct_id;

          -->> CREATE Customer Contact
          select cap.per_id
            into l_apar_per_id
            from ci_acct_per cap
           where cap.acct_rel_type_cd = 'MAINCU  '
             and cap.main_cust_sw = 'Y'
             and acct_id = sd.acct_id;

          if l_apar_per_id is not null then

            l_custom_msg := 'creating AR CC ID SA for acct id ' ||
                            sd.acct_id;

            l_cc_line1 := 'Special Deposit Refund Amt. : ' ||
                          sd.sd_total_for_refund_amt;
            l_cc_line2 := 'Existing APT Refund : ' || sd.apt_balance_amt;
            l_cc_line3 := 'Total SD for Refund : ' ||
                          (sd.sd_total_for_refund_amt + sd.apt_balance_amt);
            l_cc_line4 := l_cc_line1 || chr(13) || chr(10) || l_cc_line2 ||
                          chr(13) || chr(10) || l_cc_line3;
            l_cc_line5 := l_cc_line4;

            l_cc_line1 := 'Account ID : ' || sd.acct_id || chr(13) ||
                          'SD Apply to AR (YR) : ' ||
                          sd.sd_total_balance_amt;
            l_cc_line2 := 'Existing AR (ELEC SA) : ' || sd.ar_balance_amt;
            l_cc_line3 := 'Total SD Amount after application to AR (ELEC SA) : ' ||
                          sd.sd_applied_ar;
            l_cc_line4 := l_cc_line1 || chr(13) || chr(10) || l_cc_line2 ||
                          chr(13) || chr(10) || l_cc_line3;

            l_cc_id := substr(l_apar_per_id, 1, 6) ||
                       trunc(dbms_random.value(1000, 9999));

            insert into ci_cc_k (cc_id, env_id) values (l_cc_id, l_env_id);

            insert into ci_cc
              (cc_id,
               user_id,
               per_id,
               cc_dttm,
               cc_cl_cd,
               cc_type_cd,
               print_letter_sw,
               batch_nbr,
               --cc_status_flg,
               descrlong)
            values
              (l_cc_id,
               'SYSUSER',
               l_apar_per_id, --l_per_id,
               sysdate,
               'INQY',
               '14',
               'N',
               0,
               --'    ',
               l_cc_line4 || chr(13) || chr(13) || chr(13) || chr(10) ||
               chr(13) || chr(10) || l_cc_line5);
          else
            l_msg := 'Acct ID ' || sd.acct_id || ' has no Person ID.';
            raise l_err_found;
          end if;
        end if;

      end if;

      for sdsa in (select sd_sa_id,
                          (sd_balance_amt * -1) - nvl(sd_for_bd_amt, 0) -
                          nvl(sd_for_ar_amt, 0) - nvl(sd_for_wo_amt, 0) -
                          nvl(sd_for_refund_amt, 0) sd_balance_amt
                     from sd_refund_sa
                    where period = sd.period
                      and acct_id = sd.acct_id
                    order by sd_sa_start_dt) loop

        if sdsa.sd_balance_amt = 0 then
          update ci_sa
             set tot_to_bill_amt = -0.01
           where sa_id = sdsa.sd_sa_id;
        else
          update ci_sa
             set tot_to_bill_amt = sdsa.sd_balance_amt
           where sa_id = sdsa.sd_sa_id;
        end if;
      end loop;

      update sd_refund_accts_sa
         set status = 'UPLOADED', applied_on = sysdate
       where period = sd.period
         and acct_id = sd.acct_id
         and sa_month = sd.sa_month;

      commit;
    end loop;

  exception
    when l_err_found then
      raise_application_error(-20100, l_msg);
    when others then
      l_custom_msg := 'Error @ procedure PREPARE_SA_ADJUSTMENTS when ' ||
                      l_custom_msg;
      l_ora_errmsg := sqlerrm;
      --  rollback;
      log_error(l_custom_msg, l_ora_errmsg);
      raise_application_error(-20012,
                              l_custom_msg || ' : ' || l_ora_errmsg);
  end prepare_sa_adjustments;

  procedure apply_adjustments_v2 is
    l_rec_count           number;
    l_adj_stg_ctl_id_from number;
    l_adj_stg_ctl_id_to   number;
    l_adj_stg_up_id_from  number;
    l_adj_stg_up_id_to    number;
    l_found               number;
    l_rec_amount_neg      number;
    l_rec_amount_pos      number;
    l_custom_msg          varchar2(1000);
    l_ora_errmsg          varchar2(1000);
  begin

    select count(*) rec_count,
           sum(a.amount) tot_adj_amt_pos,
           (abs(sum(a.amount)) * (-1)) tot_adj_amt_neg
      into l_rec_count, l_rec_amount_pos, l_rec_amount_neg
      from sd_adj_trans a
     where a.status = 'PENDING'
       and a.amount > 0;

    if l_rec_count > 0 then
      /*begin
        loop
          select adj_stg_ctl_seq.nextval
            into l_adj_stg_ctl_id_from
            from dual;

          begin
            select 1
              into l_found
              from ci_adj_stg_ctl
             where adj_stg_ctl_id = l_adj_stg_ctl_id_from;

          exception
            when no_data_found then
              l_found := 0;

              insert into ci_adj_stg_ctl
                (adj_stg_ctl_id,
                 cre_dttm,
                 adj_stg_ctl_status_flg,
                 adj_stg_up_rec_cnt,
                 tot_adj_amt,
                 currency_cd)
              values
                (l_adj_stg_ctl_id_from, sysdate, 'P', 0, 0, 'PHP');

          end;
          exit when l_found = 0;

          update ci_adj_stg_ctl
             set adj_stg_up_rec_cnt = l_rec_count,
                 tot_adj_amt        = l_rec_amount_pos
           where adj_stg_ctl_id = l_adj_stg_ctl_id_from;

        end loop;
      end;

      begin
        loop
          select adj_stg_ctl_seq.nextval
            into l_adj_stg_ctl_id_to
            from dual;

          begin
            select 1
              into l_found
              from ci_adj_stg_ctl
             where adj_stg_ctl_id = l_adj_stg_ctl_id_to;

          exception
            when no_data_found then
              l_found := 0;

              insert into ci_adj_stg_ctl
                (adj_stg_ctl_id,
                 cre_dttm,
                 adj_stg_ctl_status_flg,
                 adj_stg_up_rec_cnt,
                 tot_adj_amt,
                 currency_cd)
              values
                (l_adj_stg_ctl_id_to, sysdate, 'P', 0, 0, 'PHP');
          end;
          exit when l_found = 0;

          update ci_adj_stg_ctl
             set adj_stg_up_rec_cnt = l_rec_count,
                 tot_adj_amt        = l_rec_amount_neg
           where adj_stg_ctl_id = l_adj_stg_ctl_id_to;

        end loop;
      end;*/

      select adj_stg_ctl_seq.nextval into l_adj_stg_ctl_id_from from dual;

      insert into ci_adj_stg_ctl
        (adj_stg_ctl_id,
         cre_dttm,
         adj_stg_ctl_status_flg,
         adj_stg_up_rec_cnt,
         tot_adj_amt,
         currency_cd)
      values
        (l_adj_stg_ctl_id_from, sysdate, 'P', 0, 0, 'PHP');

      select adj_stg_ctl_seq.nextval into l_adj_stg_ctl_id_to from dual;

      insert into ci_adj_stg_ctl
        (adj_stg_ctl_id,
         cre_dttm,
         adj_stg_ctl_status_flg,
         adj_stg_up_rec_cnt,
         tot_adj_amt,
         currency_cd)
      values
        (l_adj_stg_ctl_id_to, sysdate, 'P', 0, 0, 'PHP');

      for l_adj_sas in (select sd.rowid rid,
                               period,
                               acct_id,
                               sa_id_from,
                               sa_id_to,
                               adj_type_cd_from,
                               adj_type_cd_to,
                               amount adj_amt_pos,
                               (abs(amount) * (-1)) adj_amt_neg,
                               remarks,
                               status,
                               created_on,
                               created_by,
                               adj_stg_ctl_id_from,
                               adj_stg_ctl_id_to,
                               adj_stg_up_id_from,
                               adj_stg_up_id_to
                          from sd_adj_trans sd
                         where status = 'PENDING'
                           and amount > 0) loop

        begin
          declare
            l_count number;
          begin
            begin
              select count(*)
                into l_count
                from ci_adj_stg_ctl
               where (adj_stg_ctl_id = l_adj_stg_ctl_id_from or
                     adj_stg_ctl_id = l_adj_stg_ctl_id_to);
            exception
              when no_data_found then
                l_count := 0;
            end;

            if l_count > 0 then
              update ci_adj_stg_ctl
                 set adj_stg_up_rec_cnt = l_rec_count,
                     tot_adj_amt        = l_rec_amount_pos
               where adj_stg_ctl_id = l_adj_stg_ctl_id_from;

              update ci_adj_stg_ctl
                 set adj_stg_up_rec_cnt = l_rec_count,
                     tot_adj_amt        = l_rec_amount_neg
               where adj_stg_ctl_id = l_adj_stg_ctl_id_to;

            elsif l_count <= 0 then
              exit;
            end if;
          end;

          begin
            loop
              select adj_stg_up_seq.nextval
                into l_adj_stg_up_id_from
                from dual;

              select adj_stg_up_seq.nextval
                into l_adj_stg_up_id_to
                from dual;

              begin
                select 1
                  into l_found
                  from ci_adj_stg_up
                 where (adj_stg_up_id = l_adj_stg_up_id_from or
                       adj_stg_up_id = l_adj_stg_up_id_to);
              exception
                when no_data_found then
                  l_found := 0;
              end;
              exit when l_found = 0;
            end loop;
          end;

          begin
            insert into ci_adj_stg_up
              (adj_stg_up_id,
               adj_stg_ctl_id,
               adj_type_cd,
               adj_stg_up_status_flg,
               create_dt,
               adj_amt,
               adj_suspense_flg,
               sa_id)
            values
              (l_adj_stg_up_id_from,
               l_adj_stg_ctl_id_from,
               l_adj_sas.adj_type_cd_from,
               'P',
               sysdate,
               l_adj_sas.adj_amt_pos,
               'NSUS',
               l_adj_sas.sa_id_from);

            insert into ci_adj_stg_up
              (adj_stg_up_id,
               adj_stg_ctl_id,
               adj_type_cd,
               adj_stg_up_status_flg,
               create_dt,
               adj_amt,
               adj_suspense_flg,
               sa_id)
            values
              (l_adj_stg_up_id_to,
               l_adj_stg_ctl_id_to,
               l_adj_sas.adj_type_cd_to,
               'P',
               sysdate,
               l_adj_sas.adj_amt_neg,
               'NSUS',
               l_adj_sas.sa_id_to);

          end;
        end;

        update sd_adj_trans
           set status = 'UPLOADED'
         where rowid = l_adj_sas.rid;

      end loop;
      commit;
    end if;
  exception
    when others then
      l_custom_msg := 'Error @ procedure APPLY_ADJUSTMENTS_V2 when ' ||
                      l_custom_msg;
      l_ora_errmsg := sqlerrm;
      rollback;
      log_error(l_custom_msg, l_ora_errmsg);
      raise_application_error(-20012,
                              l_custom_msg || ' : ' || l_ora_errmsg);

  end apply_adjustments_v2;

  -->> APPLYING ADJUSTMENTS
  procedure apply_adjustments is
    l_rec_count      number;
    l_rec_amount     number;
    l_adj_stg_ctl_id number;
    l_adj_stg_up_id  number;
    l_found          number;
    l_custom_msg     varchar2(1000);
    l_ora_errmsg     varchar2(1000);
  begin
    --load_global_variables;
    -->> APPLYING REFUND (+)
    select count(*) rec_count, sum(amount) tot_adj_amt
      into l_rec_count, l_rec_amount
      from (select *
              from sd_refund_adjustment_trans
             where status = 'PENDING'
               and amount > 0
               and eff_dt <= sysdate
             order by eff_dt);

    if l_rec_count > 0 then
      l_custom_msg := 'preparing adjustment staging control id (+)';
      begin
        loop
          select adj_stg_ctl_seq.nextval into l_adj_stg_ctl_id from dual;

          begin
            select 1
              into l_found
              from ci_adj_stg_ctl
             where adj_stg_ctl_id = l_adj_stg_ctl_id;

          exception
            when no_data_found then
              l_found := 0;
          end;
          exit when l_found = 0;
        end loop;
      end;

      l_custom_msg := 'creating adjustment staging control (+)';
      insert into ci_adj_stg_ctl
        (adj_stg_ctl_id,
         cre_dttm,
         adj_stg_ctl_status_flg,
         adj_stg_up_rec_cnt,
         tot_adj_amt,
         currency_cd)
      values
        (l_adj_stg_ctl_id, sysdate, 'P', l_rec_count, l_rec_amount, 'PHP');

      for stgup in (select sd.rowid    rid,
                           acct_id,
                           sa_id,
                           adj_type_cd,
                           bill_msg_cd,
                           amount      adj_amt
                      from sd_refund_adjustment_trans sd
                     where status = 'PENDING'
                       and amount > 0
                       and eff_dt <= sysdate
                     order by eff_dt) loop

        l_custom_msg := 'preparing adjustment staging upload id (+) for account id ' ||
                        stgup.acct_id;
        loop
          select adj_stg_up_seq.nextval into l_adj_stg_up_id from dual;

          begin
            select 1
              into l_found
              from ci_adj_stg_up
             where adj_stg_up_id = l_adj_stg_up_id;

          exception
            when no_data_found then
              l_found := 0;
          end;
          exit when l_found = 0;
        end loop;

        l_custom_msg := 'creating adjustment detail (+) for account id ' ||
                        stgup.acct_id;
        begin
          insert into ci_adj_stg_up
            (adj_stg_up_id,
             adj_stg_ctl_id,
             adj_type_cd,
             adj_stg_up_status_flg,
             create_dt,
             adj_amt,
             adj_suspense_flg,
             sa_id)
          values
            (l_adj_stg_up_id,
             l_adj_stg_ctl_id,
             stgup.adj_type_cd,
             'P',
             sysdate,
             stgup.adj_amt,
             'NSUS',
             stgup.sa_id);

          update sd_refund_adjustment_trans
             set adj_stg_ctl_id = l_adj_stg_ctl_id,
                 adj_stg_up_id  = l_adj_stg_up_id,
                 status         = 'UPLOADED',
                 posted_on      = sysdate,
                 posted_by      = user
           where rowid = stgup.rid;

        end;

      end loop;
    end if;

    -->> APPLYING REFUND (-)
    select count(*) rec_count, sum(amount) tot_adj_amt
      into l_rec_count, l_rec_amount
      from (select *
              from sd_refund_adjustment_trans
             where status = 'PENDING'
               and amount < 0
               and eff_dt <= sysdate
             order by eff_dt);

    if l_rec_count > 0 then
      l_custom_msg := 'preparing adjustment staging control id (-)';
      begin
        loop
          select adj_stg_ctl_seq.nextval into l_adj_stg_ctl_id from dual;

          begin
            select 1
              into l_found
              from ci_adj_stg_ctl
             where adj_stg_ctl_id = l_adj_stg_ctl_id;

          exception
            when no_data_found then
              l_found := 0;
          end;
          exit when l_found = 0;
        end loop;
      end;

      l_custom_msg := 'creating adjustment staging control (-)';
      insert into ci_adj_stg_ctl
        (adj_stg_ctl_id,
         cre_dttm,
         adj_stg_ctl_status_flg,
         adj_stg_up_rec_cnt,
         tot_adj_amt,
         currency_cd)
      values
        (l_adj_stg_ctl_id, sysdate, 'P', l_rec_count, l_rec_amount, 'PHP');

      for stgup in (select sd.rowid    rid,
                           acct_id,
                           sa_id,
                           adj_type_cd,
                           bill_msg_cd,
                           amount      adj_amt
                      from sd_refund_adjustment_trans sd
                     where status = 'PENDING'
                       and amount < 0
                       and eff_dt <= sysdate
                     order by eff_dt) loop
        l_custom_msg := 'preparing adjustment staging upload id (-) for account id ' ||
                        stgup.acct_id;
        loop
          select adj_stg_up_seq.nextval into l_adj_stg_up_id from dual;

          begin
            select 1
              into l_found
              from ci_adj_stg_up
             where adj_stg_up_id = l_adj_stg_up_id;

          exception
            when no_data_found then
              l_found := 0;
          end;
          exit when l_found = 0;
        end loop;

        l_custom_msg := 'creating adjustment detail (-) for account id ' ||
                        stgup.acct_id;
        begin
          insert into ci_adj_stg_up
            (adj_stg_up_id,
             adj_stg_ctl_id,
             adj_type_cd,
             adj_stg_up_status_flg,
             create_dt,
             adj_amt,
             adj_suspense_flg,
             sa_id)
          values
            (l_adj_stg_up_id,
             l_adj_stg_ctl_id,
             stgup.adj_type_cd,
             'P',
             sysdate,
             stgup.adj_amt,
             'NSUS',
             stgup.sa_id);

          update sd_refund_adjustment_trans
             set adj_stg_ctl_id = l_adj_stg_ctl_id,
                 adj_stg_up_id  = l_adj_stg_up_id,
                 status         = 'UPLOADED',
                 posted_on      = sysdate,
                 posted_by      = user
           where rowid = stgup.rid;
        end;
      end loop;
    end if;

    commit;
  exception
    when others then
      l_custom_msg := 'Error @ procedure APPLY_ADJUSTMENTS when ' ||
                      l_custom_msg;
      l_ora_errmsg := sqlerrm;
      --  rollback;
      log_error(l_custom_msg, l_ora_errmsg);
      raise_application_error(-20012,
                              l_custom_msg || ' : ' || l_ora_errmsg);
  end apply_adjustments;

  procedure special_deposit_msgs is

    l_bill_msg   varchar2(10);
    l_sd_ar      varchar2(10);
    l_sd_ref     varchar2(10);
    l_sd_bd      varchar2(10);
    errline      number;
    l_custom_msg varchar2(500);
    l_ora_errmsg varchar2(500);
    l_ap_tot_amt number;
    l_start_dt   varchar2(10);

  begin
    l_start_dt   := to_char(trunc(sysdate, 'MM'), 'MM');
    for rec_amt in (select sra.acct_id,
                           sra.sa_month,
                           nvl(sra.ar_avg_bill_amt, 0) ar_avg_bill_amt,
                           nvl(sra.bd_balance_amt, 0) bd_balance_amt,
                           nvl((sra.ar_avg_bill_amt -
                               (sra.bd_balance_amt * -1)),
                               0) add_bd_required,
                           nvl((sra.sd_total_balance_amt * -1), 0) sd_amt,
                           nvl(sra.sd_total_for_ar_amt, 0) ar_amt,
                           nvl(sra.sd_total_for_bd_amt, 0) bd_amt,
                           nvl(sra.sd_total_for_wo_amt, 0) wo_amt,
                           nvl(sra.sd_total_for_refund_amt, 0) ref_amt,
                           nvl(sra.apt_balance_amt, 0) apt_balance,
                           nvl(sra.apwo_balance_amt, 0) apwo_balance_amt
                      from sd_refund_accts_sa sra
                     where sra.status = 'FORUPLOAD'
                       and sa_month = l_start_dt
                     ) loop

      begin

        -->>refund
        if ((rec_amt.ref_amt > 0 or rec_amt.apt_balance > 0) and
           rec_amt.ar_amt = 0 and rec_amt.bd_amt = 0 and
           rec_amt.wo_amt = 0) then

          l_ap_tot_amt := rec_amt.apt_balance + rec_amt.ref_amt;

          select reg_value
            into l_sd_ref
            from sd_refund_registry
           where reg_code = 'REFUNDMSG';

          l_bill_msg := l_sd_ref;

          errline := 10;
          insert into /*+append+*/
          ci_acct_msg
            (acct_id, bill_msg_cd, bill_msg_type_flg)
          values
            (rec_amt.acct_id, l_bill_msg, 'T');

          errline := 20;

          insert into /*+append+*/
          ci_acct_msg_prm
            (acct_id, bill_msg_cd, seq_num, msg_parm_val)
          values
            (rec_amt.acct_id,
             l_bill_msg,
             1,
             to_char(l_ap_tot_amt, 'fm999,999,999,990.00'));

          -->>bill deposit
        elsif (rec_amt.ref_amt = 0 and rec_amt.ar_amt = 0 and
              rec_amt.bd_amt > 0 and rec_amt.wo_amt = 0) then

          select reg_value
            into l_sd_bd
            from sd_refund_registry
           where reg_code = 'BILLDEPMSG';

          l_bill_msg := l_sd_bd;
          errline    := 30;
          insert into /*+append+*/
          ci_acct_msg
            (acct_id, bill_msg_cd, bill_msg_type_flg)
          values
            (rec_amt.acct_id, l_bill_msg, 'T');
          errline := 40;
          insert into /*+append+*/
          ci_acct_msg_prm
            (acct_id, bill_msg_cd, seq_num, msg_parm_val)
          values
            (rec_amt.acct_id,
             l_bill_msg,
             1,
             to_char(rec_amt.sd_amt, 'fm999,999,999,990.00'));
          errline := 50;
          insert into /*+append+*/
          ci_acct_msg_prm
            (acct_id, bill_msg_cd, seq_num, msg_parm_val)
          values
            (rec_amt.acct_id,
             l_bill_msg,
             2,
             to_char(rec_amt.add_bd_required, 'fm999,999,999,990.00'));

          -->>bill deposit and refund
        elsif (rec_amt.ref_amt > 0 and rec_amt.ar_amt = 0 and
              rec_amt.bd_amt > 0 and rec_amt.wo_amt = 0) then

          l_ap_tot_amt := rec_amt.apt_balance + rec_amt.ref_amt;

          select reg_value
            into l_sd_ar
            from sd_refund_registry
           where reg_code = 'ARMSG';

          l_bill_msg := l_sd_ar;
          errline    := 60;

          insert into /*+append+*/
          ci_acct_msg
            (acct_id, bill_msg_cd, bill_msg_type_flg)
          values
            (rec_amt.acct_id, l_bill_msg, 'T');
          errline := 70;
          insert into /*+append+*/
          ci_acct_msg_prm
            (acct_id, bill_msg_cd, seq_num, msg_parm_val)
          values
            (rec_amt.acct_id,
             l_bill_msg,
             1,
             to_char(l_ap_tot_amt, 'fm999,999,999,990.00'));
          errline := 80;
          insert into /*+append+*/
          ci_acct_msg_prm
            (acct_id, bill_msg_cd, seq_num, msg_parm_val)
          values
            (rec_amt.acct_id,
             l_bill_msg,
             2,
             to_char(rec_amt.sd_amt, 'fm999,999,999,990.00'));
          errline := 90;
          insert into /*+append+*/
          ci_acct_msg_prm
            (acct_id, bill_msg_cd, seq_num, msg_parm_val)
          values
            (rec_amt.acct_id,
             l_bill_msg,
             3,
             to_char(rec_amt.bd_amt, 'fm999,999,999,990.00'));
        end if;

        commit;

      exception
        when no_data_found then
          null;

        when dup_val_on_index then
          null;
      end;
    end loop;
    commit;
  exception
    when others then
      l_custom_msg := 'Error @ procedure SPECIAL_DEPOSIT_MSGS when ' ||
                      l_custom_msg;
      l_ora_errmsg := sqlerrm;
      log_error(l_custom_msg, l_ora_errmsg);
      raise_application_error(-20012,
                              l_custom_msg || ' : ' || l_ora_errmsg || ' ' ||
                              '@Line : ' || errline);
  end;

  procedure sd_scheduler is
    l_custom_msg varchar2(500);
    l_ora_errmsg varchar2(500);
  begin

    retrieve_special_deposit_sa;
    retrieve_special_deposit_accts;
    summarize_revenue;
    special_deposit_msgs;
    prepare_sa_adjustments;
    apply_adjustments;
    apply_adjustments_v2;

    commit;
  exception
    when others then

      rollback;
      l_custom_msg := 'Error @ procedure sd_scheduler when ' ||
                      l_custom_msg;
      l_ora_errmsg := sqlerrm;
      log_error(l_custom_msg, l_ora_errmsg);
      raise_application_error(-20012,
                              l_custom_msg || ' : ' || l_ora_errmsg);
  end;

end sd_refund_pkg;
