#!/usr/local/bin/perl

#
# Test unnamed SEQUENCE, SET, CHOICE sharing parent namespace
# (issue #28 - documentation clarification)
#

use Convert::ASN1;
use Test::More tests => 20;

# Test 1: unnamed SEQUENCE nested in SEQUENCE shares parent namespace
{
  my $asn = Convert::ASN1->new;
  ok($asn->prepare(q(
    SEQUENCE {
      id   INTEGER,
      SEQUENCE {
        name OCTET STRING,
        flag BOOLEAN
      }
    }
  )), 'prepare unnamed nested SEQUENCE');

  my $buf = $asn->encode(id => 42, name => "test", flag => 1);
  ok(defined $buf, 'encode with unnamed nested SEQUENCE');

  my $out = $asn->decode($buf);
  ok(defined $out, 'decode with unnamed nested SEQUENCE');
  is($out->{id},   42,     'id accessible in parent namespace');
  is($out->{name}, 'test', 'name shared into parent namespace from unnamed SEQUENCE');
  is($out->{flag}, 1,      'flag shared into parent namespace from unnamed SEQUENCE');
}

# Test 2: unnamed SET nested in SEQUENCE shares parent namespace
{
  my $asn = Convert::ASN1->new;
  ok($asn->prepare(q(
    SEQUENCE {
      id  INTEGER,
      SET {
        name OCTET STRING,
        flag BOOLEAN
      }
    }
  )), 'prepare unnamed nested SET');

  my $buf = $asn->encode(id => 7, name => "hello", flag => 0);
  ok(defined $buf, 'encode with unnamed nested SET');

  my $out = $asn->decode($buf);
  ok(defined $out, 'decode with unnamed nested SET');
  is($out->{id},   7,       'id accessible in parent namespace');
  is($out->{name}, 'hello', 'name shared into parent namespace from unnamed SET');
  is($out->{flag}, 0,       'flag shared into parent namespace from unnamed SET');
}

# Test 3: unnamed CHOICE nested in SEQUENCE shares parent namespace
{
  my $asn = Convert::ASN1->new;
  ok($asn->prepare(q(
    SEQUENCE {
      id     INTEGER,
      CHOICE {
        label  OCTET STRING,
        active BOOLEAN
      }
    }
  )), 'prepare unnamed nested CHOICE');

  # Encode/decode with OCTET STRING alternative selected
  my $buf = $asn->encode(id => 1, label => "foo");
  ok(defined $buf, 'encode with unnamed CHOICE (OCTET STRING alternative)');

  my $out = $asn->decode($buf);
  ok(defined $out, 'decode with unnamed CHOICE (OCTET STRING alternative)');
  is($out->{id},    1,     'id accessible in parent namespace');
  is($out->{label}, 'foo', 'label (chosen alternative) in parent namespace');

  # Encode/decode with BOOLEAN alternative selected
  my $buf2 = $asn->encode(id => 2, active => 1);
  ok(defined $buf2, 'encode with unnamed CHOICE (BOOLEAN alternative)');

  my $out2 = $asn->decode($buf2);
  ok(defined $out2, 'decode with unnamed CHOICE (BOOLEAN alternative)');
  is($out2->{active}, 1, 'active (chosen alternative) in parent namespace');
}
