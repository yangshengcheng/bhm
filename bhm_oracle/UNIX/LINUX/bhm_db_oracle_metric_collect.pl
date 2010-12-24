#!/usr/bin/perl -w
#author: yangshengcheng@gzcss.net
#date: 2010-4-27
#usage: invoked by ovo scheduled task  policy (bhm_db_oracle_metric_collect)
#parameter: no
#description: query oracle performent data 
#Categories : bhm  oracle policy


use Symbol;
use POSIX qw(strftime);


sub usage{
        print "shs_perl $0  interval(for windows)"."\t"."or osspi_perl.sh $0  interval(for unix)\n";
        exit 1;
}

##check  data source
sub  checkData 
{
	return  1;
}


#change hpux 's os stamp
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

# generate the the filename
sub  gencsvname
{
	my ($val) = @_;
	my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)= localtime();
	my $index = sprintf("%d",($hour * 60 + $min ) / $val);
	
	my $name = "ora_".$index.".csv";
	return  $name;
	
}

#check  and generate the necessarily dir
sub genDir
{
	my ($dir)=@_;
	if($osname=~/win/i)
	{
		unless(-d  $dir)
		{
			system("mkdir \"$dir\"");
		}
	}
	else
	{
		unless(-d  $dir)
		{
			system("mkdir -p  $dir");
		}
	}
}

##log warn and error
sub  log_ftp_err
{
	my ($text)=@_;
	my $timestamp = strftime("%Y%m%d%H%M%S", localtime);
	open(ERR,">>$bhm_oracle_err_log");
	print ERR $timestamp."\t".$text."\n";
	close(ERR);
	
}

#check  the basic variable
sub  check_env
{
	if($osname=~/win/i)
	{
		$metric_config_file="$ENV{OvDataDir}\\bin\\instrumentation\\";
		$bhm_ftp_temp_dir = "$ENV{OvDataDir}\\bhm\\temp\\";
		$agent_data_dir="$ENV{OvDataDir}\\bhm\\dsi\\";
		$bhm_oracle_err_log = "$ENV{OvDataDir}\\bhm\\bhm_oracle_err.txt";
		$ov_install_bin_dir="$ENV{OvInstallDir}\\bin\\";
		$dbspi_udm_config = "$ENV{OvDataDir}\\Conf\\dbspi\\udm_config\\dbspiudm.cfg"
		
	}
	elsif($osname=~/tru/i)
	{
		$metric_config_file="/usr/var/opt/OV/bin/instrumentation/";
		$agent_data_dir="/usr/var/opt/OV/bhm/dsi/";
		$bhm_oracle_err_log = "/usr/var/opt/OV/bhm/bhm_oracle_err.txt";
		$bhm_ftp_temp_dir = "/usr/var/opt/OV/bhm/temp/";
		$ov_install_bin_dir="/usr/opt/OV/bin/";
		$dbspi_udm_config = "/usr/var/opt/OV/conf/dbspi/udm_config/dbspiudm.cfg";	
	}
	else
	{
		$metric_config_file="/var/opt/OV/bin/instrumentation/";
		$agent_data_dir="/var/opt/OV/bhm/dsi/";
		$bhm_oracle_err_log = "/var/opt/OV/bhm/bhm_oracle_err.txt";
		$bhm_ftp_temp_dir = "/var/opt/OV/bhm/temp/";
		$dbspi_udm_config = "/var/opt/OV/conf/dbspi/udm_config/dbspiudm.cfg";
		if($osname=~/aix/i)
		{
			$ov_install_bin_dir="/usr/lpp/OV/bin/";
		}
		else
		{
			$ov_install_bin_dir="/opt/OV/bin/";
		}
	}
}

## parser dbspicao  rezult
sub  parserDBSPI_ORA_UDM
{
#	my $timestamp = strftime("%Y%m%d%H%M%S", localtime);
	my @temp=();
	my $fl =  gensym();
	
	if($osname=~/win/i)
	{
		unless(open($fl,"ovcodautil -dumpds DBSPI_ORA_UDM|"))
		{
			  &log_ftp_err("execute ovcodautil fail");
        exit 1; 	
		}
	}
	else
	{
		unless(open($fl,"${ov_install_bin_dir}ovcodautil -dumpds DBSPI_ORA_UDM|"))
		{
			  &log_ftp_err("execute ovcodautil fail");
        exit 1; 	
		}		
	}
	
	while(my $line=<$fl>)
	{
			if($line=~/^(\d+)\/(\d+)\/\d+\s+(\d+):(\d+):(\d+)(.*?)\|(\w+)\s*\|(.+?)\|/)
			{					
					my $mon = $1;my $day=$2;my $hour=$3;my $min = $4;my $sec=$5;my $AMPM= $6;my $metric=$7;my $value=$8;
					if($AMPM && $AMPM =~/PM/i)
					{
						$hour = $hour +  12;
					}
					
					if($value=~/\s*-1/i)
					{
						next;
					}
					
					if($metric=~/INSTANCENAME/i)
					{
							$ora_instance_name = $value;
							next;
					}

					
					if($ora_instance_name)
					{						
								my $entry =$year.$mon.$day.$hour.$min.$sec.'|'.'DBSPI_ORA_UDM'.'|'.$metric.'|'.$ora_instance_name.'|'.$value;
								push(@temp,$entry);
					}
			}
	}
	
	close($fl);
	
#flush  oracle metric data  to  csv file
	&flush(\@temp,"DBSPI_ORA_UDM");
}

#flush  oracle metric data  to  csv file
sub flush
{
	my ($array_ref,$class)=@_;
	my $fl = gensym();
	unless(open($fl,">>${agent_data_dir}$filename")) 
	{
    &log_ftp_err("create ${filename} fail");
    exit 1;  
	}
	
	foreach my $entry(@{$array_ref})
	{
		print $fl $entry."|".$osname."\n";
	}
	close($fl);
	
	return  ;
}


### main ###

#check argument
usage if(scalar(@ARGV) > 2);
#my $scope=shift @ARGV;
my $interval = shift  @ARGV || "60";

#check  env 
our $osname = &checkOs();
our $ov_install_bin_dir;
our $agent_data_dir;
our $metric_config_file;
our $bhm_ftp_temp_dir;
our $bhm_oracle_err_log;
our $dbspi_udm_config;


&check_env();
&genDir($agent_data_dir);
&genDir($bhm_ftp_temp_dir);

our $year = strftime("%Y",localtime);
#check  oracle config env  


# process env
our $filename;
$filename = &gencsvname($interval);

#set language env to english  before call ovcodauitl 
$ENV{'LC_ALL'}=C unless($osname=~/win/i);
#load data to csv file
&parserDBSPI_ORA_UDM();

### end of main ###