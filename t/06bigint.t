#!/usr/local/bin/perl

#
# Test bigint INTEGER encoding/decoding
#

use Convert::ASN1;
BEGIN { require './t/funcs.pl' }

$^W=0 if $] < 5.005; # BigInt in 5.004 has undef issues

print "1..117\n";

btest 1, $asn = Convert::ASN1->new or warn $asn->error;
btest 2, $asn->prepare(q(
 integer INTEGER
)) or warn $asn->error;

use Math::BigInt;
my $num = 
Math::BigInt->new("1092509802939879587398450394850984098031948509");

$asn->configure(decode => { bigint => 'Math::BigInt' }, encode => { bigint => 'Math::BigInt' });

$result = pack("C*", 0x2,  0x13, 0x30, 0xfd, 0x65, 0xc1, 0x01, 0xd9,
                     0xea, 0x2c, 0x94, 0x9e, 0xc5, 0x08, 0x50, 0x4a,
                     0x90, 0x43, 0xdb, 0x52, 0xdd);
stest 3, $result, $asn->encode(integer => $num) or warn $asn->error;
btest 4, $ret = $asn->decode($result) or warn $asn->error;
btest 5, exists $ret->{integer};
btest 6, ref($ret->{integer}) eq 'Math::BigInt';
ntest 7, $num, $ret->{integer};

$num = (1<<17) * (1<<17);
$result = pack("C*", 0x2, 0x5, 0x4, 0x0, 0x0, 0x0, 0x0);
stest 8, $result, $asn->encode(integer => $num) or warn $asn->error;
btest 9, $ret = $asn->decode($result) or warn $asn->error;
btest 10, exists $ret->{integer};
ntest 11, $num, $ret->{integer};

$num += 10;
$result = pack("C*", 0x2, 0x5, 0x4, 0x0, 0x0, 0x0, 0xa);
stest 12, $result, $asn->encode(integer => $num) or warn $asn->error;
btest 13, $ret = $asn->decode($result) or warn $asn->error;
btest 14, exists $ret->{integer};
ntest 15, $num, $ret->{integer};

$num = -$num;
$result = pack("C*", 0x2, 0x5, 0xfb, 0xff, 0xff, 0xff, 0xf6);
stest 16, $result, $asn->encode(integer => $num) or warn $asn->error;
btest 17, $ret = $asn->decode($result) or warn $asn->error;
btest 18, exists $ret->{integer};
ntest 19, $num, $ret->{integer};

$num += 10;
$result = pack("C*", 0x2, 0x5, 0xfc, 0x0, 0x0, 0x0, 0x0);
stest 20, $result, $asn->encode(integer => $num) or warn $asn->error;
btest 21, $ret = $asn->decode($result) or warn $asn->error;
btest 22, exists $ret->{integer};
ntest 23, $num, $ret->{integer};

$num = Math::BigInt->new("-1092509802939879587398450394850984098031948509");
$result = pack("C*", 0x2,  0x13, 0xcf, 0x2,  0x9a, 0x3e, 0xfe, 0x26,
                     0x15, 0xd3, 0x6b, 0x61, 0x3a, 0xf7, 0xaf, 0xb5,
                     0x6f, 0xbc, 0x24, 0xad, 0x23);
stest 24, $result, $asn->encode(integer => $num) or warn $asn->error;
btest 25, $ret = $asn->decode($result) or warn $asn->error;
btest 26, exists $ret->{integer};
ntest 27, $num, $ret->{integer};


## Test most-significant bit bug in 0.09.
$num =  Math::BigInt->new("1333280603684579469575805266526464216433260889799");
$result = pack("C*", 0x2,  0x15, 0x00, 0xe9, 0x8a, 0x5e, 0xb8, 0x3a,
                     0xfa, 0x3d, 0x4,  0x13, 0x7d, 0x19, 0xfc, 0x39,
                     0x36, 0xa3, 0x2b, 0xd2, 0x22, 0x06, 0xc7);
stest 28, $result, $asn->encode(integer => $num) or warn $asn->error;
btest 29, $ret = $asn->decode($result) or warn $asn->error;
btest 30, exists $ret->{integer};
ntest 31, $num, $ret->{integer};

$num = Math::BigInt->new(-1 * (1<<24)) * Math::BigInt->new(1<<24);
$result = pack("C*", 0x2,  0x7, 0xff, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0);
stest 32, $result, $asn->encode(integer => $num) or warn $asn->error;
btest 33, $ret = $asn->decode($result) or warn $asn->error;
btest 34, exists $ret->{integer};
ntest 35, $num, $ret->{integer};

## testing twos complement option
$asn->configure(decode => { bigint => 'twos' }, encode => { bigint => 'twos' });

$num = '0x30fd65c101d9ea2c949ec508504a9043db52dd';
$result = pack("C*", 0x2,  0x13, 0x30, 0xfd, 0x65, 0xc1, 0x01, 0xd9,
                     0xea, 0x2c, 0x94, 0x9e, 0xc5, 0x08, 0x50, 0x4a,
                     0x90, 0x43, 0xdb, 0x52, 0xdd);
stest 36, $result, $asn->encode(integer => $num) or warn $asn->error;
btest 37, $ret = $asn->decode($result) or warn $asn->error;
btest 38, exists $ret->{integer};
stest 39, $num, lc $ret->{integer};

$num = '0x0400000000';
$result = pack("C*", 0x2, 0x5, 0x4, 0x0, 0x0, 0x0, 0x0);
stest 40, $result, $asn->encode(integer => $num) or warn $asn->error;
btest 41, $ret = $asn->decode($result) or warn $asn->error;
btest 42, exists $ret->{integer};
stest 43, $num, lc $ret->{integer};

$num = '0x040000000a';
$result = pack("C*", 0x2, 0x5, 0x4, 0x0, 0x0, 0x0, 0xa);
stest 44, $result, $asn->encode(integer => $num) or warn $asn->error;
btest 45, $ret = $asn->decode($result) or warn $asn->error;
btest 46, exists $ret->{integer};
stest 47, $num, $ret->{integer};

$asn->configure(encode => { bigint => 'Math::BigInt' });

$num = "-$num";
my $hnum = '0xfbfffffff6';
$result = pack("C*", 0x2, 0x5, 0xfb, 0xff, 0xff, 0xff, 0xf6);
stest 48, $result, $asn->encode(integer => $num) or warn $asn->error;
btest 49, $ret = $asn->decode($result) or warn $asn->error;
btest 50, exists $ret->{integer};
stest 51, $hnum, $ret->{integer};

$asn->configure(encode => { bigint => 'twos' });

$num = '0xfbfffffff6';
$result = pack("C*", 0x2, 0x5, 0xfb, 0xff, 0xff, 0xff, 0xf6);
stest 52, $result, $asn->encode(integer => $num) or warn $asn->error;
btest 53, $ret = $asn->decode($result) or warn $asn->error;
btest 54, exists $ret->{integer};
stest 55, $num, lc $ret->{integer};
$asn->configure(decode => { bigint => 'Math::BigInt' }, encode => { bigint => 'Math::BigInt' });
$num = Math::BigInt->new('-17179869194');
btest 56, $ret = $asn->decode($result) or warn $asn->error;
btest 57, exists $ret->{integer};
ntest 58, $num, $ret->{integer};


$asn->configure(decode => { bigint => 'twos' }, encode => { bigint => 'twos' });

$num = Math::BigInt->new("-1092509802939879587398450394850984098031948509");
$hnum = '0xcf029a3efe2615d36b613af7afb56fbc24ad23';

$result = pack("C*", 0x2,  0x13, 0xcf, 0x2,  0x9a, 0x3e, 0xfe, 0x26,
                     0x15, 0xd3, 0x6b, 0x61, 0x3a, 0xf7, 0xaf, 0xb5,
                     0x6f, 0xbc, 0x24, 0xad, 0x23);
stest 59, $result, $asn->encode(integer => $num) or warn $asn->error;
btest 60, $ret = $asn->decode($result) or warn $asn->error;
btest 61, exists $ret->{integer};
stest 62, $hnum, lc $ret->{integer};

## testing hex option
$asn->configure(decode => { bigint => 'hex' }, encode => { bigint => 'hex' });

$num = '0x30fd65c101d9ea2c949ec508504a9043db52dd';
$result = pack("C*", 0x2,  0x13, 0x30, 0xfd, 0x65, 0xc1, 0x01, 0xd9,
                     0xea, 0x2c, 0x94, 0x9e, 0xc5, 0x08, 0x50, 0x4a,
                     0x90, 0x43, 0xdb, 0x52, 0xdd);
stest 63, $result, $asn->encode(integer => $num) or warn $asn->error;
btest 64, $ret = $asn->decode($result) or warn $asn->error;
btest 65, exists $ret->{integer};
stest 66, $num, lc $ret->{integer};

$num = '0x0400000000';
$result = pack("C*", 0x2, 0x5, 0x4, 0x0, 0x0, 0x0, 0x0);
stest 67, $result, $asn->encode(integer => $num) or warn $asn->error;
btest 68, $ret = $asn->decode($result) or warn $asn->error;
btest 69, exists $ret->{integer};
stest 70, $num, lc $ret->{integer};

$num = '0x040000000a';
$result = pack("C*", 0x2, 0x5, 0x4, 0x0, 0x0, 0x0, 0xa);
stest 71, $result, $asn->encode(integer => $num) or warn $asn->error;
btest 72, $ret = $asn->decode($result) or warn $asn->error;
btest 73, exists $ret->{integer};
stest 74, $num, lc $ret->{integer};

$num = "-$num";
$result = pack("C*", 0x2, 0x5, 0xfb, 0xff, 0xff, 0xff, 0xf6);
stest 75, $result, $asn->encode(integer => $num) or warn $asn->error;
btest 76, $ret = $asn->decode($result) or warn $asn->error;
btest 77, exists $ret->{integer};
stest 78, $num, lc $ret->{integer};
$asn->configure(decode => { bigint => 'Math::BigInt' }, encode => { bigint => 'Math::BigInt' });
$num = Math::BigInt->new('-17179869194');
btest 79, $ret = $asn->decode($result) or warn $asn->error;
btest 80, exists $ret->{integer};
ntest 81, $num, $ret->{integer};

$asn->configure(decode => { bigint => 'hex' }, encode => { bigint => 'hex' });

$num  = '-0x000030fd65c101d9ea2c949ec508504a9043db52dd';
$hnum = '-0x30fd65c101d9ea2c949ec508504a9043db52dd';

$result = pack("C*", 0x2,  0x13, 0xcf, 0x2,  0x9a, 0x3e, 0xfe, 0x26,
                     0x15, 0xd3, 0x6b, 0x61, 0x3a, 0xf7, 0xaf, 0xb5,
                     0x6f, 0xbc, 0x24, 0xad, 0x23);
stest 82, $result, $asn->encode(integer => $num) or warn $asn->error;
btest 83, $ret = $asn->decode($result) or warn $asn->error;
btest 84, exists $ret->{integer};
stest 85, $hnum, lc $ret->{integer};

$asn->configure(decode => { bigint => 'Math::BigInt' }, encode => { bigint => 'Math::BigInt' });

######

my $test = 86;

my %INTEGER = (
  pack("C*", 0x02, 0x04, 0x40, 0x00, 0x00, 0x00),	     2**30,
  pack("C*", 0x02, 0x05, 0x00, 0x80, 0x00, 0x00, 0x00),	     2**31,
  pack("C*", 0x02, 0x05, 0x01, 0x00, 0x00, 0x00, 0x00),	     2**32,
  pack("C*", 0x02, 0x04, 0xC0, 0x00, 0x00, 0x00),	     -2**30,
  pack("C*", 0x02, 0x04, 0x80, 0x00, 0x00, 0x00),	     -2**31,
  pack("C*", 0x02, 0x05, 0xFF, 0x00, 0x00, 0x00, 0x00),	     -2**32,
);

while(($result,$val) = each %INTEGER) {
  print "# INTEGER $val\n";

  btest $test++, $asn->prepare(' integer INTEGER') or warn $asn->error;
  stest $test++, $result, $asn->encode(integer => $val) or warn $asn->error;
  btest $test++, $ret = $asn->decode($result) or warn $asn->error;
  ntest $test++, $val, $ret->{integer};

}

my %BCD = (
  pack("C*", 0x04, 0x05, 0x10, 0x73, 0x74, 0x18, 0x24),	     2**30,
  pack("C*", 0x04, 0x00),	     -2**30,
);

while(($result,$val) = each %BCD) {
  print "# BCDString $val\n";

  btest $test++, $asn->prepare('bcd BCDString') or warn $asn->error;
  stest $test++, $result, $asn->encode(bcd => $val) or warn $asn->error;
  btest $test++, $ret = $asn->decode($result) or warn $asn->error;
  $val =~ s/\D.*//;
  stest $test++, $val, $ret->{'bcd'};
}

