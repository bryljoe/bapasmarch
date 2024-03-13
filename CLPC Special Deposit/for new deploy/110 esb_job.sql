begin
  sys.dbms_scheduler.create_job(job_name            => 'ESB.SD_REFUND_PKG_B',
                                job_type            => 'PLSQL_BLOCK',
                                job_action          => 'begin 
                                                            sd_refund_pkg.sd_scheduler; 
                                                          end;',
                                start_date          => to_date('03-11-2024 00:00:00', 'dd-mm-yyyy hh24:mi:ss'),
                                repeat_interval     => 'Freq=DAILY',
                                end_date            => to_date(null),
                                job_class           => 'DEFAULT_JOB_CLASS',
                                enabled             => true,
                                auto_drop           => false,
                                comments            => '');
end;
/
