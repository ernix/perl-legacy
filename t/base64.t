use strict;
use warnings;
use Test::More;

use FindBin qw($RealBin);

require_ok "$RealBin/../src/base64.pl";

my $binary_string
    = 'Man is distinguished, not only by his reason, but by this singular'
    . ' passion from other animals, which is a lust of the mind, that by'
    . ' a perseverance of delight in the continued and indefatigable'
    . ' generation of knowledge, exceeds the short vehemence of any carnal'
    . ' pleasure.'
    ;

my $base64 = <<'__BASE64';
TWFuIGlzIGRpc3Rpbmd1aXNoZWQsIG5vdCBvbmx5IGJ5IGhpcyByZWFzb24s
IGJ1dCBieSB0aGlzIHNpbmd1bGFyIHBhc3Npb24gZnJvbSBvdGhlciBhbmlt
YWxzLCB3aGljaCBpcyBhIGx1c3Qgb2YgdGhlIG1pbmQsIHRoYXQgYnkgYSBw
ZXJzZXZlcmFuY2Ugb2YgZGVsaWdodCBpbiB0aGUgY29udGludWVkIGFuZCBp
bmRlZmF0aWdhYmxlIGdlbmVyYXRpb24gb2Yga25vd2xlZGdlLCBleGNlZWRz
IHRoZSBzaG9ydCB2ZWhlbWVuY2Ugb2YgYW55IGNhcm5hbCBwbGVhc3VyZS4=
__BASE64

my $uuencode = <<'__UUENCODE';
M36%N(&ES(&1I<W1I;F=U:7-H960L(&YO="!O;FQY(&)Y(&AI<R!R96%S;VXL
M(&)U="!B>2!T:&ES('-I;F=U;&%R('!A<W-I;VX@9G)O;2!O=&AE<B!A;FEM
M86QS+"!W:&EC:"!I<R!A(&QU<W0@;V8@=&AE(&UI;F0L('1H870@8GD@82!P
M97)S979E<F%N8V4@;V8@9&5L:6=H="!I;B!T:&4@8V]N=&EN=65D(&%N9"!I
M;F1E9F%T:6=A8FQE(&=E;F5R871I;VX@;V8@:VYO=VQE9&=E+"!E>&-E961S
L('1H92!S:&]R="!V96AE;65N8V4@;V8@86YY(&-A<FYA;"!P;&5A<W5R92X`
__UUENCODE

subtest Synopsis => sub {
    subtest 'b64encode => b64touu => uuedecode' => sub {
        my $base64_string = &base64::b64encode($binary_string);
        is $base64_string, $base64;

        my $uuencode_string = &base64::b64touu($base64_string);
        is $uuencode_string, $uuencode;

        is &base64::uudecode($uuencode_string), $binary_string;
    };

    subtest 'uuencode => uutob64 => b64decode' => sub {
        my $uuencode_string = &base64::uuencode($binary_string);
        is $uuencode_string, $uuencode;

        my $base64_string = &base64::uutob64($uuencode_string);
        is $base64_string, $base64;

        is &base64::b64decode($base64_string), $binary_string;
    };
};

done_testing;
