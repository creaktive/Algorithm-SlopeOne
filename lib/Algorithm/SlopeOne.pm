package Algorithm::SlopeOne;
# ABSTRACT: Slope One collaborative filtering for rated resources

=head1 SYNOPSIS

    #!/usr/bin/env perl
    use common::sense;
    use Algorithm::SlopeOne;
    use Data::Printer;

    my $s = Algorithm::SlopeOne->new;
    $s->update([
        {
            squid       => 1.0,
            cuttlefish  => 0.5,
            octopus     => 0.2,
        }, {
            squid       => 1.0,
            octopus     => 0.5,
            nautilus    => 0.2,
        }, {
            squid       => 0.2,
            octopus     => 1.0,
            cuttlefish  => 0.4,
            nautilus    => 0.4,
        }, {
            cuttlefish  => 0.9,
            octopus     => 0.4,
            nautilus    => 0.5,
        },
    ]);
    p $s->predict({ squid => 0.4 });

    # Output:
    # \ {
    #     cuttlefish   0.25,
    #     nautilus     0.1,
    #     octopus      0.233333333333333
    # }

=head1 DESCRIPTION

Perl implementation of the I<Weighted Slope One> rating-based collaborative filtering scheme.

=cut

use strict;
use utf8;
use warnings qw(all);

use Carp qw(croak);
use Moo;

# VERSION

=attr diffs

Differential ratings matrix.

=attr freqs

Ratings count matrix.

=cut

has diffs => (is => q(rw), default => sub { {} });
has freqs => (is => q(rw), default => sub { {} });

=method clear

Reset the instance.

=cut

sub clear {
    my ($self) = @_;

    $self->diffs({});
    $self->freqs({});

    return $self;
}

=method update($userprefs)

Update matrices with user preference data, accepts HashRef or ArrayRef of HashRefs:

    $s->predict({ StarWars => 5, LOTR => 5, StarTrek => 3, Prometheus => 1 });
    $s->predict({ StarWars => 3, StarTrek => 5, Prometheus => 4 });
    $s->predict([
        { IronMan => 4, Avengers => 5, XMen => 3 },
        { XMen => 5, DarkKnight => 5, SpiderMan => 3 },
    ]);

=cut

sub update {
    my ($self, $userprefs) = @_;

    my $type = ref $userprefs;
    if ($type eq q(HASH)) {
        $userprefs = [ $userprefs ];
    } elsif ($type eq q(ARRAY)) {
    } else {
        croak q(Pass HashRef or ArrayRef of HashRefs!);
    }

    for my $ratings (@{$userprefs}) {
        for my $item1 (keys %{$ratings}) {
            for my $item2 (keys %{$ratings}) {
                $self->freqs->{$item1}{$item2} ++;
                $self->diffs->{$item1}{$item2} += $ratings->{$item1} - $ratings->{$item2};
            }
        }
    }

    return $self;
}

=method predict($userprefs)

Recommend new items given known item ratings.

    $s->predict({ StarWars => 5, LOTR => 5, Prometheus => 1 });

=cut

sub predict {
    my ($self, $userprefs) = @_;

    my (%preds, %freqs);
    while (my ($item, $rating) = each %{$userprefs}) {
        while (my ($diffitem, $diffratings) = each %{$self->diffs}) {
            my $freq = $self->freqs->{$diffitem}{$item};
            next unless defined $freq;
            $preds{$diffitem} += $diffratings->{$item} + ($freq * $rating);
            $freqs{$diffitem} += $freq;
        }
    }

    return {
        map { $_ => $preds{$_} / $freqs{$_} }
        grep { not exists $userprefs->{$_} }
        keys %preds
    };
}

=head1 REFERENCES

=for :list
* L<Slope One|https://en.wikipedia.org/wiki/Slope_One> - Wikipedia article
* L<Slope One Predictors for Online Rating-Based Collaborative Filtering|http://lemire.me/fr/abstracts/SDM2005.html> - original paper
* L<Collaborative filtering made easy|http://www.serpentine.com/blog/2006/12/12/collaborative-filtering-made-easy/> - Python implementation by Bryan O'Sullivan (primary reference, test code)
* L<github.com/ashleyw/Slope-One|https://github.com/ashleyw/Slope-One> - Ruby port of the above by Ashley Williams (used to borrow test code)
* L<Programming Collective Intelligence book|http://shop.oreilly.com/product/9780596529321.do> by Toby Segaran
* L<Data Sets by GroupLens Research|http://www.grouplens.org/node/12>

=cut

1;
