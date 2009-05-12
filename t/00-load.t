#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Catalyst::Plugin::Session::Store::WithCache' );
}

diag( "Testing Catalyst::Plugin::Session::Store::WithCache $Catalyst::Plugin::Session::Store::WithCache::VERSION, Perl $], $^X" );
