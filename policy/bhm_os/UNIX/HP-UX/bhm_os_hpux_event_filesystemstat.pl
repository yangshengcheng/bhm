#!/opt/OV/nonOV/perl/a/bin/perl -w

#########################################################

#author: yangshengcheng@gzcss.net

#date: 2010-6-18 

#usage: osspi_perl.sh  bhm_os_hpux_event_filesystemstat.pl -f filesystemMountPoint  -t thresholdValue -s avaliableSize

#parameter: filesystemMountPoint,thresholdValue ,avaliableSize(MB)

#description: check  os's filesystem  config 

#Categories : os event 

##########################################################

#HPUX#HPUX#HPUX#HPUX#HPUX#HPUX#HPUX#HPUX#HPUX#HPUX#HPUX#HPUX#HPUX#HPUX

use Getopt::Std;

use vars qw($opt_f $opt_t $opt_s);
use Symbol;


sub  Usage
{
	print "osspi_perl.sh ".$0." -f filesystemMountPoint  -t thresholdValue -s avaliableSize(MB)\n";
	print "ForExample: "."osspi_perl.sh ".$0." -f /var  -t 90 -s 100\n";
	exit 1;
}

sub SetEnv
{
	my ($dir) = @_;
	$ENV{'PATH'} =  $ENV{'PATH'}.":${dir}";
	
}

sub  SendMsg
{
	my ($severity,$msg_text)=@_;
	my $app='bhm_os_hpux_event_filesystemstat.pl';
	my $obj="filesystem";
	my $msg_grp="BHM:HPUX:EVENT";
	$msg_text = "'".$msg_text."'";

	system("opcmsg  severity=${severity} application=${app} object=${obj} msg_grp=${msg_grp} msg_text=$msg_text");
}

sub  checkFileSystem
{
	my ($f,$t,$s) = @_;
	my $fl = gensym();
	my $line;
	my ($f_temp,$t_temp,$s_temp) = ();

	$SIG{ALRM} = sub{system("ps -ef |grep  /usr/bin/bdf|grep -v grep |awk '{print \$2}'|xargs kill -9");};

	alarm(5);

	if(open($fl,"/usr/bin/bdf|"))
	{
		while($line = <$fl>)
		{
			if($line=~/\d+\s+\d+\s+(\d+)\s+(\d+)\%\s+(\S+)\s*/i)
			{
				$s_temp = $1/1024;$t_temp = $2;$f_temp = $3;
				if($f =~/all/i)
				{
					
					if($s_temp < $s && $t_temp > $t)
					{
						&SendMsg("critical","the directory ${f_temp} is less then ${s} MB, current ${s_temp} MB;and used more then ${t} percent ,current ${t_temp} percent")
					}
					elsif($s_temp < $s && $t_temp < $t )
					{
						&SendMsg("critical","the directory ${f_temp} is less then ${s} MB, current ${s_temp} MB");
					}
					elsif($s_temp > $s && $t_temp > $t)
					{
						&SendMsg("critical","the directory ${f_temp} is used more then ${t} percent,current ${t_temp} percent");
					}
					else
					{
						next;
					}

				}
				else
				{
					if($f_temp eq $f)
					{
						if($s_temp < $s && $t_temp > $t)
						{
							&SendMsg("critical","the directory ${f_temp} is less then ${s} MB, current ${s_temp} MB;and used more then ${t} percent ,current ${t_temp} percent")
						}
						elsif($s_temp < $s && $t_temp < $t )
						{
							&SendMsg("critical","the directory ${f_temp} is less then ${s} MB, current ${s_temp} MB");
						}
						elsif($s_temp > $s && $t_temp > $t)
						{
							&SendMsg("critical","the directory ${f_temp} is used more then ${t} percent,current ${t_temp} percent");
						}
						else
						{
							next;
						}						
					}
					else
					{
						next;
					}
				}
				
			}
		}

		close($fl);
	}
	else
	{
		&SendMsg("normal","invoke bdf  commad fail,because $!");
	}
}


### main process ###  
getopts('f:t:s:');
Usage() unless($opt_f);
$filesystemMountPoint = $opt_f ;
$threshold = $opt_t || 90;
$avaliableSize = $opt_s || 100;

&SetEnv("/opt/OV/bin");

&checkFileSystem($filesystemMountPoint,$threshold,$avaliableSize);

### end of main ###