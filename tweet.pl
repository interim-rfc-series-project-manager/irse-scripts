#!/usr/local/bin/perl
# $Header: /home/johnl/hack/RCS/tweet,v 1.1 2013/07/04 21:07:14 johnl Exp $

# tweet a string to a known account
# -a account
# -s read stdin
# -f read file (otherwise literal arguments)
# -w wrap long tweets into a numbered series of replies

# To get OAUTH consumer info see
# https://developer.twitter.com/en/docs/twitter-api/getting-started/getting-access-to-the-twitter-api
# and https://dev.twitter.com/docs/api/1.1/overview

# To set up a new account, make a .twittok-x file with two blank lines
# account name, and screen name.  Run tweet and it will provide the
# auth URL

use open qw( :std :encoding(UTF-8) );
use strict;
use Net::Twitter::Lite::WithAPIv1_1;
use Getopt::Std;
use Encode;

use vars qw{$opt_a $opt_d $opt_f $opt_s $opt_w $access_token $access_token_secret $user_id $screen_name};
getopts('a:df:sw');

$| = 1; # flush output

my $tokfile = ".twittok";
$tokfile .= "-$opt_a" if defined $opt_a;

die "need something to tweet" if !$opt_f && !$opt_s && !$ARGV[0];

if(open(TT, "<$tokfile")) {
    my @f = <TT>;
    chomp(@f);
    close TT;
    ($access_token, $access_token_secret, $user_id, $screen_name) = @f;
} else {
    print "No token file.\n";
    exit 1;
}

my $nt = Net::Twitter::Lite::WithAPIv1_1->new(
    traits   => [qw/API::REST/, 'OAuth'],
    ssl => 1,
    consumer_key => 'xx', # OAUTH key provided by Twitter, see API documentation
    consumer_secret => 'xxx', # OAUTH secret provided by Twitter, see API documentation
    access_token => $access_token,
    access_token_secret => $access_token_secret,
    );

unless ( $nt->authorized ) {
    # The client is not yet authorized: Do it now
    print "Authorize this app at ", $nt->get_authorization_url, " and enter the PIN#\n";

    my $pin = <STDIN>; # wait for input
    chomp $pin;

    ($access_token, $access_token_secret, $user_id, $screen_name) = 
	$nt->request_access_token(verifier => $pin);
    open(TT, ">$tokfile") or die "write token file";
    print TT "$access_token\n$access_token_secret\n$user_id\n$screen_name\n";
    close TT;
}
print "Tweeting as $screen_name\n";

my ($last_id);

sub tweet($$) {
    my ($msg, $reply) = @_;
    my ($res);

    if($opt_d) {
	    print "tweet $msg\n";
	    return;
    }

    if($reply and $last_id) {
	$res = $nt->update({"status" => $msg, "in_reply_to_status_id" => $last_id});
    } else {
	$res = $nt->update($msg);
    }
    print $res->{text},"\n";
    $last_id = $res->{id};
}

sub wraptweet($) {
    my ($msg) = @_;

    my ($ntot, $i, $m, @tw);

    while(length($msg) > 250) {
	    my $p = rindex($msg, " ", 250);
	    last if !$p;	    
	    push @tw,substr($msg, 0, $p+1);
	    $msg = substr($msg, $p+1);
    }
    if( scalar(@tw) == 0) {
	    tweet($msg, 0);
	    return;
    }
    push @tw, $msg;
    $ntot = scalar @tw;
    $last_id = undef;			# make this a new sequence
    for($i = 1; $m = shift @tw; $i++) {
	    if( $i > 1) {
		    print("Sleeping...");
		    sleep(20);
	    }
	    tweet("$m $i/$ntot", 1);
    }
}

if($opt_f) {
    open(F, "<$opt_f") or die "cannot open $opt_f";
    while(<F>) {
	chomp;
	wraptweet($_) if $opt_w;
	tweet($_, 0) if !$opt_w;
    }
    close F;
} elsif ($opt_s) {
    while(<>) {
	chomp;
	wraptweet($_) if $opt_w;
	tweet($_, 0) if !$opt_w;
    }

} else {
    wraptweet(join(' ',@ARGV)) if $opt_w;;
    tweet(join(' ',@ARGV), 0) if !$opt_w;
}

exit 0;
