#!/usr/bin/perl -w

use Getopt::Std;
use vars qw($opt_l $opt_d $opt_e);
use File::Copy;
use Symbol;


#global variables
our $syslog_conf_file = "syslog.conf";
our $backup_file = "syslog.conf.bak";
sub usage
{
	print("usage: /usr/bin/perl bhm_os_unix_config_syslogconf.pl -l level -d  destination -e eraser\n");
	print("level: default *.debug\n");
	print("destination: can be \@ip or local log file\n");
	print("eraser: the config line will be eraser\n");
	exit(1);
}

# deal the argument with prefix
getopts('l:d:e:');

usage() unless($opt_l ||$opt_d );

# print $opt_l."\t".$opt_d."\n";
my $entry = $opt_l."\t\t\t".$opt_d."\n";

unless(-e "$syslog_conf_file")
{
	die("/etc/syslog.conf isn't exists\n");
}

#backup  the conf file before edit it
unless(-e $backup_file)
{
	unless(copy("$syslog_conf_file","$backup_file"))
	{
		die("copy file fail $!\n");
	}
}


#change the config file 
my @temp = ();
my $fl = gensym();
my $l;
unless(open($fl,$syslog_conf_file))
{
	die("open $syslog_conf_file");
}

while($l = <$fl>)
{
	unless($l=~/^\*\.debug\s+${opt_d}$/ || $l=~/^\*\.debug\s+${opt_e}$)
	{
		push(@temp,$l);
	}
}

close($fl);

unless(open($fl,">$syslog_conf_file"))
{
	die("copy file fail $!\n");
}
foreach(@temp)
{
	print $_;
	print $fl $_;
}
print $fl $entry;
close($fl);


