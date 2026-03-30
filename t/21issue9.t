#!/usr/local/bin/perl

#
# Regression test for issue #9:
# Encoding garbled when 'use encoding' is in effect.
#
# Root cause: _encode.pm only imported 'bytes' on old Perl (< 5.007).
# On modern Perl, 'use encoding' is not lexically scoped and affects chr()
# globally. Without 'use bytes' in _encode.pm, length() and string ops
# could behave unexpectedly when the buffer or input strings have the utf8 flag.
#
# Fix: import 'bytes' unconditionally in _encode.pm (matching _decode.pm).
#

use strict;
use warnings;
use Convert::ASN1;
use Test::More tests => 12;

my $asn = Convert::ASN1->new;

# --- INTEGER with high bytes ---

ok($asn->prepare('n INTEGER'), 'prepare INTEGER schema');

# INTEGER 200: tag=02, length=02, value=00 C8
my $expected = pack('C*', 0x02, 0x02, 0x00, 0xC8);
my $encoded = $asn->encode(n => 200);
ok(defined $encoded, 'encode integer 200 succeeds') or diag($asn->error);
is($encoded, $expected, 'integer 200 encodes to correct binary')
    or diag('got: ' . unpack('H*', $encoded) . '  want: ' . unpack('H*', $expected));

# Verify round-trip
my $decoded = $asn->decode($encoded);
ok(defined $decoded, 'decode succeeds');
is($decoded->{n}, 200, 'decoded integer matches original');

# --- OCTET STRING with high bytes ---

ok($asn->prepare('s OCTET STRING'), 'prepare OCTET STRING schema');

# A byte string with bytes > 127 — must not be utf8-re-encoded
my $byte_str = "\xC8\xC9\xCA";   # bytes 200, 201, 202
my $str_encoded = $asn->encode(s => $byte_str);
my $expected_str = pack('C*', 0x04, 0x03, 0xC8, 0xC9, 0xCA);
ok(defined $str_encoded, 'encode string with high bytes succeeds') or diag($asn->error);
is($str_encoded, $expected_str, 'string with high bytes encodes correctly (not utf8-expanded)')
    or diag('got: ' . unpack('H*', $str_encoded) . '  want: ' . unpack('H*', $expected_str));
is(length($str_encoded), 5, 'encoded length is 5 bytes (not utf8-expanded)');

# --- SEQUENCE with high-byte values: exercises substr() path in _enc_sequence ---

ok($asn->prepare('r SEQUENCE { n INTEGER, s OCTET STRING }'), 'prepare SEQUENCE schema');
my $seq_encoded = $asn->encode(r => { n => 200, s => "\xC8" });
ok(defined $seq_encoded, 'sequence encode succeeds') or diag($asn->error);

# Decode and verify no corruption
my $seq_decoded = $asn->decode($seq_encoded);
ok(defined $seq_decoded, 'sequence decode succeeds') or diag($asn->error);
