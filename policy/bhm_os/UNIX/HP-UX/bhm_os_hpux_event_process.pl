#!/usr/bin/perl -w

#author: yangshengcheng@gzcss.net
#date :2010-12-06
#platform : just for hpux
#input : process key word
#output : error or warn to ovo if process word in a bad condition
#description :check aix process's status
#severity=normal|warning|minor|major|critical


use Getopt::Std;
use vars qw($opt_k);
use Symbol;
use File::Basename;

#### functions ####
sub usage
{
	print("usage: osspi_perl.sh $0 -k processKeyWord1:num1,processKeyWord2:num2...\n");
	exit 1;
}


# set important env variables and libs
sub SetEnv
{
	my ($dir) = @_;
	$ENV{'PATH'} =  $ENV{'PATH'}.":${dir}";
	
}
#### print_msg: interface to opcmsg(1) ####
#### usage: print_msg <sev> <text> ####


sub print_msg 
{
	my ($severity,$msg_text,$obj)=@_;
#	print "$severity"."\t".$msg_text."\n";
	my $app='bhm_os_aix_event_process.pl';
	my $msg_grp="BHM:AIX:EVENT";
	my $node=$node_fqdn;
	$msg_text = "'".$msg_text."'";

	system("opcmsg  severity=${severity} application=${app} object=${obj} msg_grp=${msg_grp} node=$node msg_text=$msg_text");
}

sub  get_local_ip
{
	my $localip;
	my $line;
	my $nodeinfo = "${ov_agt_tool_dir}nodeinfo";
	my $fl =  gensym();
	if(-e "$nodeinfo")
	{
		if(open($fl,$nodeinfo))
		{
			while($line=<$fl>)
			{
				if($line=~/ip\s+(\d+\.\d+\.\d+\.\d+)/i)
				{
					$localip = $1;
					close($fl);
					return  $localip;
				}
			}
			close($fl);
		}
	}
	my $hostname=`hostname`;chomp $hostname;
	if($^O=~/win/i)
	{
		unless(open(HOSTS,"C:\\WINDOWS\\system32\\drivers\\etc\\hosts"))
		{
			exit 1;
		}
		
	}
	else
	{
			unless(open(HOSTS,"/etc/hosts"))
			{
				exit 1;
			}
	}
	
	while( $line=<HOSTS>)
	{
		next if($line=~/^#/);
		if($line=~/(\d+\.\d+\.\d+\.\d+)\s+(${hostname}$|${hostname}\.\S+)/i)
		{
			$localip = $1;
			undef($localip) if($localip =~/127\.0\.0\.1/);
			last;
		}
	}
	close(HOSTS);
	
	if($localip)
	{
		return  $localip;
	}
	else
	{
		return  $hostname;
	}
	
	
}

sub check_dir
{
	my ($dir) = @_;
	unless(-d  $dir)
	{
		system("mkdir -p  $dir");
		system("chmod -R 766 $dir");
	}
}

# get process info from ps command
sub get_process_list
{
	my ($key) = @_;
	# different os has different argument be carefull
	system("ps -eflx >${process_list_temp} 2>/dev/null");
	return 1;
}

# check process list temp file  
sub  check_process_file
{
	my ($file) = @_;
	my $text;
	unless(-e $file)
	{
		$text = "process list file is not exist";
		&print_msg("warning",$text,"process");
		return 0;
	}

	my $size = (-s $file);
	if($size <= 0 )
	{
		$text = "process list file is empty";
		&print_msg("warning",$text,"process");
		return 0;
	}
	return 1;

}

# analyse the process list
sub check_process
{
	my ($file,$pkey) = @_;
	my $l ;
	my $n = 0;
	my $text ;

	my $pid;
	my $status ;
	my $command;

	# is it format ok?
	unless($pkey=~/\S+:\d+/)
	{
		$text = "bad format argument";
		&print_msg("warning",$text,"$PROGRAM_NAME");
		return 0;
	}


	my ($k,$v) = split(/:/,$pkey);

	my $fl = gensym();

	unless(open($fl,$file))
	{
		$text = "$!";
		&print_msg("warning",$text,"$PROGRAM_NAME");
		return 0;
	}

	while($l = <$fl>)
	{
		#if($l =~/\S+\s+(\d+)\s+\d+\.\d+\s+\d+\.\d+\s+\d+\s+\d+\s+\S+\s+(\w+)\s+(.*)/)
		if($l=~/\d+\s+(\w+)\s+\S+\s+(\d+)\s+\d+\s+(.*)/)
		{
			$pid = $2; $status = $1; $command = $3;
			if($command=~/$k/i)
			{
				unless($command =~/$PROGRAM_NAME/i)
				{
					if($status=~/O|Z|T/i)
					{
						$text = "$k process pid=${pid} in  bad  condition $status";
						&print_msg("critical",$text,$k."pid=$pid");
					}
					$n++;
				}
			}
		}
	}

	if($n < $v)
	{
		$text = "$k process  less then expect $v,current $n";
		&print_msg("critical",$text,$k);
	}


}
### end of functions ###


#### main  process ####

#### ovo env define ####
our $PROGRAM_NAME = basename($0);
our $ov_agt_bin_dir="/opt/OV/bin";
our $ov_agt_tool_dir='/var/opt/OV/bin/instrumentation/';
our $ov_bhm_temp_dir='/var/opt/OV/bhm/temp/';
our $process_list_temp = $ov_bhm_temp_dir.'process_temp_list'.$$;
our @keywords = ();
#### argument deal ####
getopts('k:');

usage() unless($opt_k);

#split the process keys 
@keywords = split(/,/,$opt_k);

our $node_fqdn = &get_local_ip();
#export ovo agent bin to  PATH
&SetEnv($ov_agt_bin_dir);

&check_dir($ov_bhm_temp_dir);

&get_process_list();

&check_process_file($process_list_temp);

foreach my $i (@keywords)
{
	&check_process($process_list_temp,$i);
}

#delete the process list temp file
unlink($process_list_temp);