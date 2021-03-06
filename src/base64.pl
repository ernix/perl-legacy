package base64;
#
# base64.pl -- A perl package to handle MIME-style BASE64 encoding
# A. P. Barrett <barrett@ee.und.ac.za>, October 1993
# $Revision: 1.2 $$Date: 1993/11/01 12:12:29 $
#
# Synopsis:
#       require 'base64.pl';
#
#       $uuencode_string = &base64'b64touu($base64_string);
#       $binary_string = &base64'b64decode($base64_string);
#       $base64_string = &base64'uutob64($uuencode_string);
#       $base64_string = &base64'b64encode($binary_string);
#       $uuencode_string = &base64'uuencode($binary_string);
#       $binary_string = &base64'uudecode($uuencode_string);
#
#       uuencode and base64 input strings may contain multiple lines,
#       but may not contain any headers or trailers.  (For uuencode,
#       remove the begin and end lines, and for base64, remove the MIME
#       headers and boundaries.)
#
#       uuencode and base64 output strings will be contain multiple
#       lines if appropriate, but will not contain any headers or
#       trailers.  (For uuencode, add the "begin" line and the
#       " \nend\n" afterwards, and for base64, add any MIME stuff
#       afterwards.)

####################

$base64_alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.
                   'abcdefghijklmnopqrstuvwxyz'.
                   '0123456789+/';
$base64_pad = '=';

$uuencode_alphabet = q|`!"#$%&'()*+,-./0123456789:;<=>?|.
                      '@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_'; # double that '\\'!
$uuencode_pad = '`';

# Build some strings for use in tr/// commands.
# Some uuencodes use " " and some use "`", so we handle both.
# We also need to protect backslashes.
($tr_uuencode = " ".$uuencode_alphabet) =~ s/\\/\\\\/;
$tr_base64 = "A".$base64_alphabet;


sub b64touu
{
    local ($_) = @_;
    local ($result);
    
    # zap bad characters and translate others to uuencode alphabet
    eval qq{
	tr|$tr_base64||cd;
	tr|$tr_base64|$tr_uuencode|;
    };

    # break into lines of 60 encoded chars, prepending "M" for uuencode
    while (s/^(.{60})//) {
	$result .= "M" . $& . "\n";
    }

    # any leftover chars go onto a shorter line
    # with padding to the next multiple of 4 chars
    if ($_ ne "") {
	$result .= substr($uuencode_alphabet, length($_)*3/4, 1)
		   . $_
		   . ($uuencode_pad x ((60 - length($_)) % 4)) . "\n";
    }

    # return result
    $result;
}

sub b64decode
{
    local ($_) = @_;
    local ($result);
    
    # zap bad characters and translate others to uuencode alphabet
    eval qq{
	tr|$tr_base64||cd;
	tr|$tr_base64|$tr_uuencode|;
    };

    # break into lines of 60 encoded chars, prepending "M" for uuencode,
    # and then using perl's builtin uudecoder to convert to binary.
    while (s/^(.{60})//) {
	#warn "chunk :$&:\n";
	$result .= unpack("u", "M" . $&);
    }

    # also decode any leftover chars
    if ($_ ne "") {
	#warn "last chunk :$_:\n";
	$result .= unpack("u",
		    substr($uuencode_alphabet, length($_)*3/4, 1) . $_);
    }

    # return result
    $result;
}

sub uutob64
{
    local ($_) = @_;
    local ($result);
    
    # This is the most difficult, because some perverse uuencoder
    # might have made lines that do not describe multiples of 3 bytes.
    # I don't see any better method than uudecoding to binary and then
    # b64encoding the binary.

    &b64encode(&uudecode); # implicitly pass @_ to &uudecode
}

sub b64encode
{
    local ($_) = @_;
    local ($chunk);
    local ($result);
    
    # break into chunks of 45 input chars, use perl's builtin
    # uuencoder to convert each chunk to uuencode format,
    # then kill the leading "M", translate to the base64 alphabet,
    # and finally append a newline.
    while (s/^((.|\n){45})//) {
	#warn "in:$&:\n";
	$chunk = substr(pack("u", $&), $[+1, 60);
	#warn "packed    :$chunk:\n";
	eval qq{
	    \$chunk =~ tr|$tr_uuencode|$tr_base64|;
	};
	#warn "translated:$chunk:\n";
	$result .= $chunk . "\n";
    }

    # any leftover chars go onto a shorter line
    # with uuencode padding converted to base64 padding
    if ($_ ne "") {
	#warn "length ".length($_)." \$_:$_:\n";
	#warn "enclen ", int((length($_)+2)/3)*4 - (45-length($_))%3, "\n";
	$chunk = substr(pack("u", $_), $[+1,
			int((length($_)+2)/3)*4 - (45-length($_))%3);
	#warn "chunk:$chunk:\n";
	eval qq{
	    \$chunk =~ tr|$tr_uuencode|$tr_base64|;
	};
	#warn "translated:$chunk:\n";
	$result .= $chunk . ($base64_pad x ((60 - length($chunk)) % 4)) . "\n";
    }

    # return result
    $result;
}

sub uuencode
{
    local ($_) = @_;
    local ($result);
    
    # break into chunks of 45 input chars, and use perl's builtin
    # uuencoder to convert each chunk to uuencode format.
    # (newline is added by builtin uuencoder.)
    while (s/^((.|\n){45})//) {
	$result .= pack("u", $&);
    }

    # any leftover chars go onto a shorter line
    # with padding to the next multiple of 4 chars
    if ($_ ne "") {
	$result .= pack("u", $_);
    }

    # return result
    $result;
}

sub uudecode
{
    local ($_) = @_;
    local ($result);
    
    # use perl's builtin uudecoder to convert each line
    while (s/^([^\n]+\n?)//) {
	$result .= unpack("u", $&);
    }

    # return result
    $result;
}

1;
