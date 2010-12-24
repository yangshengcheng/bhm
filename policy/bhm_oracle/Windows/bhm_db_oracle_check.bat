@echo  off

sqlplus -S %1/%2 @"%OvDataDir%\\bin\\Instrumentation\\bhm_check.sql" ora_check.csv  MSWin32