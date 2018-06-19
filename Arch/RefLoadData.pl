#!/bin/perl
#use lib '/root/perl5/bin';

use strict;
use warnings;
use DBI;
use REST::Client;
use Data::Dumper;
use XML::Simple;
use DateTime;
use Getopt::Long;


my $lastPull = "0";
my $full;
my $debug;
GetOptions ("date|d=s"   => \$lastPull,   # string
            "full|f"  => \$full,   # flag
            "debug"  => \$debug   # flag
	   )
or die("Error in command line arguments\n");

my $dt = DateTime->today;
my $todayDate =  $dt->ymd();

my $database = 'l360';
my $hostname = 'localhost';
my $port = '3306';
my $user = 'l360user';
my $password = 'w00pw00p';

my $dsn = "DBI:mysql:database=$database;host=$hostname;port=$port";
my $dbh = DBI->connect($dsn, $user, $password);

my $pullconfig = 'SELECT * FROM config';
my $config_data = $dbh->selectall_hashref($pullconfig,'recordid');
if ($lastPull == '0') {
  $lastPull = $config_data->{'1'}->{'lastpulldate'};
}
print Dumper $config_data if ($debug);

my @s_ids = ('851491545344381965','22916');
foreach my $storeid (@s_ids) {
my $apikey = 'a226d8edb7421adc93d289c6851fc6c5cfd1360d';

my $ret_lmt = '500';
my $ret_cnt = '500';
my $curPage = '1';
my $cnt = 1;
print "Store ID: $storeid\n" if ($debug);
#my $storeid = '851491545344381965';
my $client = REST::Client->new();

print "Limit: $ret_lmt\n" if ($debug);
while ($ret_cnt == $ret_lmt) { # Get All Pages

if ($full) {
$client->GET("https://$apikey\@app.listen360.com/organizations/$storeid/reviews.xml?per_page=$ret_lmt&page=$curPage") or die ;
print "Pulling Full Dataset\n";
} else {
$client->GET("https://$apikey\@app.listen360.com/organizations/$storeid/reviews.xml?start_date=$lastPull&per_page=$ret_lmt&page=$curPage");
}
print $client->responseContent();

my $xml = XMLin($client->responseContent, ForceContent => 1);
my @contentSize = keys %{$xml};
if (scalar @contentSize > 1) {
  $ret_cnt = @{$xml->{'survey'}};
} else {
  $ret_cnt = 0;
  print "No Results Returned.\n";
}

foreach (@{$xml->{'survey'}}) {
	my @columns = keys %{$_};
        my $cols='';
        my $vals='';
        foreach my $key (@columns) {
	   if ($_->{$key}->{'content'}) {	
             my $cname = $key;
             $cname =~ s/-/_/g;
	     $cols = "$cols,$cname";
	     my $content = $dbh->quote($_->{$key}->{'content'}); 
	     $vals = "$vals,$content";
           }
        $cols =~ s/^,//;
	$vals =~ s/^,//;
        }
        my $insert_sql = "INSERT INTO reviews($cols) VALUES ($vals)";
	$|=1;
	print "\r" . "StoreID: $storeid Page: $curPage Total: $ret_cnt Inserted: " . $cnt++ if ($debug);
	#$dbh->do("INSERT INTO reviews($cols) VALUES ($vals)");
}
print "\n";
$curPage++;
} # Get All Pages
} # StoreIds
my $updateSql = qq/UPDATE config set lastpulldate = '$todayDate' where recordid =1/; 
$dbh->do($updateSql); 
#print Dumper $xml;
