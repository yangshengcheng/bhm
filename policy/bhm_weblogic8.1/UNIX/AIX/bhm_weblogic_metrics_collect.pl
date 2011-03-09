#author : yangshengcheng@gzcss.net
#2010-4-3 23:22
#usage : shs_perl/osspi_perl.sh  bhm_weblogic_metrics_collect.pl  metrics_configfile interval
#descript : this  script use for test  if MBean objects describe in the metrics_desc_file return  correct result
#output : MBean attribute value and warning or error results
use Symbol;
use POSIX qw(strftime);


sub usage{
        print "wasspi_wls_perl $0 metrics_configfile interval"."\t"."or wasspi_wls_perl.sh $0  metrics_configfile    interval\n";
        exit 1;
}



sub  check_env
{
	if($osname=~/win/i)
	{
		$metric_config_file="$ENV{OvDataDir}\\bin\\instrumentation\\";
		$bhm_ftp_temp_dir = "$ENV{OvDataDir}\\bhm\\temp\\";
		$agent_data_dir="$ENV{OvDataDir}\\bhm\\dsi\\";
		$bhm_ftp_err_log = "$ENV{OvDataDir}\\bhm\\bhm_wls_err.txt";
		$ov_install_bin_dir="$ENV{OvInstallDir}\\bin\\";
		$bhm_node_info_dir = "$ENV{OvDataDir}\\bhm\\conf\\";
	}
	elsif($osname=~/tru/i)
	{
		$metric_config_file="/usr/var/opt/OV/bin/instrumentation/";
		$agent_data_dir="/usr/var/opt/OV/bhm/dsi/";
		$bhm_ftp_err_log = "/usr/var/opt/OV/bhm/bhm_wls_err.txt";
		$bhm_ftp_temp_dir = "/usr/var/opt/OV/bhm/temp/";
		$ov_install_bin_dir="/usr/opt/OV/bin/";	
		$bhm_node_info_dir="/usr/var/opt/OV/bhm/conf/";
	}
	else
	{
		$metric_config_file="/var/opt/OV/bin/instrumentation/";
		$agent_data_dir="/var/opt/OV/bhm/dsi/";
		$bhm_ftp_err_log = "/var/opt/OV/bhm/bhm_wls_err.txt";
		$bhm_ftp_temp_dir = "/var/opt/OV/bhm/temp/";
		$bhm_node_info_dir="/var/opt/OV/bhm/conf/";
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

#make csv file name
sub  gencsvname
{
	my ($val) = @_;
	my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)= localtime();
	my $index = sprintf("%d",($hour * 60 + $min ) / $val);
	
	my $name = "weblogic_".$index.".csv";
	return  $name;
	
}

#check  os 
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

##check  if exists the weblogic spi tool 
sub  checkWeblogicSpi
{
	my $weblogic;
	if($osname=~/win/i)
	{
		$weblogic = "wasspi_wls_ca";
	}
	else
	{
		$weblogic = "wasspi_wls_ca";
	}
	
	unless(-e "${metric_config_file}$weblogic")
	{
		&log_ftp_err("can not find weblogic spi tool");
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
		&log_ftp_err("not find config file");
		return  0;
	}
}
### flush  weblogic metric data to csv file

sub  parserWeblogic
{
	my ($MBeans_file)=@_;
	
	my @temp_array=();
	my %temp_hash=();
	my $fl = gensym();
	if(open($fl,$MBeans_file))
	{
		while(my $line=<$fl>)
		{
			next  if($line=~/^\s*$/ || $line=~/^#/);
			if($line=~/(\S+)\s+(\S+)\s+(\S+)/)
			{
				my $mbean=$1;my $attribute=$2;my $metric = $3;my $value = 0;my $instance=0; my $flag=0;my  $entry =0;
				$mbean=~s/MBean//ig;
				if($mbean && $attribute)
				{
					my @rez=`wasspi_wls_perl  -S wasspi_wls_ca -a  -mbean "*:*,Type=${mbean}" -get  ${attribute}`;
					foreach (@rez)
					{
						
						if($_=~/(\S+)\s*\|(.+?)\|(.+?)\|(.+?)\|\s*(\S+)/)
						{
							#print $_;
							$instance = $1;$flag = $3; 
							$value =  $5;
							$temp_hash{$instance}->{$flag}->{'value'} += $value;
							$temp_hash{$instance}->{$flag}->{'metric'} = $metric;
						}
					}
				
				}
			}
		}
		
		close($fl);
		
		##flush  data  to  csv file
		my $timestamp = strftime("%Y%m%d%H%M%S", localtime);
		if(%temp_hash)
		{
#			&flush($timestamp,\@temp_array,"WLSSPI_UDM_METRICS");
			&caculate(\%temp_hash);
			&flush_hash($timestamp,\%temp_hash,"WLSSPI_UDM_METRICS");
		}
		else
		{
			&log_ftp_err("not mbean  metric available");
			exit 1;
		}
	}
	else
	{
		&opcMsg("warning", "\'can not open then  mbean describe file $!\'");
		&log_ftp_err("can not open then  mbean describe file $!");
		exit 1;
	}
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
 sub flush_hash
{
	my ($timestamp,$hash_ref,$class) = @_;
	my $fl = gensym();
	unless(open($fl,">>${agent_data_dir}$filename")) 
	{
    &log_ftp_err("create ${filename} fail");
    exit 1;  
	}
	
	foreach my $server (keys %{$hash_ref})
	{
			$in_name = "WeblogicServer".$server;
			foreach my $couter (keys %{$hash_ref->{$server}})
			{
				print $fl $timestamp."|".$class."|".$hash_ref->{$server}->{$couter}-> {'metric'}."|".$in_name."|".$hash_ref->{$server}->{$couter}->{'value'}."|".$osname."\n";
			}
	} 
	close($fl);
	
	return  ;	
}

sub caculate
{
	my ($hash_ref) = @_;
	
	foreach my $server (keys %{$hash_ref})
	{
		foreach my $couter (keys %{$hash_ref->{$server}})
		{

		}
		if(exists($hash_ref->{$server}->{'HeapFreeCurrent'}-> {'value'}) && exists($hash_ref->{$server}->{'HeapSizeCurrent'}-> {'value'}))
		{
			my $temp =100 - sprintf("%0.2f", $hash_ref->{$server}->{'HeapFreeCurrent'}-> {'value'} * 100 / $hash_ref->{$server}->{'HeapSizeCurrent'}-> {'value'});
			$hash_ref->{$server}->{'HeapFreePercent'}-> {'value'} = $temp;
			$hash_ref->{$server}->{'HeapFreePercent'}-> {'metric'} = 'WLSSPI_0751';
		}
	} 
	return 1;
}

#sent message to  ovo console
sub  opcMsg
{
	my ($severity,$msg_text)=@_;
	my $app='bhm_weblogic_metrics_collect.pl';
	my $obj="weblogic";
	my $msg_grp="weblogic";
	#my $OV_BIN_DIR="/opt/OV/bin/";
	
	if($osname=~/win/i)
	{
		system("opcmsg  severity=${severity} application=${app} object=${obj} msg_grp=${msg_grp}  msg_text=$msg_text");
	}
	else
	{
		system("${ov_install_bin_dir}opcmsg  severity=${severity} application=${app} object=${obj} msg_grp=${msg_grp}  msg_text=$msg_text");
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

sub  trunErrLog
{
	my ($ErrLog)= @_;
	return 1  unless(-e "$ErrLog");
	
	my $fl  =  gensym();
	my $logSize = (-s "$ErrLog");
#	print $logSize;
	if($logSize > 1048578 )
	{
		if(open($fl,">$ErrLog"))
		{
			close($fl);
			return  1;
		}
		else
		{
			return 0;
		}
	}
	else
	{
		return 1;
	}
}




### main ###

#check argument
my $configfile=shift @ARGV || "mbean_console_perf.txt";
my $interval = shift  @ARGV || "10";

#check  env 
our $osname = &checkOs();
our $ov_install_bin_dir;
our $agent_data_dir;
our $metric_config_file;
our $bhm_ftp_temp_dir;
our $bhm_ftp_err_log;



&check_env();
&genDir($agent_data_dir);
&genDir($bhm_ftp_temp_dir);

#truncate logfile before  parser and upload  
&trunErrLog($bhm_ftp_err_log);

#check  oracle config env  
$configfile = $metric_config_file.$configfile;

exit 0 	unless(&checkWeblogicSpi());
exit 0  unless(&checkudmConfig($configfile));

# process env
our $filename;
$filename = &gencsvname($interval);

#load data to csv file
&parserWeblogic($configfile);

### end of main ###

