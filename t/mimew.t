use strict;
use warnings;
use Test::More;
use Encode;
BEGIN {
    use_ok 'Encode';
    use_ok FindBin => qw($RealBin);
}

require_ok "$RealBin/../src/mimew.pl";

subtest example1 => sub {
    my $from;

    $from = "From: 生田 昇 <noboru\@ikuta.ichihara.chiba.jp>";
    $from = encode('euc-jp', decode_utf8($from));

    is &mimeencode($from),
        'From: =?ISO-2022-JP?B?GyRCQDhFRBsoQg==?='
        . ' =?ISO-2022-JP?B?GyRCPjobKEI=?='
        . "\n  <noboru\@ikuta.ichihara.chiba.jp>" ;
};

subtest example2 => sub {
    my $argv
        = 'Man is distinguished, not only by his reason, but by this singular'
        . ' passion from other animals, which is a lust of the mind, that by'
        . ' a perseverance of delight in the continued and indefatigable'
        . ' generation of knowledge, exceeds the short vehemence of any carnal'
        . ' pleasure.'
        ;

    open local(*ARGV), '<', \$argv or die "Can not open fake argv: $!";

    local $/ = undef;
    is &bodyencode(<>), <<'__BASE64';
TWFuIGlzIGRpc3Rpbmd1aXNoZWQsIG5vdCBvbmx5IGJ5IGhpcyByZWFzb24sIGJ1dCBieSB0
aGlzIHNpbmd1bGFyIHBhc3Npb24gZnJvbSBvdGhlciBhbmltYWxzLCB3aGljaCBpcyBhIGx1
c3Qgb2YgdGhlIG1pbmQsIHRoYXQgYnkgYSBwZXJzZXZlcmFuY2Ugb2YgZGVsaWdodCBpbiB0
aGUgY29udGludWVkIGFuZCBpbmRlZmF0aWdhYmxlIGdlbmVyYXRpb24gb2Yga25vd2xlZGdl
__BASE64

    is &benflush(),
        "LCBleGNlZWRzIHRoZSBzaG9ydCB2ZWhlbWVuY2Ugb2YgYW55IGNhcm5hbCBwbGVhc3VyZS4=\n";
};

done_testing;

