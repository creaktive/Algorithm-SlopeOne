package Algorithm::SlopeOne;
# ABSTRACT: Slope One collaborative filtering for rated resources

=head1 SYNOPSIS

    #!/usr/bin/env perl
    use common::sense;
    use Algorithm::SlopeOne;
    use Data::Printer;

    my $s = Algorithm::SlopeOne->new;
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

=method update($userdata)

Update matrices with data in a form:

    {
        user1 => {
            item1 => rating1,
            item2 => rating2,
            ...
        },
        user2 => ...
    }

=cut

sub update {
    my ($self, $userdata) = @_;

    for my $ratings (values %{$userdata}) {
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

Recommend new items given item ratings in a form:

    {
        item1 => rating1,
        item2 => rating2,
        ...
    }

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

=cut

1;
