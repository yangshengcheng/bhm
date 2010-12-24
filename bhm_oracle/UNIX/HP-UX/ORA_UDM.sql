#this  file is use for usa define metric 
#####   sample ######
# ORACLE
#   METRIC 0700
#     COLLECT ITO MW "
#       declare
#         tmp number;
#       begin
#         :dbspi_error := '<no error>';
#         tmp := :dbspi_threshold;
#         :dbspi_value := 2*tmp;
#       end;
#     "


 

#
ORACLE
   METRIC 0700
     COLLECT ITO MW "
       declare
         var number;
       begin
       :dbspi_error := '<no error>';
       select (sysdate - (select startup_time from  v$instance)) * 24 as hours into var from  dual ;
       if var > 0 then
		:dbspi_value := var;
	else
		:dbspi_value := -1;
	end if;

       end;
     "


#the current transaction sum 

   METRIC 0707
     COLLECT ITO MW "
       declare
         var number;
       begin
       :dbspi_error := '<no error>';
       select count(*) into  var from  v$transaction;
       if var >= 0 then
		:dbspi_value := var;
	else
		:dbspi_value := -1;
	end if;

       end;
     "
#the current redo  log size  

   METRIC 0708
     COLLECT ITO MW "
       declare
         var number;
       begin
       :dbspi_error := '<no error>';
       select sum(value)/1024/1024 into var from v$sesstat, v$statname where v$sesstat.statistic#=v$statname.statistic# and v$statname.name='redo size';
       if var >= 0 then
		:dbspi_value := var;
	else
		:dbspi_value := -1;
	end if;

       end;
     "

#the physic  write  sum(time) since oracle start 

   METRIC 0709
     COLLECT ITO MW "
       declare
         var number;
       begin
       :dbspi_error := '<no error>';
        select sum(PHYWRTS)  into  var  from v$filestat;
       if var >= 0 then
		:dbspi_value := var;
	else
		:dbspi_value := -1;
	end if;

       end;
     "

#the physic  read  sum(time) since oracle start 

   METRIC 0710
     COLLECT ITO MW "
       declare
         var number;
       begin
       :dbspi_error := '<no error>';
        select sum(phyrds)  into  var  from v$filestat;
       if var >= 0 then
		:dbspi_value := var;
	else
		:dbspi_value := -1;
	end if;

       end;
     "

#the current session count 

   METRIC 0712
     COLLECT ITO MW "
       declare
         var number;
       begin
       :dbspi_error := '<no error>';
        select count(*) into  var from v$session;
       if var >= 0 then
		:dbspi_value := var;
	else
		:dbspi_value := -1;
	end if;

       end;
     "

#the database size  

   METRIC 0713
     COLLECT ITO MW "
       declare
         var number;
       begin
       :dbspi_error := '<no error>';
        select sum(bytes)/1024/1024 into  var from dba_data_files;
       if var >= 0 then
		:dbspi_value := var;
	else
		:dbspi_value := -1;
	end if;

       end;
     " 

#the db_block_size  

   METRIC 0714
     COLLECT ITO MW "
       declare
         var number;
       begin
       :dbspi_error := '<no error>';
        select value into  var from  gv$parameter where name='db_block_size';
       if var >= 0 then
		:dbspi_value := var;
	else
		:dbspi_value := -1;
	end if;

       end;
     " 

#the block read total  times since oracle start   

   METRIC 0715
     COLLECT ITO MW "
       declare
         var number;
       begin
       :dbspi_error := '<no error>';
        select sum(PHYBLKRD) into  var from  v$filestat;
       if var >= 0 then
		:dbspi_value := var;
	else
		:dbspi_value := -1;
	end if;

       end;
     " 

#the block write total  times since oracle start   

   METRIC 0716
     COLLECT ITO MW "
       declare
         var number;
       begin
       :dbspi_error := '<no error>';
        select sum(PHYBLKWRT) into  var from  v$filestat;
       if var >= 0 then
		:dbspi_value := var;
	else
		:dbspi_value := -1;
	end if;

       end;
     " 
#the shared pool size    

   METRIC 0717
     COLLECT ITO MW "
       declare
         var number;
       begin
       :dbspi_error := '<no error>';
        select sum(bytes)/1024/1024   into var from v$sgastat where pool='shared pool' group by pool ;
       if var >= 0 then
		:dbspi_value := var;
	else
		:dbspi_value := -1;
	end if;

       end;
     " 
#the redo log file size   

   METRIC 0718
     COLLECT ITO MW "
       declare
         var number;
       begin
       :dbspi_error := '<no error>';
       select sum(bytes)/1024/1024    into var from v$log;
       if var >= 0 then
		:dbspi_value := var;
	else
		:dbspi_value := -1;
	end if;

       end;
     "
     
#the data dictionary cache size   

   METRIC 0719
     COLLECT ITO MW "
       declare
         var number;
       begin
       :dbspi_error := '<no error>';
       select sum(sharable_mem)/1024/1024 into  var from v$sqlarea;
       if var >= 0 then
		:dbspi_value := var;
	else
		:dbspi_value := -1;
	end if;

       end;
     "

#the sql area size   

   METRIC 0720
     COLLECT ITO MW "
       declare
         var number;
       begin
       :dbspi_error := '<no error>';
       select sum(bytes)/1024/1024    into var from v$sgastat where name='sql area' ;
       if var >= 0 then
		:dbspi_value := var;
	else
		:dbspi_value := -1;
	end if;

       end;
     "

#the database buffer size   

   METRIC 0721
     COLLECT ITO MW "
       declare
         var number;
       begin
       :dbspi_error := '<no error>';
       select value into  var from v$sga  where name='Database Buffers';
       if var >= 0 then
		:dbspi_value := var;
	else
		:dbspi_value := -1;
	end if;

       end;
     "
#the shared pool  cache hit ratio  

   METRIC 0722
     COLLECT ITO MW "
       declare
         var number;
       begin
       :dbspi_error := '<no error>';
       select sum(pinhits-reloads)/sum(pins)*100 "hit radio" into  var  from v$librarycache;
       if var >= 0 then
		:dbspi_value := var;
	else
		:dbspi_value := -1;
	end if;

       end;
     "
#the buffer pool  hit ratio  

   METRIC 0723
     COLLECT ITO MW "
       declare
         var number;
       begin
       :dbspi_error := '<no error>';
       select 100 - (phy.value - (direct.value + lob.value)) / (consis.value + block.value - (direct.value + lob.value))* 100  "Buffer Cache Hit Ratio" into  var from v$sysstat phy,v$sysstat direct ,v$sysstat lob,v$sysstat consis,v$sysstat block where phy.name='physical reads' and direct.name='physical reads direct' and lob.name='physical reads direct (lob)' and consis.name='consistent gets' and block.name='db block gets';
       if var >= 0 then
		:dbspi_value := var;
	else
		:dbspi_value := -1;
	end if;

       end;
     "

##### the follow reference the special instance 

#the system table_space total  size 
   METRIC 0730
     COLLECT ITO MW "
       declare
         var number;
       begin
       :dbspi_error := '<no error>';
       select sum(BYTES)/1024/1024  into  var from  dba_data_files where  TABLESPACE_NAME='SYSTEM';
       if var >= 0 then
		:dbspi_value := var;
	else
		:dbspi_value := -1;
	end if;

       end;
     "

#the system table_space used   percent 
   METRIC 0731
     COLLECT ITO MW "
       declare
         var number;
       begin
       :dbspi_error := '<no error>';
       select 100 - 100 * (select sum(bytes) from DBA_FREE_SPACE where TABLESPACE_NAME='SYSTEM' ) / (select sum(bytes) from  DBA_DATA_FILES where TABLESPACE_NAME='SYSTEM') as usedratio into  var from  dual;
       if var >= 0 then
		:dbspi_value := var;
	else
		:dbspi_value := -1;
	end if;

       end;
     "

#the system table_space total  size 
   METRIC 0732
     COLLECT ITO MW "
       declare
         var number;
       begin
       :dbspi_error := '<no error>';
       select count(FILE_NAME) into  var from  DBA_DATA_FILES where TABLESPACE_NAME='SYSTEM';
       if var >= 0 then
		:dbspi_value := var;
	else
		:dbspi_value := -1;
	end if;

       end;
     "


