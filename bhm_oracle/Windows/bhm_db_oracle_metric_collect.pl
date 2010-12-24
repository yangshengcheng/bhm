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
        print "shs_perl $0 metric_scope interval"."\t"."or osspi_perl.sh  metric_scope $0  interval\n";
        exit 1;
}

##check  if exists the dbspicao tool 
sub  checkOracleSpi
{
	my $dbspicao;
	if($osname=~/win/i)
	{
		$dbspicao = "dbspicao.bat";
	}
	else
	{
		$dbspicao = "dbspicao";
	}
	
	unless(-e "$dbspicao")
	{
		return 0
	}
	else
	{
		return  1;
	}
}

#check if exists the oracle udm config file  
sub  checkudmConfig
{
	my ($config_file)=@_;
	if(-e "$config_file")
	{
		return 1;
	}
	else
	{
		return  0;
	}
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
	open(ERR,">>$bhm_ftp_err_log");
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
		$bhm_ftp_err_log = "$ENV{OvDataDir}\\bhm\\bhm_ftp_err.txt";
		$ov_install_bin_dir="$ENV{OvInstallDir}\\bin\\";
		$dbspi_udm_config = "$ENV{OvDataDir}\\Conf\\dbspi\\udm_config\\dbspiudm.cfg"
		
	}
	elsif($osname=~/tru/i)
	{
		$metric_config_file="/usr/var/opt/OV/bin/instrumentation/";
		$agent_data_dir="/usr/var/opt/OV/bhm/dsi/";
		$bhm_ftp_err_log = "/usr/var/opt/OV/bhm/bhm_ftp_err.txt";
		$bhm_ftp_temp_dir = "/usr/var/opt/OV/bhm/temp/";
		$ov_install_bin_dir="/usr/opt/OV/bin/";
		$dbspi_udm_config = "/usr/var/opt/OV/conf/dbspi/udm_config/dbspiudm.cfg";	
	}
	else
	{
		$metric_config_file="/var/opt/OV/bin/instrumentation/";
		$agent_data_dir="/var/opt/OV/bhm/dsi/";
		$bhm_ftp_err_log = "/var/opt/OV/bhm/bhm_ftp_err.txt";
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
sub  parserDbspicao
{
	my ($scope)=@_;
	my $timestamp = strftime("%Y%m%d%H%M%S", localtime);
	my @temp=();
	my $fl =  gensym();
	if($osname=~/win/i)
	{
		unless(open($fl,"dbspicao -m  ${scope} -p|"))
		{
			  &log_ftp_err("execute dbspicao fail");
        exit 1; 	
		}
	}
	else
	{
		unless(open($fl,"./dbspicao -m  ${scope} -p|"))
		{
			  &log_ftp_err("execute dbspicao fail");
        exit 1; 	
		}		
	}
	
	while(my $line=<$fl>)
	{
		if($line=~/(\S+)\s+0(\d+)\s+(\S+)/)
		{
			my $instance = $1;my $metric = $2;my $value = $3;
			my $entry = "UDM_".$metric."|".$instance."|".$value;
			push(@temp,$entry);
		}
	}
	
	close($fl);
	
#flush  oracle metric data  to  csv file
	&flush($timestamp,\@temp,"DBSPI_ORA_UDM");
}

#flush  oracle metric data  to  csv file
sub flush
{
	my ($timestamp,$array_ref,$class)=@_;
	my $fl = gensym();
	unless(open($fl,">>${agent_data_dir}$filename")) 
	{
    &log_ftp_err("create ${filename} fail");
    exit 1;  
	}
	
	foreach my $entry(@{$array_ref})
	{
		print $fl $timestamp."|".$class."|".$entry."|".$osname."\n";
	}
	close($fl);
	
	return  ;
}


### main ###

#check argument
usage if(!defined(@ARGV) || (scalar(@ARGV) < 2));
my $scope=shift @ARGV;
my $interval = shift  @ARGV || "60";

#check  env 
our $osname = &checkOs();
our $ov_install_bin_dir;
our $agent_data_dir;
our $metric_config_file;
our $bhm_ftp_temp_dir;
our $bhm_ftp_err_log;
our $dbspi_udm_config;


&check_env();
&genDir($agent_data_dir);
&genDir($bhm_ftp_temp_dir);

#check  oracle config env  
exit 0 	unless(&checkOracleSpi());
exit 0  unless(&checkudmConfig($dbspi_udm_config));

# process env
our $filename;
$filename = &gencsvname($interval);

#load data to csv file
&parserDbspicao($scope);

### end of main ###