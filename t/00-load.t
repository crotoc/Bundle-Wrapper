#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Bundle::Wrapper' ) || print "Bail out!\n";
}

diag( "Testing Bundle::Wrapper $Bundle::Wrapper::VERSION, Perl $], $^X" );
