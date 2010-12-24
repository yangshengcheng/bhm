@echo  off

set file=ora_%time:~0,2%%time:~3,2%.csv
sqlplus -S %1/%2 @"%OvDataDir%\\bin\\Instrumentation\\bhm_db_oracle_metric_spl.sql"  %file%  MSWin32

copy /Y "%OvDataDir%\\bhm\\temp\\%file%" "%OvDataDir%\\bhm\\dsi\\%file%"

del  /Q "%OvDataDir%\\bhm\\temp\\%file%"