#!/opt/OV/nonOV/perl/a/bin/perl -w

#########################################################

#author: yangshengcheng@gzcss.net

#date: 2010-6-23 

#usage: osspi_perl.sh  bhm_os_hpux_config_nicsum.pl 

#parameter: none

#description: check  total number of network interface card config 

#Categories : os config 

##########################################################

#HPUX#HPUX#HPUX#HPUX#HPUX#HPUX#HPUX#HPUX#HPUX#HPUX#HPUX#HPUX#HPUX#HPUX


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
	my $app='bhm_os_hpux_config_nicsum.pl';
	my $obj="nic";
	my $msg_grp="BHM:HPUX:CONFIG";
	$msg_text = "'".$msg_text."'";

	system("opcmsg  severity=${severity} application=${app} object=${obj} msg_grp=${msg_grp} msg_text=$msg_text");
}

sub  getCurr
{
	
	my $fl = gensym();
	my $line;
	my @names=();
	if(open($fl,"/usr/sbin/ioscan -funC lan|"))
	{
		while($line = <$fl>)
		{
			if($line=~/lan\s+\d+\s+\S+\s+\S+\s+\w+\s+\w+\s+(.*)\n/i)
			{
				my $name = $1;
				push(@names,$name);
			}
		}

		close($fl);
		
		return  @names;
	}
	else
	{
		&SendMsg("normal","invoke ifconfig commad fail");
		return @names ;
	}
}

sub  getLast
{
	my ($curr,$filepath) = @_;
	my $fl = gensym();
	my @last_names = ();

	if(! -e "$filepath")
	{
		if(open($fl,">${filepath}"))
		{
			foreach  (@$curr) 
			{
				print $fl $_."\n";
			}

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
			foreach  (@$curr) 
			{
				print $fl $_."\n";
			}

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
				push(@last_names,$line);
			}
			close($fl);
		}
		else
		{
			&SendMsg("normal","open ${filepath} fail beacause $!");
		}
	}
	
	return  @last_names;

}


sub  compare
{
	my ($Last,$Curr) = @_;
	
	if(scalar(@$Last) !=  scalar(@$Curr))
	{
		return 0;
	}
	
	my $flag = 0;
	
	foreach my $curr_item (@$Curr)
	{
		foreach my $last_item (@$Last)
		{
			if($curr_item  eq $last_item)
			{
				$flag = 1;
				last;
			}
			else
			{
				next;
			}
		}
		
		if($flag == 0)
		{
			return 0;
		}
	}
	
	return $flag;
	
}

sub  saveCurr
{
	my ($file,$curr) = @_;
	my $fl =  gensym();
	if(open($fl,">${file}"))
	{
		foreach (@$curr)
		{
			print $fl $_."\n";
		}
		
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

our $bhm_os_hpux_config_dir = "/var/opt/OV/bhm/conf";
unless(-d "$bhm_os_hpux_config_dir")
{
	if(system("/usr/bin/mkdir  -p ${bhm_os_hpux_config_dir}"))
	{
		&SendMsg("normal","mkdir ${bhm_os_hpux_config_dir} fail because $!");
		exit 1;
	}
}

our $bhm_os_hpux_config_file = ${bhm_os_hpux_config_dir}."/"."bhm_OsConfig_nicsum.txt";





my @Curr  = &getCurr();

my @Last = &getLast(\@Curr,${bhm_os_hpux_config_file});

my $flag = &compare(\@Curr,\@Last);

unless($flag)
{
		my ($last_text,$curr_text) = ("","");
		foreach (@Last)
		{
			$last_text =  $_." ".$last_text;
		}
		
		foreach (@Curr)
		{
			$curr_text =  $_." ".$curr_text;
		}
		
		&SendMsg("warning","network interface card  had been changed last:${last_text}; \ncurrent:${curr_text}");
		
		&saveCurr($bhm_os_hpux_config_file,\@Curr);
}
### end of main ###