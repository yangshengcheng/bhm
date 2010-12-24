#!/usr/lpp/OV/nonOV/perl/a/bin/perl -w

#########################################################

#author: yangshengcheng@gzcss.net

#date: 2010-6-17 

#usage: osspi_perl.sh  bhm_os_aix_config_osversion.pl 

#parameter: none

#description: check  os  version config 

#Categories : os config 

##########################################################

#AIX#AIX#AIX#AIX#AIX#AIX#AIX#AIX#AIX#AIX#AIX#AIX#AIX#AIX


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
	my $app='bhm_os_aix_config_osversion.pl';
	my $obj="osversion";
	my $msg_grp="BHM:AIX:CONFIG";
	$msg_text = "'".$msg_text."'";

	system("opcmsg  severity=${severity} application=${app} object=${obj} msg_grp=${msg_grp} msg_text=$msg_text");
}

sub  getCurr
{
	
	my $fl = gensym();
	my $line;
	my $value = 0;
	
	if(open($fl,"/usr/bin/uname -s -r -v|"))
	{
		while($line = <$fl>)
		{
			chomp  $line;
			$value = $line;
		}

		close($fl);
		
		return  $value;
	}
	else
	{
		&SendMsg("normal","invoke uname commad fail");
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
&SetEnv("/usr/lpp/OV/bin");

our $bhm_os_aix_config_dir = "/var/opt/OV/bhm/conf";
unless(-d "$bhm_os_aix_config_dir")
{
	if(system("/usr/bin/mkdir  -p ${bhm_os_aix_config_dir}"))
	{
		&SendMsg("normal","mkdir ${bhm_os_aix_config_dir} fail because $!");
		exit 1;
	}
}

our $bhm_os_aix_config_file = ${bhm_os_aix_config_dir}."/"."bhm_OsConfig_osversion.txt";





my $Curr  = &getCurr();

my $Last = &getLast($Curr,${bhm_os_aix_config_file});

my $flag = &compare($Curr,$Last);

unless($flag)
{	
		&SendMsg("warning","osversion had been changed last:${Last}; \ncurrent:${Curr}");
		
		&saveCurr($bhm_os_aix_config_file,$Curr);
}
### end of main ###