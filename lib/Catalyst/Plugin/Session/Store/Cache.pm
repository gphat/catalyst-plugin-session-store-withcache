package Catalyst::Plugin::Session::Store::Cache;
use strict;
use warnings;

use base qw(
    Catalyst::Plugin::Session::Store
    Class::Accessor::Fast
    Class::Data::Inheritable
);

use MRO::Compat;

use CHI ();

our $VERSION = '0.01';

__PACKAGE__->mk_classdata(qw/_session_cache/);

sub setup_session {
    my $c = shift;

    $c->log->error('setup_session');

    $c->maybe::next::method(@_);

    my $cache = CHI->new(
        driver => $c->config->{session}->{cache}->{driver}
    );

    $c->_session_cache($cache);
}

sub get_session_data {
    my ($c, $key) = @_;

    my ($prefix, $sid) = split(/:/, $key);

    $c->log->error("get_session_data: $key");

    my $data = $c->_session_cache->get($key);

    if($data) {
        $c->log->error('CACHE HIT');
        return $data;
    } else {
        $c->log->error('!! CACHE MISS');
    }

    $data = $c->maybe::next::method($key);

    $c->_session_cache->set($key, $data);

    return $data;
}

sub store_session_data {
    my ($c, $key, $data) = @_;

    my ($prefix, $sid) = split(/:/, $key);

    $c->log->error("store_session_data: $key ($data)");

    my $curr_expiry = $c->_session_cache->get("expires:$sid");

    if($curr_expiry && $key =~ /^expires:/) {
        # If we are asked to store an expiration, compare it to the existing
        # expiration and only let it go to the backend if the expire time
        # is far enough, based on the config
        my $fudge = $c->config->{session}->{cache}->{time} || 10;
        if($data > ($curr_expiry + $fudge)) {
            # The new expiration is greater than the current one plus the
            # fudge time so let it go to the real store
            $c->log->debug('Fudge exceeded, updating.');
            $c->maybe::next::method($key, $data);
        } else {
            $c->log->debug('Fudge not exceeded, skipping.');
        }
    } else {
        # If this isn't an expire update, let it come across
        $c->log->debug('Not expire, updating.');
        $c->maybe::next::method($key, $data);
    }

    # We are updating the cache regardless..
    $c->_session_cache->set($key, $data);
}

sub delete_session_data {
    my ($c, $sid) = @_;

    $c->log->error("delete_session_data: $sid");

    $c->_session_cache->remove($sid);

    $c->maybe::next::method($sid);
}

sub delete_expired_session {
    my ($c) = @_;

    $c->log->error('delete_session_data');

    $c->maybe::next::method(@_);
}

1;