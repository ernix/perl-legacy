use strict;
use warnings;
use utf8;
use open qw/:std :encoding(UTF-8)/;
use Test::More;
BEGIN {
    use_ok 'Encode';
    use_ok FindBin => qw($RealBin);
}

require_ok "$RealBin/../src/jcode.pl";

# jcode::getcode(\$line)
# jcode::convert(\$line, $ocode [, $icode [, $option]])
# jcode::xxx2yyy(\$line [, $option])
# &{$jcode::convf{'xxx', 'yyy'}}(\$line)
# jcode::to($ocode, $line [, $icode [, $option]])
# jcode::jis($line [, $icode [, $option]])
# jcode::euc($line [, $icode [, $option]])
# jcode::sjis($line [, $icode [, $option]])
# jcode::jis_inout($in, $out)
# jcode::get_inout($string)
# jcode::cache()
# jcode::nocache()
# jcode::flush()
# jcode::h2z_xxx(\$line)
# jcode::z2h_xxx(\$line)
# &{$jcode::z2hf{'xxx'}}(\$line)
# &{$jcode::h2zf{'xxx'}}(\$line)
# jcode::tr(\$line, $from, $to [, $option])
# jcode::trans($line, $from, $to [, $option)
# jcode::init()

our %EJ_TABLE = (
    'ISO-2022-JP' => 'jis',
    'Shift_JIS' => 'sjis',
    'EUC-JP' => 'euc',
);
our %JE_TABLE = reverse %EJ_TABLE;

subtest SAMPLES => sub {
    my @words = qw( 日本語テスト ほげほげ );

    for my $word (@words) {
        for my $code (keys %EJ_TABLE) {
            for my $jcode (values %EJ_TABLE) {
                subtest "convert_${code}_kanji_code_to_${jcode}" => sub {
                    local $::s = encode $code => $word;
                    local (*::f, $::icode) = &jcode'convert(*::s, $jcode);
                    is decode($JE_TABLE{$jcode}, $::s), $word;

                    $::s = encode $code => $word;
                    &f(*::s);
                    is decode($JE_TABLE{$jcode}, $::s), $word;

                    is $::icode, $EJ_TABLE{$code};
                };

                subtest the_safest_way_conversion => sub {
                    local $::s = encode $code => $word;
                    local ($::matched, $::icode) = &jcode'getcode(*::s);
                    ok defined $::matched;
                    is $::icode, $EJ_TABLE{$code};
                };
            }
        }
    }
};

subtest xxx2yyy => sub {
    for my $from (values %EJ_TABLE) {
        for my $to (values %EJ_TABLE) {
            for my $option (undef, 'z', 'h') {
                my $f = "${from}2${to}";
                subtest sprintf("%s_%s", $f, $option // q{}) => sub {
                    my $orig = "日本語テｽト";
                    local $::s = encode $JE_TABLE{$from} => $orig;

                    no strict 'refs';
                    my $bytes = &{"jcode'$f"}(*::s, $option);

                    my $out = decode $JE_TABLE{$to} => $::s;

                    my $expect = "日本語テｽト";
                    if ($from eq 'jis') {
                        $expect = "日本語テスト";  # buggy
                    }

                    if ($option) {
                        if ($option eq 'h') {
                            $expect = "日本語ﾃｽﾄ";
                        }
                        else {
                            $expect = "日本語テスト";
                        }
                    }

                    is $out, $expect;

                    # if ($bytes == 0) {
                    #     is $orig, $out; # buggy
                    # }
                };
            }
        }
    }
};

done_testing;
