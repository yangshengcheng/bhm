#!/opt/OV/nonOV/perl/a/bin/perl -w

#########################################################

#author: yangshengcheng@gzcss.net

#date: 2010-6-23 

#usage: osspi_perl.sh  bhm_os_hpux_config_macaddr.pl 

#parameter: none

#description: check  os 's nic mac address config 

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
	my $app='bhm_os_hpux_config_macaddr.pl';
	my $obj="macaddress";
	my $msg_grp="BHM:HPUX:CONFIG";
	$msg_text = "'".$msg_text."'";

	system("opcmsg  severity=${severity} application=${app} object=${obj} msg_grp=${msg_grp} msg_text=$msg_text");
}

sub  getCurr
{
	
	my $fl = gensym();
	my $line;
	my @names=();
	if(open($fl,"/usr/sbin/lanscan|"))
	{
		while($line = <$fl>)
		{
			if($line=~/\S+\s+0x(\w+)\s+\d+\s+(up|down)\s+(\S+)\s+\S+\s+\d+\s+\w+\s+(yes|no)\s+\d+\s*/i)
			{
				my $name = $3."->".$1;
				push(@names,$name);
			}
		}

		close($fl);
		return  @names;
	}
	else
	{
		&SendMsg("normal","invoke lanscan commad fail because $!");
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

our $bhm_os_hpux_config_file = ${bhm_os_hpux_config_dir}."/"."bhm_OsConfig_macaddr.txt";





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
		
		&SendMsg("warning","mac address had been changed last:${last_text}; \ncurrent:${curr_text}");
		
		&saveCurr($bhm_os_hpux_config_file,\@Curr);
}
### end of main ###