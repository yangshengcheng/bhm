set verify off
set wrap on
set termout off
set trimout on
set trimspool on
set feed off
set linesize  300
set pagesize 0
set heading off;
spool "%OvDataDir%\\bhm\\temp\\&1"
col  instance format a10

@"%OvDataDir%\\bin\\instrumentation\\bhm_db_oracle_config_sel.sql" &2

@"%OvDataDir%\\bin\\instrumentation\\bhm_db_oracle_perf_sel.sql" &2

col name format  a20
@"%OvDataDir%\\bin\\instrumentation\\bhm_db_oracle_tablespace_sel.sql" &2

col event format a30
@"%OvDataDir%\\bin\\instrumentation\\bhm_db_oracle_event_sel.sql" &2

spool off
exit