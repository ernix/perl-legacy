package stdio;
;###############################################################
;#
;# <stdio.pl> CGI STandarD Input Output - Perl Library.
;#   Version 7.56 (Updated at October 6, 2001)
;#   Copyright(C)1999-2001 WEB POWER. All Rights Reserved.
;#   The latest programs are found at <http://www-power.net/>
;#
;#  - 著作権は放棄していませんが、配布・転載・改造は自由です。
;#  - 改造物を配布する場合、必ず改造物のファイル名とパッケージ
;#    名を変更して、改造物であることを明記してください。
;#  - 関数のリファレンス等は上記URIを参照してください。
;#  - ライブラリの一切の動作保証はしません。また、運用結果につ
;#    いていかなる責任も負いません。
;#
;###############################################################

;$ver = q$stdio.pl;7.56;October 6, 2001$;
;$cpy = 'Auther: Program by (C)2001 WEB POWER (http://www-power.net/)';
;$max = 1048576; # maximum bytes to accept via POST - 128KB(2^17=131072)
srand(time ^ ($$ + ($$ << 15)) || time);

;# ============================
;# Set/Get Cookie.
;# ============================

sub setCookie #($cookie_name, *cookie_body, $return_value, $expires, $path, $domain, $secure)
{
  local($cookie_name, *cookie_body, $return_value, $expires, $path, $domain, $secure) = @_;
  local($cookie);

  if (%cookie_body) {
    local(@cookie);
    while(local($key, $val) = each %cookie_body) {
      &urlencode(*val);
      push @cookie, "$key=$val";
    }
    $cookie = join "&", @cookie;
  } elsif ($cookie_body) {
    $cookie = $cookie_body;
  }
  if ($expires == -1) {
    $expires = '; expires=Mon, 01-Jan-1990 00:00:00 GMT';
  } elsif ($expires =~ /^\d+$/) {
    local(@gmtime) = split / +/, scalar gmtime(time + $expires);
    $expires = "; expires=$gmtime[0], $gmtime[2]-$gmtime[1]-$gmtime[4] $gmtime[3] GMT";
  } elsif ($expires) {
    $expires = "; expires=$expires";
  }
  $domain = "; domain=$domain" if ($domain);
  $path   = "; path=$path" if ($path);
  $secure = "; secure"  if ($secure);
  return "$cookie_name=$cookie$expires$path$domain$secure" if ($return_value);
  print "Set-Cookie: $cookie_name=$cookie$expires$path$domain$secure\n";
  return;
}

sub getCookie #($cookie_name, *COOKIE)
{
  local($cookie_name, *COOKIE) = @_;
  local(@array);

  foreach (split /;/o, $ENV{'HTTP_COOKIE'}) {
    local($key, $val) = split /=/o, $_, 2;
    $key =~ tr/ \r\n\t//d;
    if ($key eq $cookie_name) {
      foreach (split /&/, $val) {
        local($key, $val) = split /=/o, $_, 2;
        $val =~ tr/+/ /;
        $val =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex $1)/eg;
        $COOKIE{$key} = $val;
        push @array, $key;
      }
      return @array;
    }
  }
  return;
}

;# ============================
;# Get day & time.
;# ============================

sub getTime #($time_format, $time_difference, $base_time)
{
  local($_, $time_difference, $base_time) = @_;
  local(@time);

  $base_time = time if ($base_time eq "");
  if ($_) {
    @time = gmtime($base_time + $time_difference);
  } else {
    return scalar gmtime($base_time + $time_difference);
  }
  s/mm/sprintf("%02d",$time[4]+1)/eg;
  s/m/$time[4]+1/eg;
  s/yyyy/$time[5]+1900/eg;
  s/yyy/$time[5]-88/eg;
  s/yy/substr($time[5]+1900, 2, 2)/eg;
  s/y/substr($time[5]+1900, 3, 1)/eg;
  s/dd/sprintf("%02d",$time[3])/eg;
  s/d/$time[3]/g;
  s/hh/sprintf("%02d",$time[2])/eg;
  s/h/$time[2]/g;
  s/nn/sprintf("%02d",$time[1])/eg;
  s/n/$time[1]/eg;
  s/ss/sprintf("%02d",$time[0])/eg;
  s/s/$time[0]/eg;
  s/ww4/$time[6]/g;

  if ($time[2] <= 12) {
    $time[7] = $time[2];
    s/ap3/午前/gi;
    s/ap2/am/gi;
    s/ap/AM/gi;
  } else {
    $time[7] = $time[2] - 12;
    s/ap3/午後/gi;
    s/ap2/pm/gi;
    s/ap/PM/gi;
  }
  s/HH/sprintf("%02d",$time[7])/eg;
  s/H/$time[7]/g;
  if (/ww2/) {
    local(@week) = ('Sun','Mon','Tue','Wed','Thu','Fri','Sat');
    s/ww2/$week[$time[6]]/g;
  }
  if (/ww3/) {
    local(@week) = ('Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday');
    s/ww3/$week[$time[6]]/g;
  }
  if (/ww/) {
    local(@week) = ('日','月','火','水','木','金','土');
    s/ww/$week[$time[6]]/g;
  }
  if (/MM2/) {
    local(@month) = ('January','Februay','March','April','May','June','July','August','September','October','November','December');
    s/MM2/$month[$time[4]]/g;
  }
  if (/MM/) {
    local(@month) = ('Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec');
    s/MM/$month[$time[4]]/g;
  }
  return $_;
}

;# ============================
;# Get STDIN Data & Decode.
;# ============================

sub getFormData #(*IN, $tr_tags, $jcode, $h2z, $multi_keys, $file_dir)
{
  return &getMultipartFormData(@_) if ($ENV{'CONTENT_TYPE'} =~ /^multipart\/form-data;/i);

  local(*IN, $tr_tags, $jcode, $h2z, $multi_keys) = @_;
  local($buffer, @array);

  if ($ENV{'CONTENT_LENGTH'} > $max) {
    return;
  } elsif ($ENV{'REQUEST_METHOD'} eq 'POST') {
    read STDIN, $buffer, $ENV{'CONTENT_LENGTH'};
  } else {
    $buffer = $ENV{'QUERY_STRING'};
  }
  return if ($buffer eq "");
  foreach (split /[&;]/o, $buffer) {
    local($key, $val) = split /=/, $_, 2;
    $key =~ tr/+/ /;
    $val =~ tr/+/ /;
    $key =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex $1)/eg;
    $val =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex $1)/eg;
    if ($h2z && $jcode && $jcode'version) {
      if ($jcode eq 'sjis') {
        &jcode'h2z_sjis(*val);
      } elsif ($jcode eq 'jis') {
        &jcode'h2z_jis(*val);
      } elsif ($jcode eq 'euc') {
        &jcode'h2z_euc(*val);
      }
    }
    if ($jcode && $jcode'version) {
      &jcode'convert(*key, $jcode);
      &jcode'convert(*val, $jcode);
    }
    $key =~ s/\r\n|\r/\n/g;
    $val =~ s/\r\n|\r/\n/g;
    $key =~ tr/\t\a\b\e\f//d;
    $val =~ tr/\t\a\b\e\f//d;
    if ($tr_tags) {
      $val =~ s/&/&amp;/g;
      $val =~ s/"/&quot;/g;
      $val =~ s/</&lt;/g;
      $val =~ s/>/&gt;/g;
#      $val =~ s/\n/<br \/>/g;
      $val =~ s/\n//g;
      $val =~ s/,//g;
    }
    if ($multi_keys) {
      $IN{$key} .= $IN{$key} ne "" ? "$multi_keys$val" : $val;
    } else {
      $IN{$key} = $val;
    }
    push @array, $key;
  }
  return @array;
}

sub getMultipartFormData #(*IN, $tr_tags, $jcode, $h2z, $multi_keys, $file_dir)
{
  local(*IN, $tr_tags, $jcode, $h2z, $multi_keys, $file_dir) = @_;
  local($boundary, $key, $val, $path, $flag, $file, $text, $type, $open, $i, @array);

  if ($ENV{'CONTENT_LENGTH'} > $max) {
    return;
  } elsif ($ENV{'CONTENT_TYPE'} =~ /^multipart\/form-data; *boundary=(.+)/) {
    $boundary = $1;
  } else {
    return;
  }
  binmode STDIN;
  while (<STDIN>) {
    if ($flag == 2) {
      if (/^--$boundary/) {
        $val =~ s/\r\n$//;
        if ($text) {
          if ($h2z && $jcode && $jcode'version) {
            if ($jcode eq 'sjis') {
              &jcode'h2z_sjis(*val);
            } elsif ($jcode eq 'jis') {
              &jcode'h2z_jis(*val);
            } elsif ($jcode eq 'euc') {
              &jcode'h2z_euc(*val);
            }
          }
          if ($jcode && $jcode'version) {
            &jcode'convert(*key, $jcode);
            &jcode'convert(*val, $jcode);
          }
          $key =~ s/\r\n|\r/\n/g;
          $val =~ s/\r\n|\r/\n/g;
          $key =~ tr/\t\a\b\e\f//d;
          $val =~ tr/\t\a\b\e\f//d;
          if ($tr_tags) {
            $val =~ s/&/&amp;/g;
            $val =~ s/"/&quot;/g;
            $val =~ s/</&lt;/g;
            $val =~ s/>/&gt;/g;
#            $val =~ s/\n/<br \/>/g;
            $val =~ s/\n//g;
          }
        }
        push @array, $key;
        if ($text && $multi_keys) {
          $IN{$key} .= $IN{$key} ne "" ? "$multi_keys$val" : $val;
        } else {
          if ($open) {
            close OUT;
            push @file, $file;
            $IN{"$key->size"} = (-s $file);
            $IN{$key} = $file;
          } else {
            $IN{$key} = $val;
            $IN{"$key->size"} = length $val;
          }
          $IN{"$key->path"} = $path;
          $IN{"$key->name"} = $1 if ($path =~ /([^\\\/]+)$/);
          $IN{"$key->type"} = $type;
        }
        ($text, $type, $flag, $path, $open, $file, $key, $val) = undef;
        last if (/--\r\n$/);
      } elsif ($open) {
          print OUT;
      } else {
        $val .= $_;
      }
    } elsif ($flag && !$text && /^Content-Type: *([^\r\n]+)/i) {
      $type = $1;
    } elsif ($flag && /^\r\n$/) {
      $flag = 2;
    } elsif (/^Content-Disposition: *([^;]*); *name="([^;]*)"; *filename="([^;]*)"/i) {
      $key  = $2;
      $path = $3;
      $flag = 1;
      if ($path ne "" && $file_dir ne "" && $IN{"$key->path"} eq "") {
        $i ++;
        $file = sprintf "$file_dir%d.$i.tmp", $$+time;
        if (open OUT, ">$file") {
          binmode OUT;
          $open = 1;
        }
      }
    } elsif (/^Content-Disposition: *([^;]*); *name="([^;]*)"/i) {
      $key  = $2;
      $flag = 1;
      $text = 1;
    }
  }
  return @array;
}

;# ============================
;# Send Email.
;# ============================

sub sendmail #($sendmail, *header, $body, $html_mail, $mime_encode, @attachment_files)
{
  local($sendmail, *header, $body, $html_mail, $mime_encode, @attachment_files) = @_;
  local($boundary);

  return 0 if (!open ML, "| $sendmail -t -i");
  while (local($key, $val) = each %header) {
    &encode(*val);
    print ML "$key: $val\n";
  }
  print ML "Content-Transfer-Encoding: 7bit\n";
  if (@attachment_files) {
    $boundary = '===' . time . time . '===';
    print ML qq(Content-Type: multipart/mixed; boundary="$boundary"\n\n)
           . "This is multipart message.\n\n"
           . "--$boundary\n";
  }
  print ML "Content-Type: text/";
  print ML $html_mail ? 'html' : 'plain';
  print ML qq(; charset="ISO-2022-JP"\n\n);
  &jcode'convert(*body, 'jis') if ($jcode'version);
  print ML $body . "\n";
  if (@attachment_files) {
    foreach $file (@attachment_files) {
      local($file, $type, $name, $encode) = split /;/, $file;
      if (open IN, $file) {
        local($file_size) = (-s $file);
        binmode IN;
        $encode = $mime_encode if ($encode eq "");
        $name = (!$name && $file =~ /([^\/]+$)/) ? $1 : $name;
        $type = 'application/octet-stream' if (!$type);
        print ML "--$boundary\n";
        print ML qq(Content-Type: $type; name="$name"\n);
        if ($encode == 1 || $encode =~ /^uuencode$/i) {
          local($read, $buffer);
          print ML "Content-Transfer-Encoding: X-uuencode\n";
          print ML qq(Content-Disposition: attachment; filename="$name"\n\n);
          print ML "begin 666 $name\n";
          while ($read = read IN, $buffer, 1035) {
            local($data);
            while ($buffer =~ s/^((.|\n|\r){45})//) {
              $data .= pack("u", $&);
            }
            if ($read == 1035) {
              print ML $data;
              next;
            }
            print ML $data;
            print ML pack("u", $buffer) if ($buffer ne "");
          }
          print ML "`\n"
                 . "end\n";
        } else {
          local($base, $read, $buffer, $j);
          $base = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
          $j = 1;
          print ML "Content-Transfer-Encoding: Base64\n";
          print ML qq(Content-Disposition: attachment; filename="$name"\n\n);
          while ($read = read IN, $buffer, 1026) {
            local($data, $length, $i);
            $i = $length = 0;
            $buffer = unpack "B*", $buffer;
            while ($length = substr($buffer, $i, 6)) {
              $data .= substr($base, ord pack("B*", "00".$length), 1);
              if ($read != 1026 || tell(IN) == $file_size) {
                if (length $length == 2) {
                  $data .= "==";
                } elsif (length $length == 4) {
                  $data .= "=";
                }
              }
              $data .= "\n" if ($j++ % 76 == 0);
              $i += 6;
            }
            print ML $data;
          }
        }
        close IN;
        print ML "\n";
      }
    }
    print ML "--$boundary--\n";
  }
  close ML;
  return 1;
}

sub encode #(*data)
{
  local(*data) = @_;
  local($mail, $data2);

  $data =~ tr/\r\n//d;
  if ($data =~ /^(.+)\s+<([-+.\w]+@[-.A-Za-z0-9]*[-A-Za-z0-9]{2,23}\.[A-Za-z]{2,6})>$/i) {
    $data = $1;
    $mail = $2;
  }
  foreach (split / +/, $data) {
    if (/[^\x20-\x7e]/) {
      &jcode'convert(*_, 'jis') if ($jcode'version);
      &base64encode(*_);
      $data2 .= " =?ISO-2022-JP?B?$_?= ";
    } else {
      $data2 .= " $_ ";
    }
  }
  $data = $data2;
  $data =~ s/ {2,}/ /g;
  $data =~ s/^\s//g;
  $data =~ s/\s$//g;
  $data = "$data <$mail>" if ($mail ne "");
}

sub base64encode #(*data, $ins_lf)
{
  local(*data, $ins_lf) = @_;
  local($length, $result, $i, $j);
  local($base) = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

  $data = unpack "B*", $data;
  for ($i = 0, $j = 1; $length = substr($data, $i, 6); $i += 6, $j ++) {
    $result .= substr($base, ord(pack("B*", "00" . $length)), 1);
    if (length $length == 2) {
      $result .= "==";
    } elsif (length $length == 4) {
      $result .= "=";
    }
    $result .= "\n" if ($ins_lf && $j % $ins_lf == 0);
  }
  $data = $result;
}

sub urlencode #(*data)
{
  local(*data) = @_;

  $data =~ s/([^\w\-.* ])/sprintf('%%%02X', ord $1)/eg;
  $data =~ tr/ /+/;
}

;# ============================
;# Hash to String.
;# ============================

sub hash_to_string #(*hash, *array, $cut, $spl)
{
  local(*hash, *array, $cut, $spl) = @_;
  local($space, @query);

  $space = " " x ($spl - 1) if ($spl > 0);
  @array = sort keys %hash if (!@array);
  foreach $key (@array) {
    local($val) = $hash{$key};
    next if ($cut && $val eq "");
    if ($spl) {
      $val =~ s/\r/&#13;/g;
      $val =~ s/\n/&#10;/g;
      $val =~ s/</&lt;/g;
      $val =~ s/>/&gt;/g;
      push @query, qq|$space<input type="hidden" name="$key" value="$val" />|;
    } else {
      &urlencode(*val);
      push @query, "$key=$val";
    }
  }
  return $spl ? join "\n", @query : join ";", @query;
}

;# ============================
;# Inline Link.
;# ============================

sub inlineLink #(*data, $attribute, $uri_str, $mail_str)
{
  local(*data, $attribute, $uri_str, $mail_str) = @_;

  $data =~ tr/\a//d;
  $data =~ s/&amp;/\a/g;
  if ($uri_str) {
    $data =~ s/([^="',;>]|^)((https?|ftp|gopher|telnet|news|wais|nntp):\/\/[-+:.@\w]{5,60}\/[-.?+:;!#%=@~^\$\a\w\/\\]{0,128})/$1<a href=\"$2\" $attribute>$uri_str<\/a>/g;
  } else {
    $data =~ s/([^="',;>]|^)((https?|ftp|gopher|telnet|news|wais|nntp):\/\/[-+:.@\w]{5,60}\/[-.?+:;!#%=@~^\$\a\w\/\\]{0,128})/$1<a href=\"$2\" $attribute>$2<\/a>/g;
  }
  if ($mail_str) {
    $data =~ s/([^="',;>]|^)mailto:([-+.\w]{1,30}@[-+.\w]*[-A-Za-z0-9]{2,30}\.[A-Za-z]{2,6})\b/$1<a href="mailto:$2">$mail_str<\/a>/g;
  } else {
    $data =~ s/([^="',;>]|^)mailto:([-+.\w]{1,30}@[-+.\w]*[-A-Za-z0-9]{2,30}\.[A-Za-z]{2,6})\b/$1<a href="mailto:$2">mailto:$2<\/a>/g;
  }
  $data =~ s/\a/&amp;/g;
}

;# ============================
;# Search String.
;# ============================

sub searchString #($str, $key, $mhmode, $lc, $z2h, $k2h, $igmark)
{
  local($str, $key, $mhmode, $lc, $z2h, $k2h, $igmark) = @_;
  local($once, $from, $to);
  #static $key2, $key3;

  return 0 if ($str eq "" || $key eq "");
  if ($key eq $key2) {
    $key = $key3;
    $once = 1;
  } else {
    $key2 = $key;
  }
  if ($jcode'version) {
    if ($k2h) {
      $from = 'アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲンガギグゲゴザジズゼゾダヂヅデドバビブベボパピプペポゐゑァィゥェォャュョッ';
      $to   = 'あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわをんがぎぐげござじずぜぞだぢづでどばびぶべぼぱぴぷぺぽヰヱぁぃぅぇぉゃゅょっ';
    }
    if ($z2h) {
      $from .= '０１２３４５６７８９ＡＢＣＤＥＦＧＨＩＪＫＬＭＮＯＰＱＲＳＴＵＶＷＸＹＺａｂｃｄｅｆｇｈｉｊｋｌｍｎｏｐｑｒｓｔｕｖｗｘｙｚ＋－＝＿｜＊！？”＃＄￥％＆＠：；';
      $to   .= '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz+-=_|*!?"#$\%&@:;';
    }
    if ($igmark) {
      $from .= '－ー・／＿　';
      $to   .= '------';
    }
    if ($from) {
      &jcode'tr(*str, $from, $to);
      &jcode'tr(*key, $from, $to) if (!$once);
      $str =~ tr/-_\///d;
      $key =~ tr/-_\///d;
    }
  }
  if ($lc) {
    $str =~ tr/A-Z/a-z/;
    $key =~ tr/A-Z/a-z/ if (!$once);
  }
  $key3 = $key;
  if ($mhmode == 5 || $mhmode =~ /^BOOLEAN$/i || $mhmode =~ /^BLN$/i) {
    local($i) = 0;
    local(@str, $eval);
    $key =~ s/ +AND +/ & /gi;
    $key =~ s/ *NOT +/ ! /gi;
    $key =~ s/ +OR +/ | /gi;
    $key =~ s/\( +/(/g;
    $key =~ s/ +\)/)/g;
    foreach (split /( & | \| )/, $key) {
      $str[$i] .= $_;
      $i ++ unless ($_ eq ' & ' || $_ eq ' | ')
    }
    for ($i = 0; $i <= $#str; $i ++) {
      local($option, $open, $close, $find, $not, $key);
      $key = $str[$i];
      if ($str[$i] =~ /^( & | \| )/) {
        $option = substr $key, 0, 3;
        $key    = substr $key, 3;
      }
      $open  = $1 if ($key =~ /^(\(+)/g);
      $close = $1 if ($key =~ /(\)+)$/g);
      $key   =~ s/\(|\)//g;
      if ($key =~ /^ *! +/) {
        $key =~ s/^ *! +//g;
        $not = 1;
      }
      $find  = index($str, $key) >= 0 ? 1 : 0;
      $find  = $find ? 0 : 1 if ($not);
      $eval .= "$option$open$find$close";
    }
    $eval =~ s/ & /*/g;
    $eval =~ s/ \| /+/g;
    return (eval $eval >= 1) ? 1 : 0;
  } elsif ($mhmode == 4 || $mhmode =~ /^NOR$/i) {
    foreach (split / +/, $key) {
      return 0 if (index($str, $_) >= 0);
    }
    return 1;
  } elsif ($mhmode == 3 || $mhmode =~ /^EOR$/i) {
    local($flag) = 0;
    foreach (split / +/, $key) {
      if (index($str, $_) >= 0) {
        return 0 if ($flag);
        $flag = 1;
      }
    }
    return $flag ? 1 : 0;
  } elsif ($mhmode == 2 || $mhmode =~ /^OR$/i) {
    foreach (split / +/, $key) {
      return 1 if (index($str, $_) >= 0);
    }
    return 0;
  } elsif ($mhmode == 1 || $mhmode =~ /^NAND$/i) {
    foreach (split / +/, $key) {
      return 1 if (index($str, $_) == -1);
    }
    return 0;
  } else { 
    foreach (split / +/, $key) {
      return 0 if (index($str, $_) == -1);
    }
    return 1;
  }
}

;# ============================
;# Code string by crypt().
;# ============================

sub cryptString #($passwd)
{
  local($passwd) = @_;
  local($salt, $_);
  local(@string) = ('0'..'9','A'..'Z','a'..'z','.','/');

  return if ($passwd eq "");
  foreach (1 .. 12) {
    $salt .= $string[int(rand($#string+1))];
  }
  $_ = eval { crypt('Password', '$1$TST') };
  if ($@) {
    return $passwd;
  } elsif (/^\$1\$/) {
    return crypt($passwd, '$1$' . $salt);
  } else {
    return crypt($passwd, $salt);
  }
}

sub recryptString #($passwd1, $passwd2)
{
  local($passwd1, $passwd2) = @_;
  local($_) = eval { crypt($passwd1, $passwd2) };

  if ($passwd1 eq "" || $passwd2 eq "") {
    return 0;
  } elsif ($@) {
    return $passwd1 eq $passwd2 ? 1 : 0;
  } else {
    return $_ eq $passwd2 ? 1 : 0;
  }
}

;# ============================
;# Session Manage.
;# ============================

sub session #($file_name, $mode, $session_id, *hash, $expires)
{
  local($file_name, $mode, $session_id, *hash, $expires) = @_;
  local($temp_file) = $file_name . ".$$.tmp";
  local($flag, $retry) = 0;
  local(%hash2) = %hash;

  return 0 if ($file_name eq "" || ($mode eq "r" && !-f $file_name));
  %hash = () if ($mode eq "r" || $mode eq "rw" || $mode eq "ro");
  open OUT, ">$temp_file" || return -1;
  if (-s $file_name) {
    if (!open IN, $file_name) {
      unlink $temp_file;
      return -1;
    }
    while (<IN>) {
      tr/\r\n//d;
      local($session_id2, $expires2, @field) = split /\t/;
      if ($expires2 - time > 0) {
        if (!$flag && $session_id2 eq $session_id) {
          $flag = 1;
          if ($mode eq "r" || $mode eq "rw" || $mode eq "ro") {
            foreach (@field) {
              local($key, $val) = split /=/, $_, 2;
              $val =~ s/&#10;/\n/g;
              $val =~ s/&#13;/\r/g;
              $val =~ s/&#9;/\t/g;
              $val =~ s/&amp;/&/g;
              $hash{$key} = $val;
            }
            print OUT "$_\n" if ($mode ne "ro");
          } elsif ($mode eq "w") {
            print OUT "$_\n";
          }
        } else {
          print OUT "$_\n";
        }
      }
    }
    close IN;
  }
  if (%hash2 && ($mode eq "o" || ($mode eq "rw" && !$flag) || $mode eq "ro")) {
    local(@data);
    while (($key, $val) = each %hash2) {
      $val =~ s/&/&amp;/g;
      $val =~ s/\n/&#10;/g;
      $val =~ s/\r/&#13;/g;
      $val =~ s/\t/&#9;/g;
      push @data, "$key=$val";
    }
    $expires = $expires ? $expires + time : 3600 + time;
    print OUT "$session_id\t$expires\t" . join("\t", @data) . "\n";
  }
  close OUT;
  if (-s $temp_file) {
    while(rename $temp_file, $file_name) {
      if ($retry++ >= 3) {
        unlink $temp_file;
        return -2;
      }
    }
  } else {
    unlink $temp_file, $file_name;
  }
  return $flag;
}

;# ============================
;# Lock Check / Lock / Unlock
;# ============================

sub lockCheck #($file_name)
{
  local($file_name) = @_;
  local($lock_flag) = $file_name . ".lock";
  local($i) = 0;

  if (-d $lock_flag && time - (stat $lock_flag)[9] > 60) {
    rmdir $lock_flag;
    return 1;
  }
  while (-d $lock_flag) {
    select undef, undef, undef, 1;
    return 0 if (++ $i >= 3);
  }
  return 1;
}

sub lock #($file_name)
{
  local($file_name) = @_;
  local($lock_flag) = $file_name . ".lock";
  local($i) = 0;

  rmdir $lock_flag if (-d $lock_flag && time - (stat $lock_flag)[9] > 60);
  while(!mkdir $lock_flag, 0755) {
    select undef, undef, undef, 1;
    return 0 if (++ $i >= 3);
  }
  return 1;
}

sub unlock #($file_name)
{
  rmdir "$_[0].lock" if (-d "$_[0].lock");
}

;# ============================
;# Get Image Pixel Size.
;# ============================

sub getImageSize #($file_name)
{
  local($file_name) = @_;
  local($head);

  return -1 if (!-f $file_name);
  return -2 if (!open IN, $file_name);
  binmode IN;
  read IN, $head, 8;
  if ($head eq "\x89\x50\x4e\x47\x0d\x0a\x1a\x0a") {
    local(@pack);
    return "PNG", 0 if (read(IN, $head, 4) != 4 || read(IN, $head, 4) != 4 || $head ne 'IHDR');
    read IN, $head, 8;
    close IN;
    @pack = unpack "C8", $head;
    return "PNG", $pack[0] << 24 | $pack[1] << 16 | $pack[2] << 8 | $pack[3], $pack[4] << 24 | $pack[5] << 16 | $pack[6] << 8 | $pack[7];
  }
  $head = substr $head, 0, 3;
  if ($head eq "\x47\x49\x46") {
    local($head, $width, $height);
    seek IN, 6, 0;
    read IN, $head, 4;
    close IN;
    ($width, $height) = unpack "vv", $head;
    return "GIF", $width, $height;
  }
  $head = substr $head, 0, 2;
  if ($head eq "\xff\xd8") {
    local($head, $width, $height, $w1, $w2, $h1, $h2, $l1, $l2, $length);
    seek IN, 2, 0;
    while (read IN, $head, 1) {
      last if ($head eq "");
      if ($head eq "\xff") {
        $head = getc IN;
        if ($head =~ /^[\xc0-\xc3\xc5-\xcf]$/) {
          seek IN, 3, 1;
          last if (read(IN, $head, 4) != 4);
          ($h1, $h2, $w1, $w2) = unpack "C4", $head;
          $height = $h1 * 256 + $h2;
          $width  = $w1 * 256 + $w2;
          return "JPG", $width, $height;
        } elsif ($head eq "\xd9" || $head eq "\xda") {
          last;
        } else {
          last if (read(IN, $head, 2) != 2);
          ($l1, $l2) = unpack "CC", $head;
          $length = $l1 * 256 + $l2;
          seek IN, $length - 2, 1;
        }
      }
    }
    close IN;
    return "JPG", 0;
  }
  return 0;
}
1;
