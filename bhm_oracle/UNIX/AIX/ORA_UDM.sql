#this  file is use for user define metric
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

# no meaning
  METRIC 0701
     COLLECT ITO MW "
       declare
         var number;
       begin
       :dbspi_error := '<no error>';
       var := 1;
       if var > 0 then
                :dbspi_value := var;
        else
                :dbspi_value := -1;
        end if;

       end;
     "

 # no meaning
  METRIC 0702
     COLLECT ITO MW "
       declare
         var number;
       begin
       :dbspi_error := '<no error>';
       var := 1;
       if var > 0 then
                :dbspi_value := var;
        else
                :dbspi_value := -1;
        end if;

       end;
     "

 # no meaning
  METRIC 0703
     COLLECT ITO MW "
       declare
         var number;
       begin
       :dbspi_error := '<no error>';
       var := 1;
       if var > 0 then
                :dbspi_value := var;
        else
                :dbspi_value := -1;
        end if;

       end;
     "

 # no meaning
  METRIC 0704
     COLLECT ITO MW "
       declare
         var number;
       begin
       :dbspi_error := '<no error>';
       var := 1;
       if var > 0 then
                :dbspi_value := var;
        else
                :dbspi_value := -1;
        end if;

       end;
     "

 # no meaning
  METRIC 0705
     COLLECT ITO MW "
       declare
         var number;
       begin
       :dbspi_error := '<no error>';
       var := 1;
       if var > 0 then
                :dbspi_value := var;
        else
                :dbspi_value := -1;
        end if;

       end;
     "

 # no meaning
  METRIC 0706
     COLLECT ITO MW "
       declare
         var number;
       begin
       :dbspi_error := '<no error>';
       var := 1;
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
# no meaning
  METRIC 0711
     COLLECT ITO MW "
       declare
         var number;
       begin
       :dbspi_error := '<no error>';
       var := 1;
       if var > 0 then
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
       select sum(pinhits-reloads)/sum(pins)*100  into  var  from v$librarycache;
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
       select 100 - (phy.value - (direct.value + lob.value)) / (consis.value + block.value - (direct.value + lob.value))* 100   into  var from v$sysstat phy,v$sysstat direct ,v$sysstat lob,v$sysstat consis,v$sysstat block where phy.name='physical reads' and direct.name='physical reads direct' and lob.name='physical reads direct (lob)' and consis.name='consistent gets' and block.name='db block gets';
       if var >= 0 then
                :dbspi_value := var;
        else
                :dbspi_value := -1;
        end if;

       end;
     "

# SHARED POOL used ratio
  METRIC 0724
     COLLECT ITO MW "
       declare
         var number;
       begin
       :dbspi_error := '<no error>';
       select 100 - bytes * 100 / (select sum(bytes) from  v$sgastat  where pool='shared pool' group by pool) into  var  FROM  v$sgastat WHERE pool='shared pool' AND name='free memory';
       if var > 0 then
                :dbspi_value := var;
        else
                :dbspi_value := -1;
        end if;

       end;
     "

# shared pool busy ratio
  METRIC 0725
     COLLECT ITO MW "
       declare
         var number;
       begin
       :dbspi_error := '<no error>';
       select a.value * 100 /(a.value + b.value) into  var from  v$sysstat a ,v$sysstat b where a.name='buffer is pinned count' and b.name='buffer is not pinned count';
       if var > 0 then
                :dbspi_value := var;
        else
                :dbspi_value := -1;
        end if;

       end;
     "

# data library hit ratio
  METRIC 0726
     COLLECT ITO MW "
       declare
         var number;
       begin
       :dbspi_error := '<no error>';
       select sum(gets-getmisses)/sum(gets) * 100 into  var from v$rowcache;
       if var > 0 then
                :dbspi_value := var;
        else
                :dbspi_value := -1;
        end if;

       end;
     "

 # get lock ratio 
  METRIC 0727
     COLLECT ITO MW "
       declare
         var number;
       begin
       :dbspi_error := '<no error>';
       select 100 - sum(MISSES) * 100 / sum(GETS) into var from v$latch;
       if var > 0 then
                :dbspi_value := var;
        else
                :dbspi_value := -1;
        end if;

       end;
     "

#  high database buffer cache hit ratio
  METRIC 0728
     COLLECT ITO MW "
       declare
         var number;
       begin
       :dbspi_error := '<no error>';
       select sum(Pins)/(Sum(Pins) + sum(Reloads)) * 100 into  var  from V$LibraryCache;
       if var > 0 then
                :dbspi_value := var;
        else
                :dbspi_value := -1;
        end if;

       end;
     "


 # logical  reads 
  METRIC 0729
     COLLECT ITO MW "
       declare
         var number;
       begin
       :dbspi_error := '<no error>';
       select value into var  from v$sysstat where name='session logical reads';
       if var > 0 then
                :dbspi_value := var;
        else
                :dbspi_value := -1;
        end if;

       end;
     "

 # logical  write 
  METRIC 0730
     COLLECT ITO MW "
       declare
         var number;
       begin
       :dbspi_error := '<no error>';
       var := 1;
       if var > 0 then
                :dbspi_value := var;
        else
                :dbspi_value := -1;
        end if;

       end;
     "

 # system tablespace available  size
  METRIC 0731
     COLLECT ITO MW "
       declare
         var number;
       begin
       :dbspi_error := '<no error>';
       select  ((select sum(BYTES)  from  dba_data_files where  TABLESPACE_NAME='SYSTEM') -  (select sum(bytes) from dba_free_space  where TABLESPACE_NAME='SYSTEM'))/1024/1024 into  var  from  dual ;
       if var > 0 then
                :dbspi_value := var;
        else
                :dbspi_value := -1;
        end if;

       end;
     "

# temp tablespace available size
  METRIC 0732
     COLLECT ITO MW "
       declare
         var number;
       begin
       :dbspi_error := '<no error>';
       select sum(BYTES_FREE)/1024/1024 free_MB into var from V$TEMP_SPACE_HEADER where TABLESPACE_NAME in (select distinct temporary_tablespace   from  dba_users);
       if var > 0 then
                :dbspi_value := var;
        else
                :dbspi_value := -1;
        end if;

       end;
     "
     
     
 # rollback  space available size in mb 
  METRIC 0733
     COLLECT ITO MW "
       declare
         var number;
       begin
       :dbspi_error := '<no error>';
       select sum((select BYTES from dba_extents where SEGMENT_TYPE='ROLLBACK' and rownum=1)*(MAX_EXTENTS - EXTENTS))/1024/1024 into var from dba_segments where  SEGMENT_TYPE='ROLLBACK';
       if var > 0 then
                :dbspi_value := var;
        else
                :dbspi_value := -1;
        end if;

       end;
     "
     
     
# extents available space size in mb
  METRIC 0734
     COLLECT ITO MW "
       declare
         var number;
       begin
       :dbspi_error := '<no error>';
       select sum(bytes)/1024/1024 into  var  from dba_free_space;
       if var > 0 then
                :dbspi_value := var;
        else
                :dbspi_value := -1;
        end if;

       end;
     " 
     
 # redo logfile increase speed per interval
  METRIC 0735
     COLLECT ITO MW "
       declare
         var number;
       begin
       :dbspi_error := '<no error>';
       var := 1;
       if var > 0 then
                :dbspi_value := var;
        else
                :dbspi_value := -1;
        end if;

       end;
     "
     
 # total available locks
  METRIC 0736
     COLLECT ITO MW "
       declare
         var number;
       begin
       :dbspi_error := '<no error>';
       select count(*) into  var from  v$latch;
       if var > 0 then
                :dbspi_value := var;
        else
                :dbspi_value := -1;
        end if;

       end;
     "
     
     
 # lock util ratio
  METRIC 0737
     COLLECT ITO MW "
       declare
         var number;
       begin
       :dbspi_error := '<no error>';
       select 100 - 100 * (sum(MISSES) / sum(GETS)) into  var from  v$latch;
       if var > 0 then
                :dbspi_value := var;
        else
                :dbspi_value := -1;
        end if;

       end;
     "
     
     
 # lock  wait time 
  METRIC 0738
     COLLECT ITO MW "
       declare
         var number;
       begin
       :dbspi_error := '<no error>';
       var := 1;
       if var > 0 then
                :dbspi_value := var;
        else
                :dbspi_value := -1;
        end if;

       end;
     "
     
 # lock  wait ratio
  METRIC 0739
     COLLECT ITO MW "
       declare
         var number;
       begin
       :dbspi_error := '<no error>';
       select 100 * (sum(MISSES) / sum(GETS)) into  var from  v$latch;
       if var > 0 then
                :dbspi_value := var;
        else
                :dbspi_value := -1;
        end if;

       end;
     "               

 # cpu  util  
  METRIC 0740
     COLLECT ITO MW "
       declare
         var number;
       begin
       :dbspi_error := '<no error>';
       var := 1;
       if var > 0 then
                :dbspi_value := var;
        else
                :dbspi_value := -1;
        end if;

       end;
     "

 # mem util 
  METRIC 0741
     COLLECT ITO MW "
       declare
         var number;
       begin
       :dbspi_error := '<no error>';
       var := 1;
       if var > 0 then
                :dbspi_value := var;
        else
                :dbspi_value := -1;
        end if;

       end;
     "

 # session util  
  METRIC 0742
     COLLECT ITO MW "
       declare
         var number;
       begin
       :dbspi_error := '<no error>';
       select 100 *((select count(*) from v$session) / (select value from  v$parameter where name ='sessions')) into  var from dual;
       if var > 0 then
                :dbspi_value := var;
        else
                :dbspi_value := -1;
        end if;

       end;
     "
     
 #available sessiones
  METRIC 0743
     COLLECT ITO MW "
       declare
         var number;
       begin
       :dbspi_error := '<no error>';
       select (select value from  v$parameter where name='sessions') - (select count(*) from  v$session)  into  var from  dual;
       if var > 0 then
                :dbspi_value := var;
        else
                :dbspi_value := -1;
        end if;

       end;
     "

 # available transanction 
  METRIC 0744
     COLLECT ITO MW "
       declare
         var number;
       begin
       :dbspi_error := '<no error>';
       var := 1;
       if var > 0 then
                :dbspi_value := var;
        else
                :dbspi_value := -1;
        end if;

       end;
     "

 #  transanctions util   
  METRIC 0745
     COLLECT ITO MW "
       declare
         var number;
       begin
       :dbspi_error := '<no error>';
       var := 1;
       if var > 0 then
                :dbspi_value := var;
        else
                :dbspi_value := -1;
        end if;

       end;
     "


 # checkpoint sum 
  METRIC 0746
     COLLECT ITO MW "
       declare
         var number;
       begin
       :dbspi_error := '<no error>';
       select sum(value) from v$sysstat into var where name like '%checkpoints%'; 
       if var > 0 then
                :dbspi_value := var;
        else
                :dbspi_value := -1;
        end if;

       end;
     "


 # checkpoint interval 
  METRIC 0747
     COLLECT ITO MW "
       declare
         var number;
       begin
       :dbspi_error := '<no error>';
       select value into  var from v$parameter where name ='log_checkpoint_timeout';
       if var > 0 then
                :dbspi_value := var;
        else
                :dbspi_value := -1;
        end if;

       end;
     "




















       