@echo  off

set QUERYVBS="%OvAgentDir%bin\\instrumentation\\bhm_db_mssql_query.vbs"
set QUERY2VBS="%OvAgentDir%bin\\instrumentation\\bhm_db_mssql_query2.vbs"

set CONFIGSQL="%OvAgentDir%bin\\instrumentation\\bhm_mssql_config.sql"
set PERFSQL="%OvAgentDir%bin\\instrumentation\\bhm_mssql_perf.sql"
set DATAFILESQL="%OvAgentDir%bin\\instrumentation\\bhm_mssql_perf_datafiles.sql"
set HITRATIOSQL="%OvAgentDir%bin\instrumentation\\bhm_mssql_perf_cache_hit_ratio.sql"
set tempfile="%OvAgentDir%\\bhm\\temp\\mssql_perf.csv"
set file=mssql_%time:~0,2%%time:~3,2%.csv

chdir "%OvAgentDir%bin\\instrumentation"

IF ERRORLEVEL 1  goto CleanUp

If Not Exist %QUERYVBS% (
	goto CleanUp
)



if Exist %CONFIGSQL% (
	cscript //nologo "%OvAgentDir%bin\\instrumentation\\bhm_db_mssql_query.vbs" "%OvAgentDir%bin\\instrumentation\\bhm_mssql_config.sql"
)

if Exist %PERFSQL% (
	cscript //nologo "%OvAgentDir%bin\\instrumentation\\bhm_db_mssql_query.vbs" "%OvAgentDir%bin\\instrumentation\\bhm_mssql_perf.sql"
)

if Exist %DATAFILESQL% (
	cscript //nologo "%OvAgentDir%bin\\instrumentation\\bhm_db_mssql_query.vbs" "%OvAgentDir%bin\\instrumentation\\bhm_mssql_perf_datafiles.sql"
)

If Not Exist %QUERY2VBS% (
	copy /Y "%OvDataDir%\\bhm\\temp\\%tempfile%" "%OvDataDir%\\bhm\\dsi\\%file%"
	del  /Q "%OvDataDir%\\bhm\\temp\\%tempfile%"
	goto CleanUp
)

if Exist %HITRATIOSQL% (
	cscript //nologo "%OvAgentDir%bin\\instrumentation\\bhm_db_mssql_query2.vbs" "%OvAgentDir%bin\\instrumentation\\bhm_mssql_perf_cache_hit_ratio.sql"
)


copy /Y  %tempfile%  "%OvDataDir%\\bhm\\dsi\\%file%"

del  /Q %tempfile%

goto CleanUp


:CleanUp

set QUERYVBS=
set QUERY2VBS=
set CONFIGSQL=
set PERFSQL=
set DATAFILESQL=
set HITRATIOSQL=
set file=
set tempfile=
