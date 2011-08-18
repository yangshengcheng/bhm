#!/opt/OV/nonOV/perl/a/bin/perl -w

#########################################################

#author: yangshengcheng@gzcss.net

#date: 2011-5-31 

#usage: osspi_perl.sh  bhm_mysql_query.pl -m variables_desc_file -u mysql_user -p password

#parameter: 

#description: get mysql performent metrics 


##########################################################

#LINUX#LINUX#LINUX#LINUX#LINUX#LINUX#LINUX#LINUX#LINUX#LINUX#LINUX#LINUX#LINUX#LINUX

use DBI;
use POSIX qw(strftime);
use Symbol;
use Getopt::Std;
use vars qw($opt_h $opt_u $opt_p $opt_i);



#### main process #### 
getopts('h:u:p:i');

my $host = $opt_h ||"localhost";
my $user = $opt_u || "root";
my $pw = $opt_p || "";
my $port  = $opt_i || 3306;

## defaule variables
our %hash_temp = ();
our %hash = ();
our $OvDataDir = "/var/opt/OV/bin/instrumentation/";
our @sqls = ();
$sqls[0] = "show global status where Variable_name in ('Threads_created','Threads_connected','Threads_running','Connections','Open_tables','Opened_tables','Key_reads','Key_writes','Key_read_requests','Key_write_requests','Qcache_hits','Qcache_inserts','Table_locks_immediate','Table_locks_waited','Innodb_buffer_pool_reads','Innodb_buffer_pool_read_requests','Table_locks_waited')";
$sqls[1] = "show  global variables where Variable_name in ('table_cache')";


##connect to  mysql database
my  $dbh=DBI->connect("DBI:mysql:database=mysql;host=localhost;port=$port",$user,$pw,{ RaiseError => 1, AutoCommit => 0 })||die;

foreach my $sql(@sqls)
{
	 my $sqr = $dbh->prepare($sql);
	 $sqr->execute();

	 while(my $ref = $sqr->fetchrow_arrayref())
	 {
		if($ref)
		 {
			#print $ref->[0]." ".$ref->[1]."\n";
			$hash_temp{$ref->[0]} = $ref->[1];
		 }
	 }
	$sqr->finish();
}
$dbh->disconnect;


#### caculate the metric values ####

#Threads_connected
$hash{"Threads_connected"} = $hash_temp{"Threads_connected"};

#Threads_running
$hash{"Threads_running"} = $hash_temp{"Threads_running"};

#Table_cache_util
if(exists($hash_temp{"Open_tables"}) && exists($hash_temp{"table_cache"}) )
{
	$hash{"Table_cache_util"} = sprintf("%.2f",100*($hash_temp{"Open_tables"} / $hash_temp{"table_cache"} ));
}
else
{
	$hash{"Table_cache_util"}= "";
}

$hash{"Opened_tables"} = $hash_temp{"Opened_tables"};

#Opened_tables
if(exists($hash_temp{"Key_reads"}) && exists($hash_temp{"Key_read_requests"}))
{
	if($hash_temp{"Key_read_requests"} == 0)
	{
		$hash{"key_buffer_read_hits"} = 100;
	}
	else
	{
		$hash{"key_buffer_read_hits"} = sprintf("%.2f",100*(1 - ($hash_temp{"Key_reads"} / $hash_temp{"Key_read_requests"})));
	}
}
else
{
	$hash{"key_buffer_read_hits"} = "";
}

#key_buffer_write_hits 
if(exists($hash_temp{"Key_writes"}) && exists($hash_temp{"Key_write_requests"}))
{
	if($hash_temp{"Key_write_requests"} == 0)
	{
		$hash{"key_buffer_write_hits"} = 100;
	}
	else
	{
		$hash{"key_buffer_write_hits"} = sprintf("%.2f",100*(1 - ($hash_temp{"Key_writes"} / $hash_temp{"Key_write_requests"})));
	}
}
else
{
	$hash{"key_buffer_write_hits"} = "";
}

#Query_cache_hits 
if(exists($hash_temp{"Qcache_hits"}) && exists($hash_temp{"Qcache_inserts"}))
{
	if(($hash_temp{"Qcache_hits"} + $hash_temp{"Qcache_inserts"}) == 0 )
	{
		$hash{"Query_cache_hits"} = 100;
	}
	else
	{
		$hash{"Query_cache_hits"} = sprintf("%.2f",100*($hash_temp{"Qcache_hits"}/($hash_temp{"Qcache_hits"} + $hash_temp{"Qcache_inserts"} )));
	}
}
else
{
	$hash{"Query_cache_hits"} = "";
}

#Thread_cache_hits
if(exists($hash_temp{"Threads_created"}) && exists($hash_temp{"Connections"}))
{
	if($hash_temp{"Connections"} == 0)
	{
		$hash{"Thread_cache_hits"} = 100;
	}
	else
	{
		$hash{"Thread_cache_hits"} = sprintf("%.2f",100 *($hash_temp{"Threads_created"} / $hash_temp{"Connections"}));
	}
}
else
{
	$hash{"Thread_cache_hits"} = "";
}

#innodb_buffer_read_hits 
if(exists($hash_temp{"Innodb_buffer_pool_reads"}) && exists($hash_temp{"Innodb_buffer_pool_read_requests"}))
{
	if($hash_temp{"Innodb_buffer_pool_read_requests"} == 0)
	{
		$hash{"innodb_buffer_read_hits"} = 100;
	}
	else
	{
		$hash{"innodb_buffer_read_hits"} = sprintf("%.2f",100*(1 - ($hash_temp{"Innodb_buffer_pool_reads"} / $hash_temp{"Innodb_buffer_pool_read_requests"})));
	}
}
else
{
	$hash{"innodb_buffer_read_hits"} = "";
}

#Table_lock_hits
if(exists($hash_temp{"Table_locks_immediate"}) && exists($hash_temp{"Table_locks_waited"}))
{
	if(($hash_temp{"Table_locks_immediate"} + $hash_temp{"Table_locks_waited"}) == 0)
	{
		$hash{"Table_lock_hits"} = 100;
	}
	else
	{
		$hash{"Table_lock_hits"} = sprintf("%.2f",100*($hash_temp{"Table_locks_immediate"} / ($hash_temp{"Table_locks_immediate"} + $hash_temp{"Table_locks_waited"})));
	}
}
else
{
	$hash{"Table_lock_hits"} = "";
}

#Table_locks_waited
$hash{"Table_locks_waited"} = $hash_temp{"Table_locks_waited"};

#### now write data to file ####
our $dataFile = "test.csv";
our $timestamp = strftime("%Y%m%d%H%M%S", localtime);
our $Ostype = &checkOs();


if(open(FL,">$dataFile"))
{
	foreach my $key(keys %hash)
	{
		print FL $timestamp."|"."GLOBAL"."|".$key."|".$hash{$key}."|"."NULL"."|".$Ostype."\n";
	}
	close(FL);
}
else
{
	foreach my $key(keys %hash)
	{
		print $timestamp."|"."GLOBAL"."|".$key."|".$hash{$key}."|"."NULL"."|".$Ostype."\n";
	}
}


#### additional  function ####

sub  checkOs
{
	if($^O=~/hpux/i)
	{
		return 'HP-UX';
	}
	else
	{
		return  $^O;
	}
}

