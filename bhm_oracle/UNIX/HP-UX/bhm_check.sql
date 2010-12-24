set verify off
set wrap on
set termout off
set trimout on
set trimspool on
set feed off
set linesize  300
set pagesize 0
set heading off;
spool /var/opt/OV/bhm/dsi/&1

desc v$instance;
desc dba_data_files;
desc DBA_FREE_SPACE;
desc V$VERSION;
desc V$DATABASE;
desc V$SYSTEM_EVENT;
desc V$SGASTAT;
desc v$rowcache;
desc v$latch;
desc V$LibraryCache;
desc v$filestat;
desc v$session;


spool off
exit