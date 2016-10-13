package RateLimitations::Pluggable;

use strict;
use warnings;

use Carp;
use Moo;

our $VERSION = '0.01';

has limits => (
    is       => 'ro',
    required => 1,
    isa      => sub {
        croak "limits must be a hashref"
            unless (ref($_[0]) // '') eq 'HASH';
    },
);
has getter => (
    is       => 'ro',
    required => 1,
    isa      => sub {
        croak "limits must be a coderef"
            unless (ref($_[0]) // '') eq 'CODE';
    },
);

has setter => (
    is       => 'ro',
    required => 0,
    isa      => sub {
        croak "limits must be a coderef"
            if defined($_[0]) && (ref($_[0]) // '') ne 'CODE';
    },
);

# key: service name
# value: sorted by $seconds array of pairs [$seconds, $rate]
has _limits_for => (is => 'rw');

sub BUILD {
    my $self = shift;
    my %limits_for;
    for my $service (keys %{$self->limits}) {
        my @service_limits =
            sort { $a->[0] <=> $b->[0] }
            map {
            my $seconds = $_;

            croak("'$seconds' seconds is not integer for service $service")
                if $seconds - int($seconds) != 0;

            croak("'$seconds' seconds is not positive for service $service")
                if $seconds <= 0;

            my $limit = $self->limits->{$service}->{$seconds};

            croak("limit '$limit' is not integer for service $service")
                if $limit - int($limit) != 0;
            croak("limit '$limit' is not positive for service $service")
                if $limit <= 0;

            [$seconds, $limit];
            } keys %{$self->limits->{$service}};

        # validate correctness: limit for greater time interval should be greater
        for my $idx (1 .. @service_limits - 1) {
            my $lesser_limit  = $service_limits[$idx - 1]->[1];
            my $current_limit = $service_limits[$idx]->[1];
            if ($current_limit <= $lesser_limit) {
                croak "limit ($current_limit) for "
                    . $current_limit->[0]
                    . " seconds"
                    . " should be greater then limit ($lesser_limit) for "
                    . $service_limits[$idx - 1]->[0]
                    . "seconds";
            }
        }
        $limits_for{$service} = \@service_limits;
    }
    $self->_limits_for(\%limits_for);
}

sub within_rate_limits {
    my ($self, $service, $consumer) = @_;
    croak "service should be defined"  unless defined $service;
    croak "consumer should be defined" unless defined $consumer;

    my $limits = $self->_limits_for->{$service};
    croak "unknown service: '$service'" unless defined $limits;

    my $hits          = $self->getter->($service, $consumer) // [];
    my $within_limits = 1;
    my $now           = time;
    # We push first so that we hit limits more often in heavy (DoS) conditions
    push @$hits, $now;
    # Remove extra oldest hits, as they do not participate it checks anyway
    shift @$hits while (@$hits > $limits->[-1]->[0]);

    # optionally notify updated service hits
    my $setter = $self->setter;
    $setter->($service, $consumer, $hits) if $setter;

    for my $rate (@$limits) {
        # take the service time hit which occur exactly $max_rate times ago
        # might be undefined.
        # +1 is added because we already inserted $now hit above, which
        # should be out of the consideration
        my $past_hit_time = $hits->[($rate->[1] + 1) * -1] // 0;
        my $allowed_past_hit_time = $now - $rate->[0];
        if ($past_hit_time > $allowed_past_hit_time) {
            $within_limits = 0;
            last;
        }
    }

    return $within_limits;
}

1;
