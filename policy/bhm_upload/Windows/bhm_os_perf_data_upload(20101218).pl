#!/usr/bin/perl -w
#author: yangshengcheng@gzcss.net
#date: 2010/12/13
#usage: invoked by ovo scheduled task  policy (bhm_os_perf_data_upload)
#parameter: no
#description: upload  all performent data to data server
#Categories : bhm  policy
#update : change the os cpu usage data source ,get it from os counter


use Net::FTP;
use Symbol;
use POSIX qw(strftime);


sub usage{
        print "$0"." "."IP"." "."user"." "."passwd"." "."port"." "."mode\n";
        exit 1;
}

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

#upload file 
sub  get_local_ip
{
	my $localip;
	my $line;
	my $nodeinfo = "${bhm_node_info_dir}nodeinfo";
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
	if($osname=~/win/i)
	{
		unless(open(HOSTS,"C:\\WINDOWS\\system32\\drivers\\etc\\hosts"))
		{
			&log_ftp_err("open hosts file fail");
			&opcMsg("critical","\'hosts file is not exist\'");
			exit 1;
		}
		
	}
	else
	{
			unless(open(HOSTS,"/etc/hosts"))
			{
				&log_ftp_err("open hosts file fail");
				&opcMsg("critical","\'hosts file is not exist\'");
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
sub FTPFile{
        my ($ip,$user,$passwd,$port,$mode)=@_;
 #       my $filedir=strftime("%Y%m%d", localtime());
 				my $message;
        unless($ftp = Net::FTP->new($ip,Port=>$port ,Timeout=>60,Debug => 0,Passive =>$mode) )
        {
        	$message=$ftp->message;
        	&opcMsg("critical","\'Can not connect to  esb server ${ip} ,$message \'");
        	&log_ftp_err("Can not connect to  esb server ${ip} ,$message");
        	exit 0;
        }
        unless($ftp->login($user,$passwd))
        {
        	$message=$ftp->message;
        	&opcMsg("critical","\'login fail,$message \'");
        	&log_ftp_err("login fail,$message");
        	exit 0;
        }
#        unless($ftp->cwd("/${filedir}"))
#        {
#                $ftp->mkdir("/${filedir}") or die "mkidr data dir fail",$ftp->message;
#        }
        $ftp->ascii();
        unless($ftp->cwd(""))
        {
        	$message=$ftp->message;
        	&opcMsg("critical","\'Cannot change working directory,$message \'");
        	&log_ftp_err("Cannot change working directory,$message");
        	exit 0;        	
        }

        unless($ftp->put("${agent_data_dir}$filename"))
        {
         	$message=$ftp->message;
        	&opcMsg("critical","\'upload data fail,$message \'");
        	&log_ftp_err("upload data fail,$message");
        	exit 0;        	
        }
        $ftp->quit;
}

# generate the the filename
sub  gencsvname
{
	my ($val) = @_;
	my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)= localtime();
	my $index = sprintf("%d",($hour * 60 + $min ) / $val);


	my $timestamp = strftime("%Y%m%d%H%M%S", localtime);
	
	my $name = $hostip."_".$timestamp."_".$index.".csv";
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

#parser coda metric without config file
sub parserCoda
{
	my %temp_hash=();
	my @temp=();
	
	#collect the agent golden coda data
	
	
	if($osname=~/win/i)
	{
		unless(open(CODA,"ovcodautil -dumpds coda|"))
		{
        &opcMsg("critical","\'execute  ovcodautil  fail \'");
        &log_ftp_err("execute  ovcodautil  fail");	
        exit 1;		
		}
	}
	else
	{
		unless(open(CODA,"${ov_install_bin_dir}/ovcodautil -dumpds coda|"))
		{
        &opcMsg("critical","\'execute  ovcodautil  fail \'");
        &log_ftp_err("execute  ovcodautil  fail");	
        exit 1;					
		}
	}
	
	
		while(my $line=<CODA>)
		{
			
			if($line=~/^(\d+)\/(\d+)\/\d+\s+(\d+):(\d+):(\d+)(.*?)\|(\w+)\s*\|(.+?)\|/)
			{
					
					my $mon = $1;my $day=$2;my $hour=$3;my $min = $4;my $sec=$5;my $AMPM= $6;my $metric=$7;my $value=$8;
					next if($metric=~/GBL_CPU/i);
					if($AMPM && $AMPM =~/PM/i)
					{
						$hour = $hour +  12;
					}
					
					if($metric=~/GBL_/i)
					{
						$temp_hash{$metric}->{'timestamp'}=$year.$mon.$day.$hour.$min.$sec;
						$temp_hash{$metric}->{'class'}='GLOBAL';
						$temp_hash{$metric}->{'instance_name'}='NULL';
						$temp_hash{$metric}->{'value'}=$value;
					}
					
						if($metric=~/BYCPU_/i)
						{
							if($metric eq "BYCPU_ID")
							{
								$instance_name = $value;
								next;
							}
							else
							{
								my $entry =$year.$mon.$day.$hour.$min.$sec.'|'.'CPU'.'|'.$metric.'|'.$instance_name.'|'.$value.'|'.$osname ;
								push(@temp,$entry);
							}
						}
						
						if($metric=~/BYNETIF_/i)
						{
							if($metric eq "BYNETIF_NAME")
							{
								$netif_instance_name = $value;
								next;
							}
							if($netif_instance_name)
							{
								my $entry =$year.$mon.$day.$hour.$min.$sec.'|'.'NETIF'.'|'.$metric.'|'.$netif_instance_name.'|'.$value.'|'.$osname ;
								push(@temp,$entry);
							}
						}
						
						if($metric=~/FS_/i)
						{
							if($osname=~/win/i)
							{
								if($metric eq "FS_DIRNAME")
								{
									$fs_instance_name = $value;
									next;
								}
							}
							else
							{
								if($metric eq "FS_DEVNAME")
								{
									$fs_instance_name = $value;
									next;
								}
							}
							
							if($fs_instance_name)
							{
								my $entry =$year.$mon.$day.$hour.$min.$sec.'|'.'FILESYSTEM'.'|'.$metric.'|'.$fs_instance_name.'|'.$value.'|'.$osname ;
								push(@temp,$entry);
							}
						}
						
						if($metric=~/BYDSK_/i)
						{
							if($metric eq "BYDSK_DEVNAME")
							{
								$disk_instance_name = $value;
								next;
							}
							elsif($disk_instance_name)
							{
								my $entry =$year.$mon.$day.$hour.$min.$sec.'|'.'DISK'.'|'.$metric.'|'.$disk_instance_name.'|'.$value.'|'.$osname ;
								push(@temp,$entry);
							}
							
						}
								
			}

		}
			
			close(CODA);
			
			###flush the buff to data file
			&flush(\%temp_hash,\@temp);
		
}

#parser coda metric with config file
sub parserCoda2
{
	
	my ($hash_ref)=@_;
	my %temp_hash=();
	my @temp=();
	
		#collect the agent golden coda data
	
	
	if($osname=~/win/i)
	{
		unless(open(CODA,"ovcodautil -dumpds coda|"))
		{
				&opcMsg("critical","\'execute ovcodautil  fail\'");
        &log_ftp_err("execute ovcodautil fail");
        exit 1; 			
		}
	}
	else
	{
		unless(open(CODA,"${ov_install_bin_dir}/ovcodautil -dumpds coda|"))
		{
				&opcMsg("critical","\'execute ovcodautil  fail\'");
        &log_ftp_err("execute ovcodautil fail");
        exit 1; 			
		}
	}
	
	
		while(my $line=<CODA>)
		{
			
			if($line=~/^(\d+)\/(\d+)\/\d+\s+(\d+):(\d+):(\d+)(.*?)\|(\w+)\s*\|(.+?)\|/)
			{
					
					my $mon = $1;my $day=$2;my $hour=$3;my $min = $4;my $sec=$5;my $AMPM= $6;my $metric=$7;my $value=$8;
					if($AMPM && $AMPM =~/PM/i)
					{
						$hour = $hour +  12;
					}
					
					if($metric=~/GBL_/i)
					{
						next unless(exists($hash_ref->{$metric}));
						
						$temp_hash{$metric}->{'timestamp'}=$year.$mon.$day.$hour.$min.$sec;
						$temp_hash{$metric}->{'class'}='GLOBAL';
						$temp_hash{$metric}->{'instance_name'}='NULL';
						$temp_hash{$metric}->{'value'}=$value;
					}
					
						if($metric=~/BYCPU_/i)
						{
							if($metric eq "BYCPU_ID")
							{
								$instance_name = $value;
								next;
							}
							else
							{
								next unless(exists($hash_ref->{$metric}));
								my $entry =$year.$mon.$day.$hour.$min.$sec.'|'.'CPU'.'|'.$metric.'|'.$instance_name.'|'.$value.'|'.$osname ;
								push(@temp,$entry);
							}
						}
						if($metric=~/BYNETIF_/i)
						{
							if($metric eq "BYNETIF_NAME")
							{
								$netif_instance_name = $value;
								next;
							}
							if($netif_instance_name)
							{
								next unless(exists($hash_ref->{$metric}));
								my $entry =$year.$mon.$day.$hour.$min.$sec.'|'.'NETIF'.'|'.$metric.'|'.$netif_instance_name.'|'.$value.'|'.$osname ;
								push(@temp,$entry);
							}
						}
						
						if($metric=~/FS_/i)
						{
							if($osname=~/win/i)
							{
								if($metric eq "FS_DIRNAME")
								{
									$fs_instance_name = $value;
									next;
								}
							}
							else
							{
								if($metric eq "FS_DEVNAME")
								{
									$fs_instance_name = $value;
									next;
								}
							}
							
							if($fs_instance_name)
							{
								next unless(exists($hash_ref->{$metric}));
								my $entry =$year.$mon.$day.$hour.$min.$sec.'|'.'FILESYSTEM'.'|'.$metric.'|'.$fs_instance_name.'|'.$value.'|'.$osname ;
								push(@temp,$entry);
							}
						}
						
						if($metric=~/BYDSK_/i)
						{
							if($metric eq "BYDSK_DEVNAME")
							{
								$disk_instance_name = $value;
								next;
							}
							elsif($disk_instance_name)
							{
								next unless(exists($hash_ref->{$metric}));
								my $entry =$year.$mon.$day.$hour.$min.$sec.'|'.'DISK'.'|'.$metric.'|'.$disk_instance_name.'|'.$value.'|'.$osname ;
								push(@temp,$entry);
							}
							
						}
								
			}

		}
			
			close(CODA);
			
			#caculate 
			&caculate(\%temp_hash);
			
			###flush the buff to data file
			&flush(\%temp_hash,\@temp);
		
}
# parser BHM_OS_PERF source 
sub parserBHM_OS_PERF
{
	my @temp=();
	my %temp_hash=();
	
	#collect the agent custom sources data
	
	
	if($osname=~/win/i)
	{
		unless(open(BHM_OS_PERF,"ovcodautil -dumpds BHM_OS_PERF|"))
		{
        &opcMsg("critical","\'execute  ovcodautil  fail \'");
        &log_ftp_err("execute  ovcodautil  fail");	
        return 0;		
		}
	}
	else
	{
		unless(open(BHM_OS_PERF,"${ov_install_bin_dir}/ovcodautil -dumpds BHM_OS_PERF|"))
		{
        &opcMsg("critical","\'execute  ovcodautil  fail \'");
        &log_ftp_err("execute  ovcodautil  fail");	
        return 0;					
		}
	}
	
	
		while(my $line=<BHM_OS_PERF>)
		{
			
			if($line=~/^(\d+)\/(\d+)\/\d+\s+(\d+):(\d+):(\d+)(.*?)\|(\w+)\s*\|(.+?)\|/)
			{
					
					my $mon = $1;my $day=$2;my $hour=$3;my $min = $4;my $sec=$5;my $AMPM= $6;my $metric=$7;my $value=$8;
					if($AMPM && $AMPM =~/PM/i)
					{
						$hour = $hour +  12;
					}
					
					unless( $metric=~/InstanceName/i)
					{
						$temp_hash{$metric}->{'timestamp'}=$year.$mon.$day.$hour.$min.$sec;
						$temp_hash{$metric}->{'class'}='BHM_OS_PERF';
						$temp_hash{$metric}->{'instance_name'}='NULL';
						$temp_hash{$metric}->{'value'}=$value;
					}
			}
		}

		close(BHM_OS_PERF);

		#caculate 
		&caculate(\%temp_hash);


			###flush the buff to data file
			&flush(\%temp_hash,\@temp);
	return  1;

}


#some unix os isn't exists avalaible dbm,use ascii text to simalute the dbm method
sub  sim_dbmopen
{
	my ($hash_ref,$file) = @_;
	my $fl = gensym();
	unless(-e "$file")
	{
		if(open($fl,">$file"))
		{
			close($fl);
			return  1;
		}
		else
		{
			return 0;
		}
	}
	unless(open($fl,"$file"))
	{
		return 0;
	}
	while(my $line = <$fl>)
	{
		if($line=~/(\S+)\s+(\S+)/)
		{
			my $key=$1;$value = $2;
			$hash_ref->{$key} = $value;
		}
	}
	close($fl);
	return 1;
	
}

sub  sim_dbmclose
{
	my ($hash_ref,$file,$index)=@_;
	return 0 unless(exists($hash_ref->{$index}));
	
	my $fl = gensym();
	
	unless(open($fl,">$file"))
	{
		&log_ftp_err("open $file fail");
		return 0;
	}
	
	foreach (keys %{$hash_ref})
	{
		print $fl $_." ".$hash_ref->{$_}."\n";
	}
	
	close($fl);
	undef $hash_ref;
	return 1;
}

#get the latest file 
sub  getLatest
{
	my ($keyWord)=@_;
	
	my $dir = gensym();
	unless(opendir($dir,"$agent_data_dir"))
	{
		&log_ftp_err("open data dir fail");
		return  0;
	}
	
	my @files = grep(/$keyWord/,readdir($dir));
	closedir($dir);
	
	my $num = scalar(@files);
	if($num == 0)
	{
		return  0;
	}
	if($num == 1)
	{
		return  $files[0];
	}
	
	
	my $latest_file;
	my $timestamp = 0;
	my $i = 0;
	my $top = $num - 1;
	foreach $i(0..$top)
	{
		my @temp = stat("${agent_data_dir}$files[$i]");
#		print $files[$i] ."->".$temp[9]."\n";
		if($temp[9] > $timestamp)
		{
			$latest_file = $files[$i];
			$timestamp = $temp[9];
		}
	}
	
	return  $latest_file;
	
}

# get the next  file
sub getNext
{
	my ($last_file,$interval)=@_;
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
	my $current =sprintf("%d",($hour * 60 + $min ) / $interval);
	my $max = (24 * 60) /$interval - 1;
	
	my $next_file;
	if($last_file=~/(\w+_)(\d+)(\.csv)/)
	{
		my $prefix = $1;my $i = $2;my $apped = $3;
		if($i > $max)
		{
			&log_ftp_err("the file index large then the max index $last_file");
			return 0;
		}
		if($i eq $max )
		{
			$next_file = $prefix."0".$apped;
		}
		else
		{
			$i += 1;
			# if miss a file the index will  not increase ,so use the current index to fix this situation	 
			if(abs($current - $i) > 2)
			{
				$next_file = $prefix.$current.$apped;
			}
			else
			{
				$next_file = $prefix.$i.$apped;
			}
		}
		
		return $next_file;
	}
	else
	{
		return 0;
	}
}


## merge   weblogic metrics  data  to upload  csv  file
sub merge_func
{
	my ($prefix)=@_;
	my %hash = ();
	my @temp=();
	my $indexName=$prefix."index";

	unless(&sim_dbmopen(\%hash,"$bhm_DataUpLoad",0666))
	{
		&log_ftp_err("open dbm file fail");
		return 0;
	}
	
	my $csv_file= &getLatest($prefix);
	unless ($csv_file)
	{
		$hash=();
		return 0 ;
	}
	
	if(exists $hash{"$indexName"})
 {
		if($csv_file eq $hash{"$indexName"})
		{
			$hash=();
			return 0 ;
		}
		
#			print "file exists  begin to merge\n";	
			my $fl = gensym();
			if(open($fl,"${agent_data_dir}$csv_file"))
			{
					@temp = <$fl>;
#					print $temp[0]."\n";
					close($fl);

					# write data to the upload file
					&flush2(\@temp);

					#fresh the dbm index
					$hash{"$indexName"} = $csv_file;
					
					&sim_dbmclose(\%hash,"$bhm_DataUpLoad","$indexName");
					return 1;
			}
			else
			{
					&log_ftp_err("open weblogic metrics data file fail");
					&sim_dbmclose(\%hash,"$bhm_DataUpLoad","$indexName");
					return 0;
			}
	}
	else
	{
			my $fl = gensym();
			if(open($fl,"${agent_data_dir}$csv_file"))
			{
					@temp = <$fl>;
#					print $temp[0]."\n";
					close($fl);

					# write data to the upload file
					&flush2(\@temp);

					#fresh the dbm index
					$hash{"$indexName"} = $csv_file;
					
					&sim_dbmclose(\%hash,"$bhm_DataUpLoad","$indexName");
					return 1;
			}
			else
			{
					&log_ftp_err("open weblogic metrics data file fail");
					&sim_dbmclose(\%hash,"$bhm_DataUpLoad","weblogic_index");
					return 0;
			}
		
	}
}


#flush  data to  the data file
sub  flush
{
			my ($hasl_ref,$array_ref)=@_;
			my $fl = gensym();
			unless(open($fl,">>${agent_data_dir}$filename")) 
			{
				 &opcMsg("critical","\'create ${filename} fail\'");
        		&log_ftp_err("create ${filename} fail");
        		exit 1;  
			}
			
			foreach my $key (keys %{$hasl_ref})
			{
				print $fl $hasl_ref->{$key}->{'timestamp'}.'|'.$hasl_ref->{$key}->{'class'}.'|'.$key.'|'.$hasl_ref->{$key}->{'instance_name'}.'|'.$hasl_ref->{$key}->{'value'}.'|'.$osname."\n";
			}
			
			foreach my $entry(@{$array_ref})
			{
				print $fl $entry."\n";
			}
			close($fl);
}

# just  flush  a array 
sub flush2
{
			my ($array_ref)=@_;
			my $fl = gensym();
			unless(open($fl,">>${agent_data_dir}$filename")) 
			{
					&opcMsg("critical","\'create ${filename} fail\'");
        			&log_ftp_err("create ${filename} fail");
        			exit 1;  
			}

			foreach my $entry(@{$array_ref})
			{
				print $fl $entry;
			}
			close($fl);
}

#caculate the metric
sub  caculate
{
	my ($hash_ref)= @_;
	if($osname=~/win/i)
	{
		#cal  the GBL_CPU_TOTAL_UTIL metric
		unless(exists $hash_ref->{'GBL_CPU_IDLE_UTIL'}->{'value'})
		{
			&opcMsg("warning","\'GBL_CPU_IDLE_UTIL performent counter is not exists\'");
			&log_ftp_err("GBL_CPU_IDLE_UTIL performent counter is not exists");
			return 0;
		}
		$hash_ref->{'GBL_CPU_TOTAL_UTIL'}->{'value'} = 100 - $hash_ref->{'GBL_CPU_IDLE_UTIL'}->{'value'};
		$hash_ref->{'GBL_CPU_TOTAL_UTIL'}->{'timestamp'}= $hash_ref->{'GBL_CPU_IDLE_UTIL'}->{'timestamp'};
		$hash_ref->{'GBL_CPU_TOTAL_UTIL'}->{'class'}='GLOBAL';
		$hash_ref->{'GBL_CPU_TOTAL_UTIL'}->{'instance_name'}='NULL';
		return 1;
	}
	else
	{
		my $line;
		my @temp_name;
		my @temp_value;
		my %hash_temp;

		unless(open(CPU,"/usr/bin/vmstat|"))
		{
				&opcMsg("warning","\'excute vmstat fail $!\'");
        		&log_ftp_err("excute vmstat fail $!");
				return  0;
		}
		
		while($line=<CPU>)
		{
			if($line=~/us\s+sy\s+id/)
			{
				@temp_name = split(/\s+/,$line);
			}

			if(@temp_name)
			{
				if($line=~/\d+\s+\d+\s+\d+/)
				{
					@temp_value = split(/\s+/,$line);
				}
			}

		}

		close(CPU);

		my $count = scalar(@temp_name);
		my $count2=scalar(@temp_value);

		if($count != $count2)
		{
			&opcMsg("warning","\'bad format vmstat result\'");
        	&log_ftp_err("bad format vmstat result");
			return  0;
		}


		my $i = 0;

		for(;$i < $count;$i++)
		{
			$hash_temp{$temp_name[$i]}->{'index'}= $i;
		}

		#caculate 
		$hash_ref->{'GBL_CPU_TOTAL_UTIL'}->{'value'} = 100 - $temp_value[$hash_temp{'id'}->{'index'}];
		$hash_ref->{'GBL_CPU_TOTAL_UTIL'}->{'timestamp'}= strftime("%Y%m%d%H%M%S", localtime);
		$hash_ref->{'GBL_CPU_TOTAL_UTIL'}->{'class'}='GLOBAL';
		$hash_ref->{'GBL_CPU_TOTAL_UTIL'}->{'instance_name'}='NULL';



		return 1;

	}

}


# load the config to  a hash
sub  loadConfig
{
	if(-e "metrics.conf")
	{
		if(open(CONF,"metrics.conf"))
		{
			while(my $line =<CONF>)
			{
				next  if($line=~/^\s*$|^#/);
				if($line=~/(\w+)/)
				{
					$conf{$1}=1;
				}
			}
			close(CONF);
		}
		else
		{
			&log_ftp_err("can not open  the  metrics.conf file");
		}
	}
	else
	{
		# &log_ftp_err("metrics.conf file is not exist");
	}
}

##ovo  tool  invoke
#sent message to  ovo console
sub  opcMsg
{
	my ($severity,$msg_text)=@_;
	my $app='bhm_perf_data_upload';
	my $obj="perf";
	my $msg_grp="perf_data_upload";
	#my $OV_BIN_DIR="/opt/OV/bin/";

	if($osname=~/win/i)
	{
		system("opcmsg  severity=${severity} application=${app} object=${obj} msg_grp=${msg_grp} msg_text=$msg_text");
	}
	else
	{
		system("${ov_install_bin_dir}opcmsg  severity=${severity} application=${app} object=${obj} msg_grp=${msg_grp} msg_text=$msg_text");
	}

}


### log the waring and error
sub  log_ftp_err
{
	my ($text)=@_;
	my $timestamp = strftime("%Y%m%d%H%M%S", localtime);
	open(ERR,">>$bhm_ftp_err_log");
	print ERR $timestamp."\t".$text."\n";
	close(ERR);
	
}

# del the  file older then 1 day
sub  delFile
{
	my($fileDir)=@_;
	my @files=();
	my $Dir = gensym();
	if(opendir($Dir,$fileDir))
	{
		@files=grep(/csv$/,readdir($Dir));
		closedir($Dir);
		foreach my $file (@files) 
		{
			my @array =stat("${fileDir}$file"); 
			if((time() - $array[9]) > 7200)
			{
				unless(unlink "${fileDir}$file")
				{
					print "del file fail\n";
					&opcMsg("critical","\'delete the old data file fail\'");
					&log_ftp_err("delete the old data file fail");
					exit 1;
				}
			}
		}
	}
	else
	{
		print "open data file Dir fail\n";
		&opcMsg("critical","\'open data file Dir fail\'");
		&log_ftp_err("open data file Dir fail");
		exit 1;
	}
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
		$bhm_node_info_dir = "$ENV{OvDataDir}\\bhm\\conf\\";
	}
	elsif($osname=~/tru/i)
	{
		$metric_config_file="/usr/var/opt/OV/bin/instrumentation/";
		$agent_data_dir="/usr/var/opt/OV/bhm/dsi/";
		$bhm_ftp_err_log = "/usr/var/opt/OV/bhm/bhm_ftp_err.txt";
		$bhm_ftp_temp_dir = "/usr/var/opt/OV/bhm/temp/";
		$ov_install_bin_dir="/usr/opt/OV/bin/";	
		$bhm_node_info_dir="/usr/var/opt/OV/bhm/conf/";
	}
	else
	{
		$metric_config_file="/var/opt/OV/bin/instrumentation/";
		$agent_data_dir="/var/opt/OV/bhm/dsi/";
		$bhm_ftp_err_log = "/var/opt/OV/bhm/bhm_ftp_err.txt";
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


## check  the  data source 
sub  getSource
{
	my ($hash_ref)=@_;
	my $fl = gensym();
	
	if($osname=~/win/i)
	{
		unless(open($fl,"ovcodautil -obj|"))
		{
			&opcMsg("warning","\'execute the  ovcodautil -obj fail\'");
			&log_ftp_err("execute the  ovcodautil -obj fail");
			exit 1;
		} 
		
	}
	else
	{
		unless(open($fl,"${ov_install_bin_dir}/ovcodautil -obj|"))
		{
			&opcMsg("warning","\'execute the  ovcodautil -obj fail\'");
			&log_ftp_err("execute the  ovcodautil -obj fail");
			exit 1;			
		}
	}
	
	while(my $line=<$fl>)
	{
		if($line=~/Data source:\s*(\w+)/)
		{
			$hash_ref->{$1} = 1;
		}
	}
	close($fl);
	
}


### main ###

#check argument
usage if(!defined(@ARGV) || (scalar(@ARGV) < 3));
my $ip=shift @ARGV;
my $user=shift @ARGV;
my $passwd=shift @ARGV;
my $esbPort = shift @ARGV || "9000";
my $ftpMode= shift @ARGV || 0;
my $interval = shift  @ARGV || "5";



#check  env 
our $osname = &checkOs();
our $ov_install_bin_dir;
our $agent_data_dir;
our $metric_config_file;
our $bhm_ftp_temp_dir;
our $bhm_ftp_err_log;
our $bhm_node_info_dir;


&check_env();
&genDir($bhm_node_info_dir);
&genDir($agent_data_dir);
&genDir($bhm_ftp_temp_dir);


##global  val
our $year = strftime("%Y",localtime);
our $hostip = &get_local_ip();
our $filename = &gencsvname($interval);
our $bhm_DataUpLoad = "${metric_config_file}bhm_DataUpLoad";
#our %dataSource;

# before do any thing ,del the  file which  older then one day,and truncate the log large than  1 MB
&delFile($agent_data_dir);
exit 1 unless(&trunErrLog($bhm_ftp_err_log));

#load metric conf file
our %conf=();
&loadConfig();

# detect agent available data source
#&getSource(\%dataSource);
#unless(%dataSource)
#{
#	print "no data source avalible\n";
#	&opcMsg("warning","\'execute the  ovcodautil -obj fail\'");
#	&log_ftp_err("execute the  ovcodautil -obj fail");
#	exit 1;	
#}

#load agent data source
##load  coda source metrics
#unless(exists($dataSource{'CODA'}))
#{
#	&opcMsg("critical","\'the coda daemon was died\'");
#	&log_ftp_err("the coda daemon was died");
#	exit 1;
#	
#}

$ENV{'LC_ALL'}=C unless($osname=~/win/i);

if(%conf)
{
	&parserCoda2(\%conf);
}
else
{
	&parserCoda();
}

## get BHM_OS_PERF source metrics
&parserBHM_OS_PERF();

##get aix vg info
if($osname=~/aix/i)
{
	&merge_func("vg_");
}
#load oracle source metrics

#print "oracle parser\n";
&merge_func("ora_");


#load weblogic  source  metrics 

#	print "weblogic parser\n";
&merge_func("weblogic_");

#upload the data file
if(-e "${agent_data_dir}$filename")
{
	&FTPFile($ip,$user,$passwd,$esbPort,$ftpMode);
}

### end of main ###

