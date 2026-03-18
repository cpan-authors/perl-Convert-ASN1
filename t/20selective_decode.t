#!/usr/local/bin/perl

#
# Test selective decoding via ANY (GitHub issue #7)
#
# Demonstrates the solution for getting raw bytes for opaque fields:
# define the field as ANY in the ASN.1 schema. The raw bytes can then
# be decoded separately when needed.
#
# Based on the Kerberos AS-REP example from the issue: a ticket field
# that is opaque to the client but can be decoded later if required.
#

BEGIN { require './t/funcs.pl'}

use Convert::ASN1;

print "1..16\n";

# Inner schema: simulates an opaque inner structure (e.g. Kerberos ticket)
btest 1, my $ticket_asn = Convert::ASN1->new or die "new failed";
btest 2, $ticket_asn->prepare(q(
  Ticket ::= SEQUENCE {
    realm  OCTET STRING,
    sname  OCTET STRING
  }
)) or die $ticket_asn->error;

my $ticket_schema = $ticket_asn->find('Ticket');

# Outer schema: defines the inner field as ANY to get raw bytes on decode
btest 3, my $outer_asn = Convert::ASN1->new or die "new failed";
btest 4, $outer_asn->prepare(q(
  ASRep ::= SEQUENCE {
    crealm  OCTET STRING,
    ticket  ANY
  }
)) or die $outer_asn->error;

my $asrep_schema = $outer_asn->find('ASRep');

# Step 1: encode the inner ticket structure
btest 5, my $ticket_enc = $ticket_schema->encode(
  realm => "EXAMPLE.COM",
  sname => "krbtgt"
) or die $ticket_schema->error;

# Confirm ticket encodes as a DER SEQUENCE (tag 0x30)
btest 6, length($ticket_enc) > 0 && ord(substr($ticket_enc, 0, 1)) == 0x30;

# Step 2: embed the raw ticket bytes into the outer structure via ANY
btest 7, my $asrep_enc = $asrep_schema->encode(
  crealm => "EXAMPLE.COM",
  ticket => $ticket_enc
) or die $asrep_schema->error;

# Step 3: decode the outer structure
btest 8, my $asrep_dec = $asrep_schema->decode($asrep_enc) or die $asrep_schema->error;

# crealm is a normal OCTET STRING — decoded as usual
stest 9, "EXAMPLE.COM", $asrep_dec->{crealm};

# ticket is defined as ANY — comes back as raw DER bytes (not a hash)
btest 10, defined $asrep_dec->{ticket};
stest 11, $ticket_enc, $asrep_dec->{ticket};

# Step 4: selective decode — only decode the ticket when actually needed
btest 12, my $ticket_dec = $ticket_schema->decode($asrep_dec->{ticket})
  or die $ticket_schema->error;

stest 13, "EXAMPLE.COM", $ticket_dec->{realm};
stest 14, "krbtgt", $ticket_dec->{sname};

# Step 5: verify a second application of the same decode gives identical results
btest 15, my $ticket_dec2 = $ticket_schema->decode($asrep_dec->{ticket});
stest 16, $ticket_dec->{realm}, $ticket_dec2->{realm};
