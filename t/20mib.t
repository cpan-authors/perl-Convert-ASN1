#!/usr/local/bin/perl

#
# Tests for MIB-like ASN.1 constructs (issue #10)
#

use Convert::ASN1;

print "1..12\n";

BEGIN { require './t/funcs.pl' }

my $asn = Convert::ASN1->new;
my $test = 1;

##
## OID value assignments: name OBJECT IDENTIFIER ::= { parent arc }
##

print "# OID value assignment (simple)\n";
btest $test++, $asn->prepare(
    'org OBJECT IDENTIFIER ::= { iso 3 }'
) or warn $asn->error;

print "# OID value assignment (chained)\n";
btest $test++, $asn->prepare('
    org      OBJECT IDENTIFIER ::= { iso 3 }
    dod      OBJECT IDENTIFIER ::= { org 6 }
    internet OBJECT IDENTIFIER ::= { dod 1 }
') or warn $asn->error;

print "# OID value assignment with named arcs\n";
btest $test++, $asn->prepare(
    'id-modules OBJECT IDENTIFIER ::= { iso org(3) dod(6) internet(1) }'
) or warn $asn->error;

##
## SIZE constraints
##

print "# SIZE constraint with alternatives\n";
btest $test++, $asn->prepare(
    'ExtUTCTime ::= OCTET STRING(SIZE(11 | 13))'
) or warn $asn->error;

print "# SIZE constraint with range\n";
btest $test++, $asn->prepare(
    'MyStr ::= OCTET STRING (SIZE(1..255))'
) or warn $asn->error;

print "# SIZE constraint with space before paren\n";
btest $test++, $asn->prepare(
    'MyStr2 ::= OCTET STRING (SIZE (0..127))'
) or warn $asn->error;

##
## IMPORTS section (should be silently ignored)
##

print "# IMPORTS section ignored\n";
btest $test++, $asn->prepare('
    IMPORTS
        MODULE-IDENTITY, Integer32
            FROM SNMPv2-SMI
        DisplayString
            FROM SNMPv2-TC;
    MyType ::= INTEGER
') or warn $asn->error;

##
## DEFINITIONS ::= BEGIN / END module wrapper
##

print "# DEFINITIONS ::= BEGIN / END wrapper\n";
btest $test++, $asn->prepare('
    MyModule DEFINITIONS ::= BEGIN
        MyType ::= SEQUENCE {
            field1 INTEGER,
            field2 OCTET STRING
        }
    END
') or warn $asn->error;

print "# DEFINITIONS with IMPLICIT TAGS\n";
btest $test++, $asn->prepare('
    MyModule DEFINITIONS IMPLICIT TAGS ::= BEGIN
        MyStr ::= OCTET STRING
    END
') or warn $asn->error;

##
## Combined: partial MIB fragment
##

print "# Partial MIB fragment\n";
btest $test++, $asn->prepare('
    org      OBJECT IDENTIFIER ::= { iso 3 }
    dod      OBJECT IDENTIFIER ::= { org 6 }
    internet OBJECT IDENTIFIER ::= { dod 1 }
    mgmt     OBJECT IDENTIFIER ::= { internet 2 }
    mib-2    OBJECT IDENTIFIER ::= { mgmt 1 }
') or warn $asn->error;

print "# Constraint on sequence field\n";
btest $test++, $asn->prepare('
    MyMsg ::= SEQUENCE {
        host  IA5String (SIZE (1..255)),
        port  INTEGER (0..65535)
    }
') or warn $asn->error;

print "# Multiple constructs combined\n";
btest $test++, $asn->prepare('
    IMPORTS
        Integer32 FROM SNMPv2-SMI;
    org      OBJECT IDENTIFIER ::= { iso 3 }
    MyType   ::= OCTET STRING (SIZE(1..128))
') or warn $asn->error;
