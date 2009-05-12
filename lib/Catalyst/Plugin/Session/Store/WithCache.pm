package Catalyst::Plugin::Session::Store::WithCache;
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

__PACKAGE__->mk_classdata(qw/_session_cache _seconds/);

=head1 NAME

Catalyst::Plugin::Session::Store::WithCache - Caching layer for Catalyst Sessions

=head1 SYNOPSIS

    use Catalyst qw/Session Session::Store::WithCache Session::Store::Something/;

    MyApp->config->{session}-> = {
        with_cache => {
            driver_options => {
				driver => 'Memory',
				global => 1
			},
            seconds => 300
        }
    };

=head1 DESCRIPTION

C<Catalyst::Plugin::Session::Store::WithCache> sits atop your B<existing session
store>, caching sessions reads and writes.  The C<seconds> configuration option
provides the number of seconds that the session is allowed to be "stale".
Failure of the underlying cache during this time would result in lost data,
but that might be ok with you if it speeds things up.

L<CHI> is used as the underlying cache, so the C<driver> option must be
a driver that CHI will recognize.

=cut

sub setup_session {
    my $c = shift;

    $c->log->error('setup_session');

    $c->maybe::next::method(@_);

    my $cache = CHI->new(
    	%{ $c->config->{session}->{with_cache}->{driver_options} }
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
        my $fudge = $c->config->{}->{seconds} || 10;
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
        $c->log->debug("Not expire, updating.");
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

=head1 AUTHOR

Cory G Watson, C<< <gphat at cpan.org> >>

=head1 ACKNOWLEDGEMENTS

Florian Ragwitz for providing some hints on implementation.

=head1 COPYRIGHT & LICENSE

Copyright 2009 Cory G Watson, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;