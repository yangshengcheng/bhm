#!/bin/sh
#ORACLE_HOME=/oracle/produce/10.2.0/db
USER=$1
PASSWD=$2
INDEX=`/usr/bin/date +"%M"`
OS=`uname`

#echo "************************************************"
#echo "Database performent and config  information:"
#echo "************************************************"
sqlplus -S $USER/$PASSWD @/var/opt/OV/bin/instrumentation/bhm_db_oracle_metric_spl.sql ora_${INDEX}.csv  $OS