#!/bin/perl


use Email::Send;
  use Email::Send::Gmail;
  use Email::Simple::Creator;

  my $email = Email::Simple->create(
      header => [
          From    => 'mat@tenfathomsdeep.com',
          To      => 'mat@matking.info',
          Subject => 'Server down',
      ],
      body => 'The server is down. Start panicing.',
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
