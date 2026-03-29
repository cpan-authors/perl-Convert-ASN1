#!/usr/local/bin/perl

#
# Regression test for GitHub issue #32:
# "intermittent error: oid is undefined when calling $asn1->encode"
#
# With Perl 5.18+ hash randomization, (values %hash)[0] is non-deterministic.
# When a schema defines multiple named types, the default script chosen by
# prepare() must always be the last-defined type, not a random one.
#

use Convert::ASN1;
BEGIN { require './t/funcs.pl' }

print "1..6\n";

# Schema mimicking the reporter's use case:
# AlgorithmIdentifier is defined first (a sub-type),
# SignedData is defined last (the main type the user encodes/decodes).
my $schema = <<'END';
  AlgorithmIdentifier ::= SEQUENCE {
    oid    OBJECT IDENTIFIER,
    params ANY OPTIONAL
  }
  SignedData ::= SEQUENCE {
    sig  OCTET STRING,
    alg  AlgorithmIdentifier
  }
END

btest 1, my $asn = Convert::ASN1->new;
btest 2, $asn->prepare($schema) or warn $asn->error;

# Without find(), prepare() must default to the LAST-defined type (SignedData).
# Before the fix, hash randomization could cause prepare() to pick
# AlgorithmIdentifier, making encode() fail with "oid is undefined".
my $encoded = $asn->encode(
  sig => pack('H*', 'deadbeef'),
  alg => { oid => '1.2.840.113549.1.1.13' },
);
btest 3, defined $encoded or warn "encode failed: ", $asn->error, "\n";

# The default encoding must match an explicit find('SignedData') encoding.
my $found_asn = $asn->find('SignedData');
my $found_encoded = $found_asn->encode(
  sig => pack('H*', 'deadbeef'),
  alg => { oid => '1.2.840.113549.1.1.13' },
);
btest 4, defined $found_encoded or warn "find encode failed: ", $found_asn->error, "\n";

stest 5, $found_encoded, $encoded;

# Decode round-trip using the default script.
my $decoded = $asn->decode($encoded);
btest 6, defined $decoded && $decoded->{sig} eq pack('H*', 'deadbeef')
      && $decoded->{alg}{oid} eq '1.2.840.113549.1.1.13'
    or warn "decode failed or wrong values\n";
