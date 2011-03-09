SELECT 
replace(replace(replace(CONVERT(VARCHAR(23),getdate(),120),'-',''),':',''),' ','') as timestamp,
 'MSSQL_LOCKOBJ' as class,
'MSSQL_LOCK_AVG_WAIT_TIME' as metric,
perf1.instance_name as instance,
'value' = CASE perf1.cntr_type
WHEN 537003008 -- This counter is expressed as a ratio and requires calculation. (Sql 2000)
THEN CONVERT(decimal(10,2),CONVERT(FLOAT,perf1.cntr_value) * 100 /
(SELECT CASE perf2.cntr_value
WHEN 0 THEN 1
ELSE perf2.cntr_value
END
FROM master..sysperfinfo perf2
WHERE (perf1.counter_name + ' '
= SUBSTRING(perf2.counter_name,1,PATINDEX('% Base%', perf2.counter_name)))
AND perf1.[object_name] = perf2.[object_name]
AND perf1.instance_name = perf2.instance_name
AND perf2.cntr_type in (1073939459,1073939712)
))
WHEN 537003264 -- This counter is expressed as a ratio and requires calculation.(sql 2005) 
THEN CONVERT(decimal(10,2),CONVERT(FLOAT,perf1.cntr_value) * 100 /
(SELECT CASE perf2.cntr_value 
WHEN 0 THEN 1
ELSE perf2.cntr_value
END
FROM master..sysperfinfo perf2
WHERE (perf1.counter_name + ' ' = SUBSTRING(perf2.counter_name,1,PATINDEX('% Base%', perf2.counter_name)))
AND perf1.[object_name] = perf2.[object_name]
AND perf1.instance_name = perf2.instance_name
AND perf2.cntr_type in (1073939459,1073939712)
))
ELSE perf1.cntr_value -- The values of the other counter types are
-- already calculated.
END,
'MSWin32' as ostype
FROM master..sysperfinfo perf1
WHERE perf1.cntr_type not in (1073939459,1073939712) and perf1.counter_name in ('Average Wait Time (ms)') --and perf1.instance_name='_Total' -- Don't display the divisors.