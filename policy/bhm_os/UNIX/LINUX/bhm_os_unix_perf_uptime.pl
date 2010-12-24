#author : yangshengcheng@gzcss.net
#2010-4-12 13:58
#usage : shs_perl  bhm_os_perf_uptime.pl 
#descript : get unix platform 's uptime in  seconds
#output : uncommect the print line to trace warning or error


### set  env ### HTTPS
	
$os = $^O;
#our $ov_agent_bin_dir;
our $ov_install_bin_dir;

 
if($os=~/win/i)
{
#	$ov_agent_bin_dir="$ENV{OvDataDir}/bin/instrumentation";
	$ov_install_bin_dir="$ENV{OvInstallDir}/bin/";
}
elsif($os=~/tru/i)
{
#	$ov_agent_bin_dir="/usr/var/opt/OV/bin/instrumentation";
	$ov_install_bin_dir="/usr/opt/OV/bin/";
	
}
else
{
#	$ov_agent_bin_dir="/var/opt/OV/bin/instrumentation";
	if($os=~/aix/i)
	{
		$ov_install_bin_dir="/usr/lpp/OV/bin/";
	}
	else
	{
		$ov_install_bin_dir="/opt/OV/bin/";
	}
}




my $uptime;


if($os=~/hpux/i)
{
	$string=`UNIX95= ps -p 1 -o etime | tail -1`;chomp $string;
	if($string=~/:/)
	{
		$uptime = &calculate($string);
	}
	else
	{
		&opcMsg("warning","\'invalid uptime format\'");
	}

}
else
{
	$string=`ps -p 1 -o etime | tail -1`;chomp $string;
	if($string=~/:/)
	{
		$uptime = &calculate($string);
	}
	else
	{
		&opcMsg("warning","\'invalid uptime format\'");
	}
}


#### send uptime value
if($uptime >= 0)
{
	#print $uptime;
	&storeValue("bhm_os_unix_perf_uptime",$uptime,"UPTIME");
}
else
{
	&opcMsg("warning","\'invalid uptime value\'");
}

### send to  policy 
sub storeValue
{
	my ($policy,$value,$obj)=@_;
	system("${ov_install_bin_dir}opcmon ${policy}=${value} -obj $obj");
}

#sent message to  ovo console
sub  opcMsg
{
	my ($severity,$msg_text)=@_;
	my $app='bhm_os_perf_uptime.pl';
	my $obj="uptime";
	my $msg_grp="os";
	#my $OV_BIN_DIR="/opt/OV/bin/";
	
	if($^O=~/win/i)
	{
		system("opcmsg  severity=${severity} application=${app} object=${obj} msg_grp=${msg_grp} msg_text=$msg_text");
	}
	else
	{
		system("${ov_install_bin_dir}opcmsg  severity=${severity} application=${app} object=${obj} msg_grp=${msg_grp} msg_text=$msg_text");
	}

}


### calculate uptime seconds
sub calculate
{
	my ($uptimestr)=@_;
	
	if ($uptimestr =~ /[0-9]+\-/) 
	{
		($Days, $Hours, $Minutes, $Seconds) = $uptimestr =~ /([0-9]*)\-?([0-9]+):([0-9]+):([0-9]+)/;
		return $Days * 86400 + $Hours * 3600 + $Minutes * 60 + $Seconds;
	} 
	elsif ($uptimestr =~ /[0-9]+:[0-9]+:[0-9]+/) 
	{
		($Hours, $Minutes, $Seconds) = $uptimestr =~ /([0-9]+):([0-9]+):([0-9]+)/;
		$Days = 0;
		return $Days * 86400 + $Hours * 3600 + $Minutes * 60 + $Seconds;
	} 
	else 
	{
		($Minutes, $Seconds) = $uptimestr =~ /([0-9]+):([0-9]+)/;
		$Days = 0;
		$Hours = 0;
		return $Days * 86400 + $Hours * 3600 + $Minutes * 60 + $Seconds;
	}
}