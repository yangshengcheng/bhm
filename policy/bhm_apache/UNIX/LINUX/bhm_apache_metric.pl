#!/opt/OV/nonOV/perl/a/bin/perl -w
#------------------------------------------------------------------------------
#File Name:	bhm_apache_metric.pl
#Author:	yangshengcheng@gzcss.net
#description:	get apache performance data from status url,parser,store to a data file or coda datasource
#usage:	perl bhm_apache_metric.pl 	
#Language:	Perl
#metrics:
#Total accesses
#Total Traffic
#total processes
#requests/sec 
#Traffic per second
#bytes per request
#idle process
#------------------------------------------------------------------------------

use lib qw(/var/opt/OV/wsspi/Perl-Modules);
require LWP::UserAgent;
require HTTP::Request;

use POSIX qw(strftime);
 

#MAIN starts here...

my $Args=$#ARGV + 1;

if ($Args != 2)
{
    print "USAGE: wsspi_coda_datalog_apache.pl IPAddress Port\n";
    exit (0);
}

my $IPAddress=shift;
my $port=shift; 

$urlString="http://$IPAddress:$port/server-status";

my $WSSPI_TRC_LVL = 0; # Tracing is off by default
my $wsspi_dir="/var/opt/OV/wsspi";
unless(&checkDir($wsspi_dir))
{
	die("dir is not exists\n");
}

my $log_dir="${wsspi_dir}/log";
my $error_file="${log_dir}/wsspi_error.log";
my $html_file="${wsspi_dir}/server-status-CODA.html";
my $TotalAccesses="${wsspi_dir}/TotalAccessesCODA";
my $TotalTraffic="${wsspi_dir}/TotalTrafficCODA";
my $TotalAccessesTraffic="${wsspi_dir}/TotalAccessesTrafficCODA";
my $CPULoad="${wsspi_dir}/CPULoadCODA";

my $bhmDataDir = "/var/opt/OV/bhm/dsi";
my $bhmTempDir = "/var/opt/OV/bhm/tmp";


#Send a get request to the above URL.
$ua = LWP::UserAgent->new;
$response = $ua->get($urlString);

if (! $response->is_success)
{
    &write_to_log ("Failed to connect to the URL $urlString \n");
    exit(0);
}

open (F, "> $html_file") || die "Can't open $html_file : $!\n" ;
print F $response->content;
close (F);

my @output = parseFile($html_file); #added by Brewin for 05.10 release.

foreach $line (@output)
{

#            (Current "Total Accesses" - previously logged "Total Accesses") 
#Request/Sec= ___________________________________________________________
#
#          (Current time - the time at which "Total Traffic" logged previously)
# 

    if ($line =~ /Total accesses:/)
    {
	my $value = ( split(/ /,$line) )[2];
	$totalAccesses_current = $value;
	chomp($value);
	if ( -f "$TotalAccesses") 
	{
	    open (TA, "$TotalAccesses") || die "Can't open $TotalAccess: $!\n";
	    $totalAccesses=<TA>;
	    chomp ($totalAccesses);
	    $loggedTime=<TA>;
	    chomp ($loggedTime);
	    close (TA);
	    
	}
	else
	{
	    $totalAccesses=0;
	    $loggedTime=0;
	}
	open (TA, "> $TotalAccesses") || die "Can't open $TotalAccess: $!\n";
	print TA "$value\n";
	$currentTime = time();
	print TA "$currentTime\n";
	$ReqPerSec = ($value - $totalAccesses) / ($currentTime - $loggedTime);
	close (TA);
    }
    
#          (Current "Total Traffic" - previously logged "Total Traffic" )
#Bytes/Sec= _____________________________________________________________
#
#          (Current time - the time at which "Total Traffic" logged previously)

    if ($line =~ /Total Traffic:/)
    {
	my $value = ( split(/ /,$line) )[6];
	chomp($value);
	my $size =  ( split(/ /,$line) )[7];
	chomp ($size);

# Checked with mod_status.c file. It prints the Total Traffic only in one of 
# the following three sizes: kB, MB, GB.
#

	if ($size eq "kB")
	{
	    $value = $value * 1024;
	}
	if ($size eq "MB")
	{
	    $value = $value * 1024 * 1024;
	}
	if ($size eq "GB")
	{
	    $value = $value * 1024 * 1024 * 1024;
	}

	$totalTraffic_current = $value;
	
	if ( -f "$TotalTraffic") 
	{
	    open (TT, "$TotalTraffic") || die "Can't open $TotalTraffic: $!\n";
	    $totalTraffic=<TT>;
	    chomp ($totalTraffic);
	    $loggedTime=<TT>;
	    chomp ($loggedTime);
	    close (TT);
	    
	}
	else
	{
	    $totalTraffic=0;
	    $loggedTime=0;
	}
	open (TT, "> $TotalTraffic") || die "Can't open $TotalTraffic: $!\n";
	print TT "$value\n";
	$currentTime = time();
	print TT "$currentTime\n";
	$bytesPerSec = ($value - $totalTraffic) / ($currentTime - $loggedTime);
	close (TT);

#                 Bytes/Sec as calculated above
# Bytes/Request=  ____________________________  
# 
#                 Request/Sec as calculated above  
    
	$BytesPerReq = $bytesPerSec / $ReqPerSec;
    }

# BusyProcessesRate = (busy) / (busy + idle) * 100

    if ($line =~ /idle workers/)
    {
		$busyValue = ( split(/ /,$line) )[0];
		chomp($busyValue);
		$idleValue = ( split(/ /,$line) )[5];
		chomp($idleValue);
	
	#$BusyProcessesRate = ($busyValue)/($busyValue + $idleValue) * 100;

    }


	#bhm metric is not include the cpu usage
    
#          (Current "CPU Usage" - previously logged "CPU Usage") 
#CPU Load= __________________________________________________     X 100
#
#         (Current time - the time at which "CPU Usage" logged previously)

#    if ($line =~ /CPU Usage/)
#    {
#	my $u = ( split(/ /,$line) )[2];
#	chomp($u);
#	$u =~ s/u//;
#	
#	my $s = ( split(/ /,$line) )[3];
#	chomp($s);
#	$s =~ s/s//;
#	
#	my $cu = ( split(/ /,$line) )[4];
#	chomp($cu);
#	$cu =~ s/cu//;
#	
#	my $cs = ( split(/ /,$line) )[5];
#	chomp($cs);
#	$cs =~ s/cs//;
#	
#	$cpuUsage = $u + $s + $cu + $cs;
#	
#	if ( -f "$CPULoad") 
#	{
#	    open (CL, "$CPULoad") || die "Can't open $CPULoad: $!\n";
#	    $cpuload=<CL>;
#	    chomp ($cpuload);
#	    $loggedTime=<CL>;
#	    chomp ($loggedTime);
#	    close (CL);
#	    
#	}
#	else
#	{
#	    $cpuload=0;
#	    $loggedTime=0;
#	}
#	open (CL, "> $CPULoad") || die "Can't open $CPULoad: $!\n";
#	print CL "$cpuUsage\n";
#	$currentTime = time();
#	print CL "$currentTime\n";
#	$percentageLoad = ($cpuUsage - $cpuload) / ($currentTime - $loggedTime) * 100;
#	close (CL);
#    } 
#
}

#log the data into CODA/OVPA
#truncate values before inserting them
#$percentageLoad = &truncate_value($percentageLoad);
#$memoryUsage = &truncate_value($memoryUsage);
$totalAccesses_current = "APACHE_GLOBAL|"."TOTAL_ACCESS|"."${port}|".&truncate_value($totalAccesses_current)."|".&GetOsType();
$totalTraffic_current = "APACHE_GLOBAL|"."TOTAL_TRAFFIC|"."${port}|".&truncate_value($totalTraffic_current)."|".&GetOsType();
$bytesPerSec = "APACHE_GLOBAL|"."BYTES_PERSEC|"."${port}|".&truncate_value($bytesPerSec)."|".&GetOsType();
$ReqPerSec = "APACHE_GLOBAL|"."REQUESTS_PERSEC|"."${port}|".&truncate_value($ReqPerSec)."|".&GetOsType();
$BytesPerReq = "APACHE_GLOBAL|"."BYTES_PERREQ|"."${port}|".&truncate_value($BytesPerReq)."|".&GetOsType();
$busyValue = "APACHE_GLOBAL|"."ACTIVE_PROCESS|"."${port}|".&truncate_value($busyValue)."|".&GetOsType();
$idleValue = "APACHE_GLOBAL|"."IDLE_PROCESS|"."${port}|".&truncate_value($idleValue)."|".&GetOsType();


my @temp = ();

push(@temp,$totalAccesses_current);
push(@temp,$totalTraffic_current);
push(@temp,$bytesPerSec);
push(@temp,$ReqPerSec);
push(@temp,$BytesPerReq);
push(@temp,$busyValue);
push(@temp,$idleValue);

&flush(\@temp);

#$BusyProcessesRate = &truncate_value($BusyProcessesRate);

#print $totalAccesses_current."\t".$totalTraffic_current."\t".$bytesPerSec."\t".$ReqPerSec."\t".$BytesPerReq."\t".$busyValue."\t".$idleValue."\n";



## functions ##

sub truncate_value 
{
        my $number = shift;
        my $num;my $dec;
        if ($number =~ /(.*)\.(\d\d\d)/) 
		{
                $num = $1;
                $dec = $2;
                $number = $num.'.'.$dec;
        }
        return $number;
}


sub parseFile 
{
	my @data = ();
	open (FILE, "@_") || die ("Unable to open @_") ; #open the file
	@data = <FILE> ; #read the file into an array
	close (FILE) ; #close the file


	my @parsed_data ; #Parsed output.
	my $output_word = '' ; #Current word to be flushed to the parsed output.
	my $index = 0 ; #Index of the current line in the parsed output.
	my $ignore_char = 1 ; #Ignore Char flag is turned on by default.

	foreach (@data)
	{
		chomp ;
		for (my $current_index = 0; $current_index < length($_); $current_index++) 
		{
			my $character = substr($_, $current_index, 1) ;
			if ($character eq '<') 
			{
				$ignore_char = 1 ;
				if (length(&trim($output_word)) > 0) 
				{
					$parsed_data[$index++] = $output_word;
					$output_word = '' ;
				}
				elsif ($output_word =~ / +/) 
				{
					$output_word = '' ;
				}
			}
			elsif ($character eq '>') 
			{
				$ignore_char = 0 ;
			}
			else 
			{
				$output_word = ${output_word}.${character} if ($ignore_char == 0) ;
			}
		}
	}
	
	return @parsed_data ;
}

sub trim($) {
	my $string = shift ;
	$string =~ s/^\s+// ;
	$string =~ s/\s+$// ;
	return $string;
}

sub write_to_log
{
    if ($WSSPI_TRC_LVL > 0)
    {
	if (open(TRACE, ">>$error_file"))
	{
	    my ($sec,$min,$hr,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	    my $now = sprintf "%04d/%02d/%02d %02d:%02d:%02d", $year+1900, $mon+1, $mday, $hr, $min, $sec;
	    print TRACE "$now - $$ - $_[0]";
	    close (TRACE);
	}
    }
}

sub checkDir
{
	my $dir = @_;
	if(-d $dir)
	{
		return 1;
	}
	else
	{
		my $s = system("mkdir -p  $dir");
		if($s != 0 )
		{
			return 0;
		}
	}

	return 1;
}


sub flush
{
			my ($array_ref)=@_;
			my $timestamp = strftime("%Y%m%d%H%M%S", localtime);
			my $filename = "apache_".strftime("%H%M", localtime).".csv";
			open(FL,">>${bhmDataDir}/$filename")|| die ;
			
			foreach my $entry(@{$array_ref})
			{
				print FL $timestamp."|".$entry."\n";
			}
			close(FL);
}

sub  GetOsType
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