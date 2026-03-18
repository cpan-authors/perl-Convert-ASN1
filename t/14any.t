#!/usr/local/bin/perl

#
# Check whether the ANY DEFINED BY syntax is working
#

BEGIN { require './t/funcs.pl'}

use Convert::ASN1;

print "1..26\n";

btest 1, $asn_str=Convert::ASN1->new or warn $asn->error;
btest 2, $asn_str->prepare("string STRING") or warn $asn->error;
btest 3, $asn_seq=Convert::ASN1->new or warn $asn->error;
btest 4, $asn_seq->prepare(q(
  SEQUENCE { 
    integer INTEGER,
    str STRING
  }
)) or warn $asn_seq->error;

btest 5, $asn = Convert::ASN1->new or warn $asn->error;
btest 6, $asn->prepare(q(
	type OBJECT IDENTIFIER,
	content ANY DEFINED BY type
)) or warn $asn->error;

# Bogus OIDs - testing only!
btest 7, $asn->registeroid("1.1.1.1",$asn_str);
btest 8, $asn->registeroid("1.1.1.2",$asn_seq);

# Encode the first type
my $result = pack("C*", 0x06, 0x03, 0x29, 0x01, 0x01, 0x04, 0x0d, 0x4a, 0x75,
		        0x73, 0x74, 0x20, 0x61, 0x20, 0x73, 0x74, 0x72, 0x69,
                        0x6e, 0x67);

stest 9, $result, $asn->encode(type => "1.1.1.1", content => {string=>"Just a string"});
btest 10, $ret = $asn->decode($result) or warn $asn->error;
stest 11, "Just a string", $ret->{content}->{string};

# Now check the second

$result = pack("C*", 0x06, 0x03, 0x29, 0x01, 0x02, 0x30, 0x11, 0x02,
		     0x01, 0x01, 0x04, 0x0c, 0x61, 0x6e, 0x64, 0x20,
		     0x61, 0x20, 0x73, 0x74, 0x72, 0x69, 0x6e, 0x67);

stest 12, $result, $asn->encode(type => "1.1.1.2", 
			        content => {integer=>1, str=>"and a string"});
btest 13, $ret = $asn->decode($result) or warn $asn->error;
ntest 14, 1, $ret->{content}->{integer};
stest 15, "and a string", $ret->{content}->{str};

# Decoding ANY with indefinite length must include the trailing terminator

btest 16, $asn = Convert::ASN1->new or warn $asn->error;
btest 17, $asn->prepare(q(
        Test2 ::= ANY
        Test1 ::= SEQUENCE OF ANY
)) or warn $asn->error;

$result = pack("H*","3080020109308002010900000000");

btest 18, $ret = $asn->find('Test1')->decode($result);
rtest 19, [pack("H*","020109"),pack("H*","30800201090000")], $ret;

btest 20, $ret = $asn->find('Test2')->decode($result);
stest 21, $result, $ret;

# Regression test for GitHub issue #27:
# SET OF ANY DEFINED BY with unregistered OIDs should return raw bytes without warning.
# The inner ANY in "SET OF ANY DEFINED BY" has no cVAR (anonymous element), so using
# it as a hash key in the handlers lookup must be guarded with defined().
btest 22, my $asn3 = Convert::ASN1->new;
btest 23, $asn3->prepare(q(
    Attribute ::= SEQUENCE {
      type   OBJECT IDENTIFIER,
      values SET OF ANY DEFINED BY type}
));
$asn3->registeroid("1.1.1.1", $asn_str); # register only 1.1.1.1, not 1.1.1.2

# Manually constructed: Attribute { type=1.1.1.2 (unregistered), values=[OCTET STRING "hello"] }
# 30 0e           SEQUENCE (14 bytes)
#   06 03 29 01 02  OID 1.1.1.2
#   31 07           SET (7 bytes)
#     04 05 68 65 6c 6c 6f  OCTET STRING "hello"
my $result3 = pack("H*", "300e06032901023107040568656c6c6f");
my $warnings3 = '';
local $SIG{__WARN__} = sub { $warnings3 .= $_[0] };
btest 24, my $ret3 = $asn3->find("Attribute")->decode($result3);
btest 25, !$warnings3; # must not warn "Use of uninitialized value"
# values[0] should be raw bytes (the unregistered OID element)
my $raw_elem = pack("H*", "040568656c6c6f"); # OCTET STRING "hello"
stest 26, $raw_elem, $ret3->{values}[0]; # raw bytes for unregistered OID
