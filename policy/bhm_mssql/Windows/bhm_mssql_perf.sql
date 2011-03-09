select replace(replace(replace(CONVERT(VARCHAR(23),getdate(),120),'-',''),':',''),' ','') as timestamp , 'MSSQL_GLOBAL' as class,'MSSQL_USER_SESSION' as metric,'MssqlInstance '+ @@servicename as instance,count(*) as value,'MSWin32' as ostype from master..sysprocesses
select replace(replace(replace(CONVERT(VARCHAR(23),getdate(),120),'-',''),':',''),' ','') as timestamp , 'MSSQL_GLOBAL' as class,'MSSQL_SESSION_ACTIVE' as metric,'MssqlInstance '+ @@servicename  as instance,count(*) as value,'MSWin32' as ostype from master..sysprocesses  where spid >= 0 and spid <= 32767 AND upper(cmd) <> 'AWAITING COMMAND'
select replace(replace(replace(CONVERT(VARCHAR(23),getdate(),120),'-',''),':',''),' ','') as timestamp , 'MSSQL_GLOBAL' as class,'MSSQL_FREE_PAGES' as metric,'MssqlInstance '+ @@servicename  as instance,cntr_value as value,'MSWin32' as ostype from master.sys.sysperfinfo  where object_name like '%buffer Manager%' and counter_name='free pages'
select replace(replace(replace(CONVERT(VARCHAR(23),getdate(),120),'-',''),':',''),' ','') as timestamp , 'MSSQL_GLOBAL' as class,'MSSQL_PAGE_READS' as metric,'MssqlInstance '+ @@servicename  as instance,cntr_value as value,'MSWin32' as ostype from master.sys.sysperfinfo  where object_name like '%buffer Manager%' and counter_name='Page reads/sec'
select replace(replace(replace(CONVERT(VARCHAR(23),getdate(),120),'-',''),':',''),' ','') as timestamp , 'MSSQL_GLOBAL' as class,'MSSQL_PAGE_WRITES' as metric,'MssqlInstance '+ @@servicename  as instance,cntr_value as value,'MSWin32' as ostype from master.sys.sysperfinfo  where object_name like '%buffer Manager%' and counter_name='Page writes/sec'
select replace(replace(replace(CONVERT(VARCHAR(23),getdate(),120),'-',''),':',''),' ','') as timestamp , 'MSSQL_LOCKWAIT' as class,'MSSQL_LOCKWAIT_TIME' as metric,'MssqlInstance '+ @@servicename  + '/' + replace(instance_name,' ','') as instance,cntr_value as value,'MSWin32' as ostype from master.sys.sysperfinfo   where  counter_name ='Average Wait Time (ms)' and instance_name='_Total'
select replace(replace(replace(CONVERT(VARCHAR(23),getdate(),120),'-',''),':',''),' ','') as timestamp , 'MSSQL_LOCKWAIT' as class,'MSSQL_LOCKWAIT_TIME' as metric,'MssqlInstance '+ @@servicename  + '/' + replace(instance_name,' ','') as instance,cntr_value as value,'MSWin32' as ostype from master.sys.sysperfinfo   where  counter_name ='Average Wait Time (ms)' and instance_name='Database'
select replace(replace(replace(CONVERT(VARCHAR(23),getdate(),120),'-',''),':',''),' ','') as timestamp , 'MSSQL_LOCKWAIT' as class,'MSSQL_LOCKWAIT_TIME' as metric,'MssqlInstance '+ @@servicename  + '/' + replace(instance_name,' ','') as instance,cntr_value as value,'MSWin32' as ostype from master.sys.sysperfinfo   where  counter_name ='Average Wait Time (ms)' and instance_name='File'
select replace(replace(replace(CONVERT(VARCHAR(23),getdate(),120),'-',''),':',''),' ','') as timestamp , 'MSSQL_LOCKWAIT' as class,'MSSQL_LOCKWAIT_TIME' as metric,'MssqlInstance '+ @@servicename  + '/' + replace(instance_name,' ','') as instance,cntr_value as value,'MSWin32' as ostype from master.sys.sysperfinfo   where  counter_name ='Average Wait Time (ms)' and instance_name='Object'
select replace(replace(replace(CONVERT(VARCHAR(23),getdate(),120),'-',''),':',''),' ','') as timestamp , 'MSSQL_LOCKWAIT' as class,'MSSQL_LOCKWAIT_TIME' as metric,'MssqlInstance '+ @@servicename  + '/' + replace(instance_name,' ','') as instance,cntr_value as value,'MSWin32' as ostype from master.sys.sysperfinfo   where  counter_name ='Average Wait Time (ms)' and instance_name='Extent'
select replace(replace(replace(CONVERT(VARCHAR(23),getdate(),120),'-',''),':',''),' ','') as timestamp , 'MSSQL_LOCKWAIT' as class,'MSSQL_LOCKWAIT_TIME' as metric,'MssqlInstance '+ @@servicename  + '/' + replace(instance_name,' ','') as instance,cntr_value as value,'MSWin32' as ostype from master.sys.sysperfinfo   where  counter_name ='Average Wait Time (ms)' and instance_name='Key'
select replace(replace(replace(CONVERT(VARCHAR(23),getdate(),120),'-',''),':',''),' ','') as timestamp , 'MSSQL_LOCKWAIT' as class,'MSSQL_LOCKWAIT_TIME' as metric,'MssqlInstance '+ @@servicename  + '/' + replace(instance_name,' ','') as instance,cntr_value as value,'MSWin32' as ostype from master.sys.sysperfinfo   where  counter_name ='Average Wait Time (ms)' and instance_name='RID'
select replace(replace(replace(CONVERT(VARCHAR(23),getdate(),120),'-',''),':',''),' ','') as timestamp , 'MSSQL_LOCKWAIT' as class,'MSSQL_LOCKWAIT_TIME' as metric,'MssqlInstance '+ @@servicename  + '/' + replace(instance_name,' ','') as instance,cntr_value as value,'MSWin32' as ostype from master.sys.sysperfinfo   where  counter_name ='Average Wait Time (ms)' and instance_name='Application'
select replace(replace(replace(CONVERT(VARCHAR(23),getdate(),120),'-',''),':',''),' ','') as timestamp , 'MSSQL_LOCKWAIT' as class,'MSSQL_LOCKWAIT_TIME' as metric,'MssqlInstance '+ @@servicename  + '/' + replace(instance_name,' ','') as instance,cntr_value as value,'MSWin32' as ostype from master.sys.sysperfinfo   where  counter_name ='Average Wait Time (ms)' and instance_name='Metadata'
select replace(replace(replace(CONVERT(VARCHAR(23),getdate(),120),'-',''),':',''),' ','') as timestamp , 'MSSQL_LOCKWAIT' as class,'MSSQL_LOCKWAIT_TIME' as metric,'MssqlInstance '+ @@servicename  + '/' + replace(instance_name,' ','') as instance,cntr_value as value,'MSWin32' as ostype from master.sys.sysperfinfo   where  counter_name ='Average Wait Time (ms)' and instance_name='HoBT'
select replace(replace(replace(CONVERT(VARCHAR(23),getdate(),120),'-',''),':',''),' ','') as timestamp , 'MSSQL_LOCKWAIT' as class,'MSSQL_LOCKWAIT_TIME' as metric,'MssqlInstance '+ @@servicename  + '/' + replace(instance_name,' ','') as instance,cntr_value as value,'MSWin32' as ostype from master.sys.sysperfinfo   where  counter_name ='Average Wait Time (ms)' and instance_name='AllocUnit'
select replace(replace(replace(CONVERT(VARCHAR(23),getdate(),120),'-',''),':',''),' ','') as timestamp , 'MSSQL_GLOBAL' as class,'MSSQL_TRAN_ELAPSED_TIME' as metric,'MssqlInstance '+ @@servicename  as instance,cntr_value as value,'MSWin32' as ostype from master.sys.sysperfinfo  where counter_name='Transaction ownership waits' and instance_name like '%平均等待时间%'
select replace(replace(replace(CONVERT(VARCHAR(23),getdate(),120),'-',''),':',''),' ','') as timestamp , 'MSSQL_GLOBAL' as class,'MSSQL_TAB_LOCKS' as metric,'MssqlInstance '+ @@servicename  as instance,count(*) as value,'MSWin32' as ostype from  master.dbo.syslockinfo,  master.dbo.spt_values v,  master.dbo.spt_values x,  master.dbo.spt_values u  where   master.dbo.syslockinfo.rsc_type = v.number   and v.type = 'LR'  and v.name='TAB' and master.dbo.syslockinfo.req_status = x.number  and x.type = 'LS'  and master.dbo.syslockinfo.req_mode + 1 = u.number  and u.type = 'L'