#!/usr/local/bin/perl

#
# Test macro_for_application_tag and macro_for_pdu methods (GitHub issue #5)
#

use Convert::ASN1 qw(:all);
BEGIN { require './t/funcs.pl' }

print "1..20\n";

# Set up a schema with two APPLICATION-tagged macros plus one untagged macro
btest 1, $asn = Convert::ASN1->new or warn $asn->error;
btest 2, $asn->prepare(q(
  Request  ::= [APPLICATION 0] SEQUENCE { id INTEGER }
  Response ::= [APPLICATION 1] SEQUENCE { id INTEGER, result OCTET STRING }
  Plain    ::= SEQUENCE { id INTEGER }
)) or warn $asn->error;

# --- macro_for_application_tag ---

# Find macro by numeric APPLICATION tag
stest 3, 'Request',  $asn->macro_for_application_tag(0);
stest 4, 'Response', $asn->macro_for_application_tag(1);

# Non-existent APPLICATION tag returns undef (must not croak)
btest 5, !defined($asn->macro_for_application_tag(99));

# Result from macro_for_application_tag works with find()
btest 6, do {
  my $name = $asn->macro_for_application_tag(0);
  defined($name) && defined($asn->find($name));
};

# --- macro_for_pdu ---

# Build a PDU for APPLICATION 0 (Request) -- tag 0x60, length 0x05, content
# [APPLICATION 0] SEQUENCE: tag = 0x60 (CONSTRUCTOR | APPLICATION | 0)
my $req_pdu = $asn->find('Request')->encode(id => 42);
btest 7, defined $req_pdu or warn $asn->error;

stest 8, 'Request',  $asn->macro_for_pdu($req_pdu);

my $resp_pdu = $asn->find('Response')->encode(id => 1, result => 'ok');
btest 9, defined $resp_pdu or warn $asn->error;

stest 10, 'Response', $asn->macro_for_pdu($resp_pdu);

# Plain SEQUENCE (not APPLICATION) returns undef
my $plain_pdu = $asn->find('Plain')->encode(id => 7);
btest 11, defined $plain_pdu or warn $asn->error;

btest 12, !defined($asn->macro_for_pdu($plain_pdu));

# Empty string returns undef
btest 13, !defined($asn->macro_for_pdu(''));

# High APPLICATION tag numbers (>= 30, multi-byte encoding)
btest 14, $asn2 = Convert::ASN1->new or warn $asn2->error;
btest 15, $asn2->prepare(q(
  BigTag ::= [APPLICATION 31] SEQUENCE { val INTEGER }
)) or warn $asn2->error;

stest 16, 'BigTag', $asn2->macro_for_application_tag(31);

my $big_pdu = $asn2->find('BigTag')->encode(val => 5);
btest 17, defined $big_pdu or warn $asn2->error;

stest 18, 'BigTag', $asn2->macro_for_pdu($big_pdu);

# macro_for_pdu on a PDU that has no matching macro returns undef
# Construct a fake APPLICATION 9 PDU (not in $asn schema)
my $fake_pdu = asn_encode_tag(asn_tag(ASN_APPLICATION, 9)) . "\x00";
btest 19, !defined($asn->macro_for_pdu($fake_pdu));

# macro_for_application_tag on empty tree returns undef
btest 20, do {
  my $empty = Convert::ASN1->new;
  $empty->prepare(q( Simple ::= INTEGER ));
  !defined($empty->macro_for_application_tag(0));
};
