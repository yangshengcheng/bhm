#author : yangshengcheng@gzcss.net
#2010-4-12 13:58
#usage : shs_perl  bhm_os_perf_uptime.pl 
#descript : get windows platform 's uptime in  seconds
#output : uncommect the print line to trace warning or error

use Time::Local;
### set  env ### HTTPS

our $ov_install_bin_dir;
$ov_install_bin_dir="$ENV{OvInstallDir}/bin/";

my $uptime;

my $lastBootTime=`cscript //Nologo  bhm_os_get_LastBootUpTime.vbs`;chomp $lastBootTime;
my $last_year = substr($lastBootTime,0,4);
my $last_month = substr($lastBootTime,4,2);
my $last_day = substr($lastBootTime,6,2);
my $last_hour = substr($lastBootTime,8,2);
my $last_min = substr($lastBootTime,10,2);
my $last_sec = substr($lastBootTime,12,2);

$bootSec = timelocal($last_sec,$last_min,$last_hour,$last_day,$last_month - 1,$last_year);
$uptime = time() - $bootSec;

#### send uptime value
if($uptime >= 0)
{
#	print $uptime;
	&storeValue("bhm_os_win_perf_uptime",$uptime,"UPTIME");
}
else
{
	&opcMsg("warning","\'invalid uptime value\'");
}

### send to  policy 
sub storeValue
{
	my ($policy,$value,$obj)=@_;
	system("\"${ov_install_bin_dir}opcmon\" ${policy}=${value} -obj $obj");
}

#sent message to  ovo console
sub  opcMsg
{
	my ($severity,$msg_text)=@_;
	my $app='bhm_os_perf_uptime';
	my $obj="uptime";
	my $msg_grp="os";
	#my $OV_BIN_DIR="/opt/OV/bin/";

	unless(system("\"${ov_install_bin_dir}opcmsg\"  severity=${severity} application=${app} object=${obj} msg_grp=${msg_grp} msg_text=$msg_text") == 0)
	{
		return 0;
	}
}
