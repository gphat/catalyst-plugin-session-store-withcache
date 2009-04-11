#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Catalyst::Plugin::Session::Store::Cache' );
}

diag( "Testing Catalyst::Plugin::Session::Store::Cache $Catalyst::Plugin::Session::Store::Cache::VERSION, Perl $], $^X" );
