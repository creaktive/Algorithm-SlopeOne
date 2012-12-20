#!perl
use strict;
use utf8;
use warnings qw(all);

use Test::More;

use Algorithm::SlopeOne;

my $s = Algorithm::SlopeOne->new;
isa_ok($s, q(Algorithm::SlopeOne));
can_ok($s, qw(update predict));

$s->update({
    alice => {
        squid       => 1.0,
        cuttlefish  => 0.5,
        octopus     => 0.2,
    }, bob => {
        squid       => 1.0,
        octopus     => 0.5,
        nautilus    => 0.2,
    }, carole => {
        squid       => 0.2,
        octopus     => 1.0,
        cuttlefish  => 0.4,
        nautilus    => 0.4,
    }, dave => {
        cuttlefish  => 0.9,
        octopus     => 0.4,
        nautilus    => 0.5,
    },
});
is_deeply(
    $s->predict({ squid => 0.4 }),
    { cuttlefish => 0.25, nautilus => 0.1, octopus => 7 / 30 },
    q(range 0-1),
);

$s->clear;

is_deeply(
    $s->predict({ Eastenders => 7.25 }),
    {},
    q(empty),
);

$s->update({
    rob => {
        24          => 9.5,
        Lost        => 8.2,
        House       => 6.8,
    },
});
$s->update({
    bob => {
        24          => 3.7,
        "Big Bang Theory" => 2.1,
        House       => 8.3,
    },
});
$s->update({
    tod => {
        24          => 9.5,
        Lost        => 3.4,
        House       => 5.5,
        "Big Bang Theory" => 9.3,
    },
    dod => {
        24          => 7.2,
        Lost        => 5.1,
        House       => 8.4,
        "The Event" => 7.8,
    },
});
is_deeply(
    $s->predict({ House => 3, q(Big Bang Theory) => 7.5 }),
    { 24 => 4.95, Lost => 1.65, q(The Event) => 2.4 },
    q(range 0-10),
);

is_deeply(
    $s->predict({ Eastenders => 7.25 }),
    {},
    q(non-matching),
);

done_testing 6;
