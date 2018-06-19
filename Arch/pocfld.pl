#!/bin/perl
#


    use DateTime;
    use Data::Dumper;
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

    print Dumper @retAry;

