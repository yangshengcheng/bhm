#!/usr/bin/perl -w


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

#check  the basic variable
sub  check_env
{
	if($osname=~/win/i)
	{
		
		$bhm_node_info_dir = "$ENV{OvDataDir}\\bhm\\conf\\";
		
	}
	elsif($osname=~/tru/i)
	{

		$bhm_node_info_dir="/usr/var/opt/OV/bhm/conf/";

	}
	else
	{
		$bhm_node_info_dir="/var/opt/OV/bhm/conf/";

	}
}

# update  node  info file
sub  update_nodeinfo
{
	my ($dir,$info,$value)=@_;
	my $file = "nodeinfo";
	unless(open(NODE,">${dir}$file"))
	{
		print "open nodeinfo file fail\n";
		exit 1;
	}
	print NODE $info." ".$value."\n";
	close(NODE);
	return  ;

}

sub GetRezult
{
	my ($dir)=@_;
	my $file = "nodeinfo";
	unless(open(NODE,"${dir}$file") )
	{
		print "update nodeinfo  file fail\n";
		exit 1 ;
	}
	print <NODE>;
	close(NODE);
	return  ;
}
### main  ###
my $info = shift @ARGV;
my $value = shift @ARGV;

our  $osname = &checkOs();
our $bhm_node_info_dir; 

&check_env();
&genDir($bhm_node_info_dir);


&update_nodeinfo($bhm_node_info_dir,$info,$value);

#check  result
&GetRezult($bhm_node_info_dir);








