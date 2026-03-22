#!/usr/local/bin/perl

#
# Test BMPString and UniversalString decoding/encoding
# BMPString is UCS-2 Big Endian; UniversalString is UCS-4 Big Endian
#

use Convert::ASN1;
BEGIN { require './t/funcs.pl' }

if ($] < 5.007) {
  print "1..0\n";
  exit;
}

print "1..18\n";

my ($asn, $ret, $result);

##
## BMPString: decode UCS-2-BE bytes -> Perl string
##

# "ABC" in UCS-2-BE: \x00\x41 \x00\x42 \x00\x43
# BMPString tag = 0x1e, length = 6
btest 1, $asn = Convert::ASN1->new() or warn $asn->error;
btest 2, $asn->prepare(q( str BMPString )) or warn $asn->error;

$result = pack("C*", 0x1e, 0x06, 0x00, 0x41, 0x00, 0x42, 0x00, 0x43);
btest 3, $ret = $asn->decode($result) or warn $asn->error;
stest 4, "ABC", $ret->{str};

# Verify result is a proper Perl string (length should be 3 chars, not 6 bytes)
ntest 5, 3, length($ret->{str});

##
## BMPString: encode Perl string -> UCS-2-BE bytes
##

stest 6, $result, $asn->encode(str => "ABC") or warn $asn->error;

##
## BMPString with non-ASCII characters
##

# U+00E9 (e-acute) in UCS-2-BE = \x00\xE9
# U+4E2D (CJK character) in UCS-2-BE = \x4E\x2D
my $unicode_str = chr(0xE9) . chr(0x4E2D);
my $ucs2_bytes = pack("n*", 0x00E9, 0x4E2D);
my $bmpstring_encoded = pack("C", 0x1e) . pack("C", length($ucs2_bytes)) . $ucs2_bytes;

stest 7, $bmpstring_encoded, $asn->encode(str => $unicode_str) or warn $asn->error;

btest 8, $ret = $asn->decode($bmpstring_encoded) or warn $asn->error;
stest 9, $unicode_str, $ret->{str};

##
## BMPString: empty string round-trip
##

$result = pack("C*", 0x1e, 0x00);
btest 10, $ret = $asn->decode($result) or warn $asn->error;
stest 11, "", $ret->{str};
stest 12, $result, $asn->encode(str => "") or warn $asn->error;

##
## UniversalString: decode UCS-4-BE bytes -> Perl string
##

# "AB" in UCS-4-BE: \x00\x00\x00\x41 \x00\x00\x00\x42
# UniversalString tag = 0x1c, length = 8
btest 13, $asn->prepare(q( str UniversalString )) or warn $asn->error;

$result = pack("C*", 0x1c, 0x08, 0x00, 0x00, 0x00, 0x41, 0x00, 0x00, 0x00, 0x42);
btest 14, $ret = $asn->decode($result) or warn $asn->error;
stest 15, "AB", $ret->{str};

# Verify result is a proper Perl string (length should be 2 chars, not 8 bytes)
ntest 16, 2, length($ret->{str});

##
## UniversalString: encode Perl string -> UCS-4-BE bytes
##

stest 17, $result, $asn->encode(str => "AB") or warn $asn->error;

##
## BMPString round-trip via DirectoryString CHOICE (realistic X.509 use case)
##

btest 18, $asn->prepare(q(
  DirectoryString ::= CHOICE {
    printableString  PrintableString,
    bmpString        BMPString,
    utf8String       UTF8String
  }
)) or warn $asn->error;
