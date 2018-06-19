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
use Email::Send;
use Email::Send::Gmail;
use Email::Simple::Creator;

## Handle Commandline Arguments
my %hOpt = ('debug','0','month','01');
GetOptions (\%hOpt, "month|m=i", "store|s=s", "help|?", "debug|d");

## Define Datetime Objects
my $dt_now=DateTime->now();
my ($sDate, $eDate, $monthName) = fd_ld_of_lm();
print "debug: StartDate: $sDate EndDate: $eDate\n" if $hOpt{'debug'} == 1;;

## Define General Variables
my %dbgHsh = ();
my @s_ids = ('851491545344381965','22916');
my $apikey = 'a226d8edb7421adc93d289c6851fc6c5cfd1360d';
$dbgHsh{'options'} = \%hOpt if $hOpt{'debug'} == 1;
my @hopper;

## Define REST API Stuff
my $client = REST::Client->new();
my $review = REST::Client->new();
my $job = REST::Client->new();


my $ret_lmt = '500';
my $ret_cnt = '500';
my $curPage = '1';
my $cnt = 1;
my $storeid = "";
my $storeName = "";
my $storeEmail = "";
if ($hOpt{'store'} eq 'i') {
   $storeid = '851491545344381965';
   $storeName = 'Independence'; 
   $storeEmail = 'independence@bigfrog.com,mat@matking.info,phillipk@bigfrog.com,beth@sbking.org'; 
} elsif ($hOpt{'store'} eq 'k') {
   $storeid = '22916';
   $storeName = 'North Kansas City'; 
   $storeEmail = 'kcnorth@bigfrog.com,,mat@matking.info,phillipk@bigfrog.com,beth@sbking.org'; 
} else {
   print "\nNeed Proper Store Code \"i\" for indep or \"k\" for KC North\n";
   print "debug: Store ID: $storeid\n" if $hOpt{'debug'} == 1;
   exit;
}

print "debug: Limit: $ret_lmt\n" if $hOpt{'debug'} == 1;
## Get All Reviews for the last month.
while ($ret_cnt == $ret_lmt) { 
  $review->GET("https://$apikey\@app.listen360.com/organizations/$storeid/reviews.xml?start_date=$sDate&end_date=$eDate&per_page=$ret_lmt&page=$curPage");
  print $review->responseContent() if $hOpt{'debug'} == 1;
  my $rvXml = XMLin($review->responseContent, ForceContent => 1);
  my @contentSize = keys %{$rvXml};
  if (scalar @contentSize > 1) {
    $ret_cnt = @{$rvXml->{'survey'}};
  } else {
    $ret_cnt = 0;
    print "No Results Returned.\n";
  }
  #print Dumper $rvXml; # if $hOpt{'debug'} == 1;
  foreach (@{$rvXml->{'survey'}}) {
	#push (@hopper, $_->{'job-reference'}->{'content'});
	push (@hopper, $_);
	print "debug: JobRef: $_->{'job-reference'}->{'content'} CusRef: $_->{'customer-reference'}->{'content'} Name: $_->{'customer-full-name'}->{'content'} Email: $_->{'customer-work-email'}->{'content'} Date: $_->{'completed-at'}->{'content'} \n" if $hOpt{'debug'} == 1;
  }
  print "debug:  Current Page: $curPage\n" if $hOpt{'debug'} == 1;
  $curPage++;
} # Get All Pages

## Select Winning Review
#print Dumper @hopper;
my $aryTot = scalar @hopper;
my $pickNum = int rand($aryTot);
print "debug:  Picked: $pickNum out of $aryTot  Job Ref: $hopper[$pickNum]->{'job-reference'}->{'content'}\n" if $hOpt{'debug'} == 1;


## Get Job Information
$job->GET("https://$apikey\@app.listen360.com/organizations/$storeid/jobs.xml?reference=$hopper[$pickNum]->{'job-reference'}->{'content'}");
#print $job->responseContent(); # if $hOpt{'debug'} == 1;
my $jobXml = XMLin($job->responseContent, ForceContent => 1);
my @jobContentSize = keys %{$jobXml};
if (scalar @jobContentSize < 1) {
  print "No Results Returned.\n";
}
#print Dumper $jobXml;
print "debug: Client ID: $jobXml->{'job'}->{'customer-id'}->{'content'}\n" if $hOpt{'debug'} == 1;

## Get Customer Information
$client->GET("https://$apikey\@app.listen360.com/organizations/$storeid/customers/$jobXml->{'job'}->{'customer-id'}->{'content'}.xml");
#print $client->responseContent(); # if $hOpt{'debug'} == 1;
my $cusXml = XMLin($client->responseContent, ForceContent => 1);
my @cxContentSize = keys %{$cusXml};
if (scalar @cxContentSize < 1) {
  print "No Results Returned.\n";
}
#print Dumper $cusXml; #if $hOpt{'debug'} == 1;


## Build Information Object
my $mailBody;
{ no warnings 'uninitialized';
my $emailVar = { 'name',$cusXml->{'full-name'}->{'content'},
	         'phone',$cusXml->{'work-phone-number'}->{'content'},
		 'email',$cusXml->{'work-email'}->{'content'},
                 'address-1',$cusXml->{'work-street'}->{'content'},
                 'address-2',"$cusXml->{'work-city'}->{'content'}, $cusXml->{'work-region'}->{'content'}, $cusXml->{'work-postal-code'}->{'content'}",
		 'score',$hopper[$pickNum]->{'recommendation-likelihood'}->{'content'},
		 'comment',qq/$hopper[$pickNum]->{'comments'}->{'content'}/
		};
print Dumper $emailVar if $hOpt{'debug'} == 1;; 



## Build Email Body:
$mailBody = <<"CTHULHU";
The winner for $storeName the month of $monthName is:

     Name: $emailVar->{'name'} 
    Phone: $emailVar->{'phone'}  
    Email: $emailVar->{'email'}
  Address: $emailVar->{'adress-1'} 
           $emailVar->{'adress-2'}

    Score: $emailVar->{'score'}
  Comment: $emailVar->{'comment'}

Please post to facebook and contact this customer for their 5 free tshirts.

Details:
Single Side DTG Print
White T-Shirts.  (Upcharge for substitions)
All Desigs Must be the same.

-Mat

CTHULHU
}

	  #To      => "$storeEmail",
print $mailBody;

  my $email = Email::Simple->create(
      header => [
          From    => 'mat@tenfathomsdeep.com',
          To      => "$storeEmail",
          Subject => 'Winner Winner Chicken Dinner',
      ],
      body => $mailBody,
  );

  my $sender = Email::Send->new(
      {   mailer      => 'Gmail',
          mailer_args => [
              username => 'mat@tenfathomsdeep.com',
              password => 'ojxgqdaizskoauaj',
          ]
      }
  );
  eval { $sender->send($email) };
  die "Error sending email: $@" if $@;

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
    $retAry[2] = $one_month_ago->month_name;
    return ($retAry[0], $retAry[1], $retAry[2]);
}




