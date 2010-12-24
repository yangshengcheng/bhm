select to_char(sysdate,'YYYYMMDDHH24MMSS'),'|ORA_GLOBAL', '|UDM_ORA_SHAREDPOOL_SIZE','|OracleInstance',(select INSTANCE_NAME from V$INSTANCE  ) as instance,'|',(SELECT SUM(BYTES)/1024/1024  FROM V$SGASTAT WHERE POOL='shared pool' ) as  MB,'|&1' from dual;

select to_char(sysdate,'YYYYMMDDHH24MMSS'),'|ORA_GLOBAL', '|UDM_700','|OracleInstance',(select INSTANCE_NAME from V$INSTANCE  ) as instance,'|',(select (sysdate - (select STARTUP_TIME from  v$instance)) * 24  from  dual) as hours ,'|&1' from dual;
select to_char(sysdate,'YYYYMMDDHH24MMSS'),'|ORA_GLOBAL', '|UDM_724','|OracleInstance',(select INSTANCE_NAME from V$INSTANCE  ) as instance,'|',(select 100 - bytes * 100 / (select sum(bytes) from  v$sgastat  where pool='shared pool' group by pool)  FROM  v$sgastat WHERE pool='shared pool' AND name='free memory') as  ratio,'|&1' from dual;
select to_char(sysdate,'YYYYMMDDHH24MMSS'),'|ORA_GLOBAL', '|UDM_723','|OracleInstance',(select INSTANCE_NAME from V$INSTANCE  ) as instance,'|',(select 100 - (phy.value - (direct.value + lob.value)) / (consis.value + block.value - (direct.value + lob.value))* 100   from v$sysstat phy,v$sysstat direct ,v$sysstat lob,v$sysstat consis,v$sysstat block where phy.name='physical reads' and direct.name='physical reads direct' and lob.name='physical reads direct (lob)' and consis.name='consistent gets' and block.name='db block gets') as Ratio ,'|&1' from dual;
select to_char(sysdate,'YYYYMMDDHH24MMSS'),'|ORA_GLOBAL', '|UDM_725','|OracleInstance',(select INSTANCE_NAME from V$INSTANCE  ) as instance,'|',(select a.value * 100 /(a.value + b.value) from  v$sysstat a ,v$sysstat b where a.name='buffer is pinned count' and b.name='buffer is not pinned count') as  ratio ,'|&1'  from  dual;
select to_char(sysdate,'YYYYMMDDHH24MMSS'),'|ORA_GLOBAL', '|UDM_726','|OracleInstance',(select INSTANCE_NAME from V$INSTANCE  ) as instance,'|',(select sum(gets-getmisses)/sum(gets) * 100  from v$rowcache) as ratio ,'|&1' from dual; 
select to_char(sysdate,'YYYYMMDDHH24MMSS'),'|ORA_GLOBAL', '|UDM_727','|OracleInstance',(select INSTANCE_NAME from V$INSTANCE  ) as instance,'|',(select 100 - sum(MISSES) * 100 / sum(GETS)  from v$latch) as  ratio  ,'|&1' from  dual;
select to_char(sysdate,'YYYYMMDDHH24MMSS'),'|ORA_GLOBAL', '|UDM_728','|OracleInstance',(select INSTANCE_NAME from V$INSTANCE  ) as instance,'|',(select Sum(Pins)/(Sum(Pins) + Sum(Reloads)) * 100  from V$LibraryCache) as ratio ,'|&1' from dual;
select to_char(sysdate,'YYYYMMDDHH24MMSS'),'|ORA_GLOBAL', '|UDM_729','|OracleInstance',(select INSTANCE_NAME from V$INSTANCE  ) as instance,'|',(select value  from v$sysstat where name='session logical reads') as  read ,'|&1' from dual;

select to_char(sysdate,'YYYYMMDDHH24MMSS'),'|ORA_GLOBAL', '|UDM_715','|OracleInstance',(select INSTANCE_NAME from V$INSTANCE  ) as instance,'|',(select sum( PHYBLKRD) from  v$filestat) as read ,'|&1' from  dual; 
select to_char(sysdate,'YYYYMMDDHH24MMSS'),'|ORA_GLOBAL', '|UDM_716','|OracleInstance',(select INSTANCE_NAME from V$INSTANCE  ) as instance,'|',(select sum(PHYBLKWRT) from   v$filestat) as write ,'|&1' from dual;

select to_char(sysdate,'YYYYMMDDHH24MMSS'),'|ORA_GLOBAL', '|UDM_736','|OracleInstance',(select INSTANCE_NAME from V$INSTANCE  ) as instance,'|',(select count(*) from  v$latch) as lockSum ,'|&1' from dual;
select to_char(sysdate,'YYYYMMDDHH24MMSS'),'|ORA_GLOBAL', '|UDM_737','|OracleInstance',(select INSTANCE_NAME from V$INSTANCE  ) as instance,'|',(select 100 - 100 * (sum(MISSES) / sum(GETS)) from  v$latch) as ratio ,'|&1' from dual;

select to_char(sysdate,'YYYYMMDDHH24MMSS'),'|ORA_GLOBAL', '|UDM_739','|OracleInstance',(select INSTANCE_NAME from V$INSTANCE  ) as instance,'|',( select to_char(100 * (sum(MISSES) / sum(GETS)),'90.99') from v$latch) as ratio ,'|&1' from dual;
select to_char(sysdate,'YYYYMMDDHH24MMSS'),'|ORA_GLOBAL', '|UDM_712','|OracleInstance',(select INSTANCE_NAME from V$INSTANCE  ) as instance,'|',(select count(*)  from v$session) as count ,'|&1' from dual;


select to_char(sysdate,'YYYYMMDDHH24MMSS'),'|ORA_GLOBAL', '|UDM_720','|OracleInstance',(select INSTANCE_NAME from V$INSTANCE  ) as instance,'|',(select sum(bytes)/1024/1024   from v$sgastat where name='sql area') as sqlsize ,'|&1' from dual;
select to_char(sysdate,'YYYYMMDDHH24MMSS'),'|ORA_GLOBAL', '|UDM_722','|OracleInstance',(select INSTANCE_NAME from V$INSTANCE  ) as instance,'|',(select sum(pinhits-reloads)/sum(pins)*100  from v$librarycache) as hitradio ,'|&1' from dual;
