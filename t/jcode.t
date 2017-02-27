use strict;
use warnings;
use Test::More;
use utf8;
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
                    local (*f, $::icode) = &jcode'convert(*s, $jcode);
                    is decode($JE_TABLE{$jcode}, $::s), $word;

                    $::s = encode $code => $word;
                    &f(*::s);
                    is decode($JE_TABLE{$jcode}, $::s), $word;

                    is $::icode, $EJ_TABLE{$code};
                };

                subtest the_safest_way_conversion => sub {
                    local $::s = encode $code => $word;
                    local ($::matched, $::icode) = &jcode'getcode(*s);
                    ok defined $::matched;
                    is $::icode, $EJ_TABLE{$code};
                };
            }
        }
    }
};

done_testing;
