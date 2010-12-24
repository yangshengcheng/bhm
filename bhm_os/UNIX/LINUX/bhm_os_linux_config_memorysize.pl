#!/opt/OV/nonOV/perl/a/bin/perl -w

#########################################################

#author: yangshengcheng@gzcss.net

#date: 2010-6-18 

#usage: osspi_perl.sh  bhm_os_linux_config_memorysize.pl 

#parameter: none

#description: check  memory size config 

#Categories : os config 

##########################################################

#LINUX#LINUX#LINUX#LINUX#LINUX#LINUX#LINUX#LINUX#LINUX#LINUX#LINUX#LINUX#LINUX#LINUX


use Symbol;


sub  Usage
{
	print "osspi_perl.sh ".$0."\n";
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
	my $app='bhm_os_linux_config_memorysize.pl';
	my $obj="memory";
	my $msg_grp="BHM:LINUX:CONFIG";
	$msg_text = "'".$msg_text."'";

	system("opcmsg  severity=${severity} application=${app} object=${obj} msg_grp=${msg_grp} msg_text=$msg_text");
}

sub  getCurr
{
	
	my $fl = gensym();
	my $line;
	my $value = 0;
	
	if(open($fl,"/proc/meminfo"))
	{
		while($line = <$fl>)
		{
			if($line=~/MemTotal\s*:\s*(\d+)\s*kb/i)
			{
				$value = $value + $1;
			}
		}

		close($fl);
		
		return  $value;
	}
	else
	{
		&SendMsg("normal","open /proc/meminfo commad fail");
		return 0;
	}
}

sub  getLast
{
	my ($curr,$filepath) = @_;
	my $fl = gensym();
	my $value = 0;

	if(! -e "$filepath")
	{
		if(open($fl,">${filepath}"))
		{
				print $fl $curr."\n";

			close($fl);
		}
		else
		{
			&SendMsg("normal","open ${filepath} fail beacause $!");
		}
		print "first  monitor\n";
		exit 0;
	}
	elsif(-s "${filepath}" == 0)
	{
		if(open($fl,">${filepath}"))
		{
				print $fl $curr."\n";

			close($fl);
		}
		else
		{
			&SendMsg("normal","open ${filepath} fail beacause $!");
		}		
	}
	else
	{
		if(open($fl,"$filepath"))
		{
			my $line;
			while($line = <$fl>)
			{
				chomp  $line;
				$value = $line;
			}
			close($fl);
		}
		else
		{
			&SendMsg("normal","open ${filepath} fail beacause $!");
		}
	}
	
	return  $value;

}


sub  compare
{
	my ($Last,$Curr) = @_;
	
	my $flag = 0;
	
	if($Last  eq  $Curr)
	{
		$flag = 1;
	}
	return $flag;
	
}

sub  saveCurr
{
	my ($file,$curr) = @_;
	my $fl =  gensym();
	if(open($fl,">${file}"))
	{
		print $fl $curr."\n";
		
		close($fl);
	}
	else
	{
		&SendMsg("normal","open ${file} fail because $!");
	}
}
### main process ###  

#Usage() unless();
&SetEnv("/opt/OV/bin");

our $bhm_os_linux_config_dir = "/var/opt/OV/bhm/conf";
unless(-d "$bhm_os_linux_config_dir")
{
	if(system("/bin/mkdir  -p ${bhm_os_linux_config_dir}"))
	{
		&SendMsg("normal","mkdir ${bhm_os_linux_config_dir} fail because $!");
		exit 1;
	}
}

our $bhm_os_linux_config_file = ${bhm_os_linux_config_dir}."/"."bhm_OsConfig_memorysize.txt";





my $Curr  = &getCurr();

my $Last = &getLast($Curr,${bhm_os_linux_config_file});

my $flag = &compare($Curr,$Last);

unless($flag)
{	
		&SendMsg("warning","memory size  had been changed last:${Last} kb; \ncurrent:${Curr} kb");
		
		&saveCurr($bhm_os_linux_config_file,$Curr);
}
### end of main ###