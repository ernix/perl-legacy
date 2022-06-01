use strict;
use warnings;
use Test::More;
use Encode;
BEGIN {
    use_ok 'Encode';
    use_ok FindBin => qw($RealBin);
}

require_ok "$RealBin/../src/mimer.pl";

subtest example1 => sub {
    my $from;

    $from = "From: Noboru Ikuta / =?ISO-2022-JP?B?GyRCQDhFRBsoQg==?=";
    $from .= "\n\t=?ISO-2022-JP?B?GyRCPjobKEI=?=";
    $from .= " <noboru\@ikuta.ichihara.chiba.jp>";

    is encode_utf8(decode('euc-jp', &mimedecode($from, "EUC"))),
        "From: Noboru Ikuta / 生田昇 <noboru\@ikuta.ichihara.chiba.jp>";
};

subtest example2 => sub {
    open local(*ARGV), '<', \<<'__BASE64' or die "Can not open fake argv: $!";
TWFuIGlzIGRpc3Rpbmd1aXNoZWQsIG5vdCBvbmx5IGJ5IGhpcyByZWFzb24sIGJ1dCBieSB0aGlz
IHNpbmd1bGFyIHBhc3Npb24gZnJvbSBvdGhlciBhbmltYWxzLCB3aGljaCBpcyBhIGx1c3Qgb2Yg
dGhlIG1pbmQsIHRoYXQgYnkgYSBwZXJzZXZlcmFuY2Ugb2YgZGVsaWdodCBpbiB0aGUgY29udGlu
dWVkIGFuZCBpbmRlZmF0aWdhYmxlIGdlbmVyYXRpb24gb2Yga25vd2xlZGdlLCBleGNlZWRzIHRo
ZSBzaG9ydCB2ZWhlbWVuY2Ugb2YgYW55IGNhcm5hbCBwbGVhc3VyZS4=
__BASE64

    local $/ = undef;
    is &bodydecode(<>),
        'Man is distinguished, not only by his reason, but by this singular'
        . ' passion from other animals, which is a lust of the mind, that by'
        . ' a perseverance of delight in the continued and indefatigable'
        . ' generation of knowledge, exceeds the short vehemence of any carnal'
        . ' pleasure.'
        ;

    is &bdeflush(), q{};
};

done_testing;
