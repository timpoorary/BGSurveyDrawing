#!/bin/perl
#use lib '/root/perl5/bin';

use strict;
use warnings;
use REST::Client;
use Data::Dumper;
use XML::Simple;
#use DBIx;

my $apikey = 'a226d8edb7421adc93d289c6851fc6c5cfd1360d';
my $storeid = '851491545344381965';
my $client = REST::Client->new();
#$client->GET("https://$apikey\@app.listen360.com/organizations/$storeid/reviews.xml");
$client->GET("https://$apikey\@app.listen360.com/organizations/$storeid/customers/#2601.xml");
print $client->responseContent();

my $xml = XMLin($client->responseContent, ForceContent => 1);

foreach ($xml->{'survey'}) {
print $_{'comments'}->{'content'};
}
#print $xml->{'survey'}[0]->{'comments'}->{'content'};
print Dumper $xml;
