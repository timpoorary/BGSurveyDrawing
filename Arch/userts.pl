#!/bin/perl

# ToDo: Restrict Returns by Date
# 	format emails
# 	send seperate emails by store
#
#
#



#!/bin/perl
$|=1;
use strict;
use warnings;
use REST::Client;
use Data::Dumper;
use XML::Simple;
use DateTime;
use Getopt::Long;

## Define Datetime Objects
my $dt_now=DateTime->now();
my ($sDate, $eDate) = fd_ld_of_lm();
print "StartDate: $sDate EndDate: $eDate\n";


## Define General Variables
my %dbgHsh = ();
my @s_ids = ('851491545344381965','22916');
my $apikey = 'a226d8edb7421adc93d289c6851fc6c5cfd1360d';
my @hopper;

## Define REST API Stuff
my $client = REST::Client->new();

## Handle Commandline Arguments
my %hOpt = ('debug','0','month','01');
GetOptions (\%hOpt, "month|m=i", "store|s=s", "help|?", "debug|d");
$dbgHsh{'options'} = \%hOpt if $hOpt{'debug'} == 1;


my $ret_lmt = '500';
my $ret_cnt = '500';
my $curPage = '1';
my $cnt = 1;
my $storeid = "";
my $storename = "";
if ($hOpt{'store'} eq 'i') {
   $storeid = '851491545344381965';
   $storename = 'Independence'; 
} elsif ($hOpt{'store'} eq 'k') {
   $storeid = '22916';
   $storename = 'North Kansas City'; 
} else {
   print "\nNeed Proper Store Code \"i\" for indep or \"k\" for KC North\n";
   print "Store ID: $storeid\n" if $hOpt{'debug'} == 1;
   exit;
}

print "Limit: $ret_lmt\n" if $hOpt{'debug'} == 1;
while ($ret_cnt == $ret_lmt) { # Get All Pages
	$client->GET("https://$apikey\@app.listen360.com/organizations/$storeid/reviews.xml?start_date=$sDate&end_date=$eDate&per_page=$ret_lmt&page=$curPage");
  print $client->responseContent() if $hOpt{'debug'} == 1;
  my $xml = XMLin($client->responseContent, ForceContent => 1);
  my @contentSize = keys %{$xml};
  if (scalar @contentSize > 1) {
    $ret_cnt = @{$xml->{'survey'}};
  } else {
    $ret_cnt = 0;
    print "No Results Returned.\n";
  }
  #print Dumper $xml if $hOpt{'debug'} == 1;
  foreach (@{$xml->{'survey'}}) {
	my $CusInfo = {'jobref',$_->{'job-reference'},'ref',$_->{'customer-reference'},'name',$_->{'customer-full-name'}->{'content'},'work-email',$_->{'customer-work-email'}->{'content'},};
	#push (@hopper, $_->{'customer-reference'}->{'content'});
      	push (@hopper, $CusInfo);
	#print "jobref: $_->{'job-reference'}->{'content'} Ref: $_->{'customer-reference'}->{'content'} Name: $_->{'customer-full-name'}->{'content'} Email: $_->{'customer-work-email'}->{'content'} Date: $_->{'completed-at'}->{'content'} \n";# if $hOpt{'debug'} == 1;
	print "jobref: $_->{'job-reference'}->{'content'} Name: $_->{'customer-full-name'}->{'content'} Email: $_->{'customer-work-email'}->{'content'} Date: $_->{'completed-at'}->{'content'} \n";# if $hOpt{'debug'} == 1;
  }
  print "\n";
  print "Current Page: $curPage\n" if $hOpt{'debug'} == 1;
  $curPage++;
} # Get All Pages

#print Dumper @hopper;
## Get User Information on Winner
my $aryTot = scalar @hopper;
my $pickNum = int rand($aryTot) + 1;
print "Picked: $pickNum out of $aryTot  Ref: $hopper[$pickNum]->{'ref'}->{'content'}\n";
if ($hopper[$pickNum]->{'ref'}->{'content'}) {
  print "Getting Customer Profile\n";
  $client->GET("https://$apikey\@app.listen360.com/organizations/$storeid/customers.xml?reference=$hopper[$pickNum]->{'ref'}->{'content'}");
  #print $client->responseContent(); # if $hOpt{'debug'} == 1;
  my $cusXml = XMLin($client->responseContent, ForceContent => 1);
  my @cxContentSize = keys %{$cusXml};
  if (scalar @cxContentSize < 1) {
    print "No Results Returned.\n";
  }
  #print Dumper $cusXml if $hOpt{'debug'} == 1;
  
  #print "Last Name: $cusXml->{'customer'}->{'last-name'}->{'content'}\n";

## Build Email Body:

 
  #print qq/Name: $hopper[$pickNum]->{'name'}\n Email: $hopper[$pickNum]->{'work-email'}\n/;
  my $mailBody = <<"CTHULHU";
The winner for $storename the month of <lastmonth> is:

   Name: $hopper[$pickNum]->{'name'}
  Phone: $cusXml->{'customer'}->{'work-phone-number'}->{'content'}  
  Email: $hopper[$pickNum]->{'work-email'}
Address: $cusXml->{'customer'}->{'work-street'}->{'content'}
         $cusXml->{'customer'}->{'work-city'}->{'content'}, $cusXml->{'customer'}->{'work-state'}->{'content'} $cusXml->{'customer'}->{'work-postal-code'}->{'content'}

Please contact his customer for their 5 free tshirts.

Details:
Single Side DTG Print
White T-Shirts.  (Upcharge for substitions)
All Desigs Must be the same.

-Mat

CTHULHU

  print $mailBody;
  #print Dumper($cusXml);
  #
} else {
  print "No Ref\n";
}

sub fd_ld_of_lm {
    use DateTime;
    use Data::Dumper;
    my @retAry;
    my $one_month_ago = DateTime->today->subtract(months => 1);
    if ( $one_month_ago->month < 9 ) {
      $retAry[0] = $one_month_ago->year . "-0" . $one_month_ago->mon ."-01";
    } else {
      $retAry[0] = $one_month_ago->year . "-" . $one_month_ago->mon ."-01";
    }
    $retAry[1] = DateTime->last_day_of_month(
                  month => $one_month_ago->month,
                  year  => $one_month_ago->year,
                 )->ymd . "\n";
    return ($retAry[0], $retAry[1]);
}




