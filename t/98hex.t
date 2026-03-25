#!/usr/local/bin/perl

#
# Tests for hex conversions
#

use Convert::ASN1;
BEGIN { require 't/funcs.pl' }

print "1..8\n";

my $num = '0x01';
stest 1, '0x01', Convert::ASN1::hex2twos($num);

$num = '-0x01';
stest 2, '0xff', Convert::ASN1::hex2twos($num);

$num = '0xfffb9a30a0cd0d3b';
stest 3, '-0x0465cf5f32f2c5', Convert::ASN1::twos2hex($num);

$num = '0xffffffffffff';
stest 4, '-0x01', Convert::ASN1::twos2hex($num);

$num = '0x01000000000000';
stest 5, '0x01000000000000', Convert::ASN1::twos2hex($num);

$num = '0x01000000000000';
stest 6, '0x01000000000000', Convert::ASN1::twos2hex($num);

$num = '0xffff000000000000';
stest 7, '-0x01000000000000', Convert::ASN1::twos2hex($num);

$num = '0xff000000000000';
stest 8, '-0x01000000000000', Convert::ASN1::twos2hex($num);

