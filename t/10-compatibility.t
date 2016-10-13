use strict;
use warnings;
use Test::More;

use Test::MockTime qw(set_relative_time restore_time);
use Test::FailWarnings;

use RateLimitations::Pluggable;

my $current_time = 0;
BEGIN {
  no warnings qw(redefine);
  *CORE::GLOBAL::time = sub() { $current_time; };
}


subtest "simple within_rate_limits" => sub {
    my $storage = {};
    $current_time = 1476355931;

    my $rl = RateLimitations::Pluggable->new({
        limits => {
            sample_service => {
                60   => 2,
                3600 => 5,
            }
        },
        getter => sub {
            my ($service, $consumer) = @_;
            return $storage->{$service}->{$consumer};
        },
        setter => sub {
            my ($service, $consumer, $hits) = @_;
            $storage->{$service}->{$consumer} = $hits;
        },
    });
    ok $rl->within_rate_limits('sample_service', 'client_1'), "1st attempt successful";
    ok $rl->within_rate_limits('sample_service', 'client_1'), "2st attempt successful";
    ok !$rl->within_rate_limits('sample_service', 'client_1'), "3rd attempt failed";
    for (1 .. 10) {
        ok !$rl->within_rate_limits('sample_service', 'client_1'), "additional attempt $_ failed";
    }
    ok $rl->within_rate_limits('sample_service', 'client_2'), "no interferrance with other consumer";
    ok $rl->within_rate_limits('sample_service', 'client_2'), "no interferrance with other consumer (2nd)";
    ok !$rl->within_rate_limits('sample_service', 'client_2'), "other consumer can also hit limit (3rd attempt)";

    subtest "after 60 seconds" => sub {
        $current_time += 60;
        ok !$rl->within_rate_limits('sample_service', 'client_1'), "hourly limit hit";
        ok !$rl->within_rate_limits('sample_service', 'client_1'), "hourly limit hit";
        ok !$rl->within_rate_limits('sample_service', 'client_1'), "hourly limit hit";
        ok $rl->within_rate_limits('sample_service', 'client_2'), "client2 still can consume service";
        ok $rl->within_rate_limits('sample_service', 'client_2'), "client2 still can consume service(2nd)";
        ok !$rl->within_rate_limits('sample_service', 'client_2'), "client2 hits hourly limit too";
    };

    subtest "after 1 hour" => sub {
        $current_time += 3600;
        ok $rl->within_rate_limits('sample_service', 'client_1'), "1st attempt successful";
        ok $rl->within_rate_limits('sample_service', 'client_1'), "2st attempt successful";
        ok !$rl->within_rate_limits('sample_service', 'client_1'), "3rd attempt failed";
        ok $rl->within_rate_limits('sample_service', 'client_2'), "no interferrance with other consumer";
        ok $rl->within_rate_limits('sample_service', 'client_2'), "no interferrance with other consumer (2nd)";
        ok !$rl->within_rate_limits('sample_service', 'client_2'), "other consumer can also hit limit (3rd attempt)";
    };

    subtest "no infite storage consumption" => sub {
        for (0 .. 4000) {
            $rl->within_rate_limits('sample_service', 'client_1');
        }
        is scalar(@{ $storage->{sample_service}->{client_1} }), 3600, "no inifininte storage consumtion for client_1 hits";
    }

};

=x
subtest 'verify_rate_limitations_config' => sub {
    ok(verify_rate_limitations_config(), 'Included rate limitations are ok');
};


my ($service, $consumer) = ('rl_internal_testing', 'CR001');
my $consume = {
    service  => $service,
    consumer => $consumer,
};

subtest 'rate_limited_services' => sub {
    ok((grep { $_ eq $service } rate_limited_services()), 'The test service is defined');
};

subtest 'rate_limits_for_service' => sub {
    throws_ok { rate_limits_for_service() } qr/Unknown service/, 'Must supply a known service name';
    eq_or_diff([rate_limits_for_service($service)], [[10, 2], [300, 6]], 'Got expected rates for our test service');
};


subtest 'all service consumers' => sub {
    plan skip_all => 'Test::RedisServer is required for this test' unless $redis_server;
    lives_ok { flush_all_service_consumers() } 'flushing does not die';
    eq_or_diff(all_service_consumers(), {}, 'leaving an empty list');
    my $result = {$service => [$consumer]};
    ok within_rate_limits($consume), 'Add a consumer';
    eq_or_diff(all_service_consumers(), $result, 'added consumer fills out our result');
    ok within_rate_limits($consume), 'Reuse the consumer';
    eq_or_diff(all_service_consumers(), $result, 'result is unchanged');
    cmp_ok flush_all_service_consumers(), '==', 1, 'flushed the single consumer';
};

subtest 'within_rate_limits' => sub {
    plan skip_all => 'Test::RedisServer is required for this test' unless $redis_server;
    note 'This depends on the form of the rate_limits_for_service tested above';
    foreach my $count (1 .. 2) {
        ok within_rate_limits($consume), 'Attempt ' . $count . ' ok';
    }
    ok !within_rate_limits($consume), 'Attempt 3 fails';
    set_relative_time(10);
    note 'Moved to the end of our limits we should be able to go again.';
    foreach my $count (1 .. 2) {
        ok within_rate_limits($consume), 'Attempt ' . $count . ' ok';
    }
    ok !within_rate_limits($consume), 'Attempt 3 fails';
    set_relative_time(20);
    note 'Moved to the end again, but now slower limit takes over (includes failures)';
    ok !within_rate_limits($consume), '... so it fails';
    set_relative_time(300);
    note 'Moved past the end of the longer slower limit';
    ok within_rate_limits($consume),  '... so we can start up again';
    ok within_rate_limits($consume),  '... but only a couple times';
    ok !within_rate_limits($consume), '... until we fail again';

    restore_time();
};
=cut


done_testing;
