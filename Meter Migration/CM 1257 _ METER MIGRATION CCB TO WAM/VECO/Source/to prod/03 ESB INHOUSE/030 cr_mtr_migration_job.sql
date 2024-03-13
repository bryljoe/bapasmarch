begin
  sys.dbms_scheduler.create_job(job_name            => 'ESB.CCB_WAM_MTR_ASSET_MIGRATION',
                                job_type            => 'PLSQL_BLOCK',
                                job_action          => 'begin
                                                            esb.cr_mtr_asset_migration_pkg.main(p_plant => ''03'');
                                                        end;',
                                start_date          => to_date('12-12-2023 00:00:00', 'mm-dd-yyyy hh24:mi:ss'),
                                repeat_interval     => 'FREQ=DAILY;BYHOUR=1',
                                end_date            => to_date(null),
                                job_class           => 'DEFAULT_JOB_CLASS',
                                enabled             => true,
                                auto_drop           => false,
                                comments            => 'Run every 1AM');
end;
/
