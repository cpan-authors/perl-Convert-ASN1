#!/usr/local/bin/perl

#
# Test that constructed (indefinite-length) primitive values with implicit tags
# can be decoded correctly (GitHub issue #35).
#
# X.690 specifies:
#   8.6.4.1: BIT STRING inner segments use UNIVERSAL tag 3 (BIT STRING)
#   8.7.3.2: OCTET STRING inner segments use UNIVERSAL tag 4 (OCTET STRING)
#   8.23.3:  other string types (UTF8String, etc.) inner segments use OCTET STRING (tag 4)
#

BEGIN { require './t/funcs.pl' }

use Convert::ASN1;

print "1..8\n";

btest 1, my $asn = Convert::ASN1->new or warn $asn->error;
btest 2, $asn->prepare(q(
  v ::= SEQUENCE { d [0] IMPLICIT OCTET STRING }
)) or warn $asn->error;

# Data from issue #35:
#   30 80          -- SEQUENCE, indefinite length
#     a0 80        -- [0] CONSTRUCTED, indefinite length  (implicit tag for OCTET STRING)
#       04 06      -- OCTET STRING, length 6
#         48656c6c6f20  -- "Hello "
#       04 06      -- OCTET STRING, length 6
#         576f726c6421  -- "World!"
#       00 00      -- EOC for [0]
#     00 00        -- EOC for SEQUENCE
my $buf = "\x30\x80\xa0\x80\x04\x06Hello \x04\x06World!\x00\x00\x00\x00";

my $d = $asn->decode($buf);
btest 3, defined $d or warn $asn->error;
stest 4, 'Hello World!', $d->{d};

# Same schema, but value encoded as primitive (non-constructed) -- must still work
my $buf2 = "\x30\x09\x80\x07goodbye";
my $d2 = $asn->decode($buf2);
btest 5, defined $d2 or warn $asn->error;
stest 6, 'goodbye', $d2->{d};

# UTF8String with implicit tag, constructed indefinite encoding.
# Inner segments are OCTET STRING (tag 0x04) per X.690 8.23.3.
btest 7, $asn->prepare(q(
  u ::= SEQUENCE { s [1] IMPLICIT UTF8String }
)) or warn $asn->error;

#   30 80          -- SEQUENCE, indefinite length
#     a1 80        -- [1] CONSTRUCTED, indefinite length
#       04 05      -- OCTET STRING (inner segment), length 5
#         48656c6c6f  -- "Hello"
#       04 01      -- OCTET STRING (inner segment), length 1
#         21        -- "!"
#       00 00      -- EOC for [1]
#     00 00        -- EOC for SEQUENCE
my $buf3 = "\x30\x80\xa1\x80\x04\x05Hello\x04\x01!\x00\x00\x00\x00";

my $u = $asn->decode($buf3);
btest 8, defined($u) && $u->{s} eq 'Hello!' or warn($asn->error // '') . " got " . (defined $u ? $u->{s} // 'undef' : 'undef');
