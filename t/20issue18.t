#!/usr/bin/perl
use strict;
use warnings;

# Test: issue #18 - decode ASN INTEGER with large values (X.509 serial numbers)
#
# Large INTEGER values (> 4 bytes) should decode to usable Perl values.
# On 64-bit Perl, values fitting in a native 64-bit integer (5-8 bytes)
# should return a plain scalar, not a Math::BigInt object.
# Values requiring more than 8 bytes always return a Math::BigInt.

use Test::More;
use Config;

BEGIN {
    eval { require Math::BigInt } or plan skip_all => 'Math::BigInt required';
}

use Convert::ASN1;

my $is_64bit = $Config{ivsize} == 8;

my $tests = $is_64bit ? 16 : 14;
plan tests => $tests;

my $asn = Convert::ASN1->new;
ok($asn->prepare('serial INTEGER'), 'prepare schema');

# --- 5-byte positive integer (2^33 = 8589934592) ---
# DER: 02 05 02 00 00 00 00
my $val5p = 2**33;
my $der5p = pack("C*", 0x02, 0x05, 0x02, 0x00, 0x00, 0x00, 0x00);

my $enc = $asn->encode(serial => $val5p);
ok(defined $enc, 'encode 5-byte positive integer');
is($enc, $der5p, 'encode 5-byte positive integer: correct DER');

my $dec = $asn->decode($der5p);
ok(defined $dec, 'decode 5-byte positive integer');
is($dec->{serial}, $val5p, 'decode 5-byte positive integer: correct value');

if ($is_64bit) {
    ok(!ref($dec->{serial}), 'decode 5-byte integer: plain scalar on 64-bit Perl');
}

# --- 5-byte negative integer (-2^33 = -8589934592) ---
# DER: 02 05 FE 00 00 00 00
my $val5n = -(2**33);
my $der5n = pack("C*", 0x02, 0x05, 0xFE, 0x00, 0x00, 0x00, 0x00);

$enc = $asn->encode(serial => $val5n);
ok(defined $enc, 'encode 5-byte negative integer');
is($enc, $der5n, 'encode 5-byte negative integer: correct DER');

$dec = $asn->decode($der5n);
ok(defined $dec, 'decode 5-byte negative integer');
is($dec->{serial}, $val5n, 'decode 5-byte negative integer: correct value');

if ($is_64bit) {
    ok(!ref($dec->{serial}), 'decode 5-byte negative integer: plain scalar on 64-bit Perl');
}

# --- Large integer (>8 bytes) always returns Math::BigInt ---
# This is the case from issue #18: X.509 certificate serial numbers
# that are 16-20 bytes long.
#
# 19-byte serial number: 0x30FD65C101D9EA2C949EC508504A9043DB52DD
# DER: 02 13 30 FD 65 C1 01 D9 EA 2C 94 9E C5 08 50 4A 90 43 DB 52 DD
my $bignum = Math::BigInt->new('0x30FD65C101D9EA2C949EC508504A9043DB52DD');
my $der20 = pack("C*",
    0x02, 0x13,
    0x30, 0xFD, 0x65, 0xC1, 0x01, 0xD9, 0xEA, 0x2C,
    0x94, 0x9E, 0xC5, 0x08, 0x50, 0x4A, 0x90, 0x43,
    0xDB, 0x52, 0xDD);

$asn->configure(decode => { bigint => 'Math::BigInt' });

$dec = $asn->decode($der20);
ok(defined $dec, 'decode 19-byte serial number');
ok(ref($dec->{serial}) eq 'Math::BigInt', 'decode 19-byte serial: returns Math::BigInt');
ok($dec->{serial} == $bignum, 'decode 19-byte serial: correct value');

# Math::BigInt result should stringify to its decimal value
my $str = "$dec->{serial}";
ok($str =~ /^\d+$/, 'Math::BigInt result stringifies to decimal');
is($str, $bignum->bstr(), 'Math::BigInt result stringifies correctly');
