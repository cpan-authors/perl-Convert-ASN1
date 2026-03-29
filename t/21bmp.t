#!/usr/local/bin/perl

#
# Test BMPString (UCS-2BE) encoding and decoding
# Fixes: https://github.com/gbarr/Convert-ASN1/issues/29
#

use Convert::ASN1;
BEGIN { require './t/funcs.pl' }

if ($] < 5.007) {
  print "1..0\n";
  exit;
}

print "1..14\n";

# Prepare a BMPString schema
btest 1, my $asn = Convert::ASN1->new() or warn $asn->error;
btest 2, $asn->prepare(q(
    str BMPString
)) or warn $asn->error;

# Test 1: Encode ASCII text as BMPString (each ASCII char becomes 2 bytes in UCS-2BE)
my $encoded = $asn->encode(str => "ABC");
# BMPString tag = 0x1e (UNIVERSAL 30), length = 6, data = \x00A\x00B\x00C
my $expected = pack("C*", 0x1e, 0x06, 0x00, 0x41, 0x00, 0x42, 0x00, 0x43);
stest 3, $expected, $encoded or warn $asn->error;

# Test 2: Decode BMPString back to Perl string
btest 4, my $ret = $asn->decode($expected) or warn $asn->error;
stest 5, "ABC", $ret->{str};

# Test 3: Round-trip with non-ASCII BMP characters (e.g., U+00E9 = e-acute)
my $str_with_accent = "caf\x{e9}";
$encoded = $asn->encode(str => $str_with_accent);
btest 6, defined $encoded or warn $asn->error;
btest 7, $ret = $asn->decode($encoded) or warn $asn->error;
stest 8, $str_with_accent, $ret->{str};

# Test 4: Round-trip with CJK character (U+4E16 = 'world' in Chinese)
my $cjk = "\x{4e16}\x{754c}";
$encoded = $asn->encode(str => $cjk);
btest 9, defined $encoded or warn $asn->error;
btest 10, $ret = $asn->decode($encoded) or warn $asn->error;
stest 11, $cjk, $ret->{str};

# Test 5: Decode raw UCS-2BE bytes (simulating what Microsoft CSRs produce)
# "\x00A\x00B\x00C" in UCS-2BE = "ABC"
my $raw_bmp = pack("C*",
  0x1e, 0x06,             # tag + length
  0x00, 0x41,             # 'A'
  0x00, 0x42,             # 'B'
  0x00, 0x43,             # 'C'
);
btest 12, $ret = $asn->decode($raw_bmp) or warn $asn->error;
stest 13, "ABC", $ret->{str};
# Verify the decoded value is a proper Perl character string
ntest 14, 3, length($ret->{str});
