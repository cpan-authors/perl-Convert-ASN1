#!/usr/local/bin/perl

#
# Test XS extension loading and the XS implementations of
# asn_encode_tag, asn_encode_length, asn_decode_tag, asn_decode_tag2,
# asn_decode_length, and num_length.
#

use Convert::ASN1 qw(:tag :const);
BEGIN { require './t/funcs.pl' }

print "1..28\n";

# --- num_length (internal, accessed via package name) ---
ntest 1, 1, Convert::ASN1::num_length(0);
ntest 2, 1, Convert::ASN1::num_length(127);
ntest 3, 1, Convert::ASN1::num_length(255);
ntest 4, 2, Convert::ASN1::num_length(256);
ntest 5, 2, Convert::ASN1::num_length(65535);
ntest 6, 3, Convert::ASN1::num_length(65536);
ntest 7, 3, Convert::ASN1::num_length(16777215);
ntest 8, 4, Convert::ASN1::num_length(16777216);

# --- asn_encode_length ---
# Short form: values 0-127 encode as a single byte
stest  9, pack("C", 0),   asn_encode_length(0);
stest 10, pack("C", 1),   asn_encode_length(1);
stest 11, pack("C", 127), asn_encode_length(127);

# Long form: 128+ encode as 0x80|n followed by n big-endian bytes
stest 12, pack("C2", 0x81, 128),        asn_encode_length(128);
stest 13, pack("C2", 0x81, 255),        asn_encode_length(255);
stest 14, pack("C3", 0x82, 0x01, 0x00), asn_encode_length(256);
stest 15, pack("C3", 0x82, 0xff, 0xff), asn_encode_length(65535);

# --- asn_decode_length ---
# Short form
my @r = asn_decode_length(pack("C", 5));
ntest 16, 1, $r[0];
ntest 17, 5, $r[1];

# Long form: 0x82 0x01 0x00 => length 256, consumed 3 bytes
@r = asn_decode_length(pack("C3", 0x82, 0x01, 0x00));
ntest 18, 3, $r[0];
ntest 19, 256, $r[1];

# Indefinite length: 0x80 => returns (1, -1)
@r = asn_decode_length(pack("C", 0x80));
ntest 20, 1, $r[0];
ntest 21, -1, $r[1];

# --- asn_encode_tag / asn_decode_tag roundtrip ---
# Single-byte tag (BOOLEAN = 0x01)
my $bool_tag = asn_tag(ASN_UNIVERSAL, ASN_BOOLEAN);
my $encoded = asn_encode_tag($bool_tag);
stest 22, pack("C", 0x01), $encoded;

@r = asn_decode_tag($encoded);
ntest 23, 1, $r[0];     # 1 byte consumed
ntest 24, 0x01, $r[1];  # tag value

# Two-byte tag: CONTEXT [31] (requires extension byte 0x1f)
my $ctx31_tag = asn_tag(ASN_CONTEXT, 31);
$encoded = asn_encode_tag($ctx31_tag);
ntest 25, 2, length($encoded);

@r = asn_decode_tag($encoded);
ntest 26, 2, $r[0];     # 2 bytes consumed
ntest 27, unpack("v", $encoded), $r[1];

# --- asn_decode_tag2 ---
@r = asn_decode_tag2(pack("C", 0x01));
ntest 28, 3, scalar(@r);  # returns 3 values: (len, raw_tag, tag_num)
