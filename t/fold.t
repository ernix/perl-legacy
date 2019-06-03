use strict;
use warnings;
use Test::More;
use Test::Differences;

use FindBin qw($RealBin);
require_ok "$RealBin/../src/fold.pl";

my $text = 'This is a bit of text that forms a normal book-style paragraph';

subtest fold => sub {
    for my $width (1 .. 20) {
        my ($tmp, $rest) = (q{}, $text);

        my @lines;
        while (length $rest) {
            ($tmp, $rest) = fold($rest, $width);
            push @lines, $tmp;
        }

        my $result = join "\n", @lines;

        my $expected = join "\n", unpack "(a$width)*", $text;
        eq_or_diff $result, $expected, "fold_$width";
    }
};

done_testing;
