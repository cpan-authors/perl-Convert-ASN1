use strict;
use warnings;
use Convert::ASN1;
use Test::More;

# Test for memory leaks reported in
# https://github.com/gbarr/perl-Convert-ASN1/issues/49
#
# Two leak sources were identified:
# 1. Parser globals ($yyval, @yyvs) retaining references after prepare()
# 2. find() returning a shallow copy that shares mutable options with parent

# --- Test 1: Parser globals are cleaned up after prepare() ---

my $asn = Convert::ASN1->new;
$asn->prepare(q(
  Foo ::= SEQUENCE {
    bar INTEGER,
    baz OCTET STRING
  }
));

{
  no strict 'refs';
  is($Convert::ASN1::parser::yyval, undef,
    'parser $yyval cleared after prepare()');
  is(scalar @Convert::ASN1::parser::yyvs, 0,
    'parser @yyvs cleared after prepare()');
  is(scalar @Convert::ASN1::parser::yyss, 0,
    'parser @yyss cleared after prepare()');
}

# --- Test 2: find() returns object with independent options ---

my $found = $asn->find('Foo');
ok($found, 'find() returns an object');

# The options hash should be a different reference
isnt(\%{$found->{options}}, \%{$asn->{options}},
  'find() returns object with copied options hash');

# Modifying the found object's options should not affect the parent
$found->{options}{test_key} = 'test_value';
ok(!exists $asn->{options}{test_key},
  'modifying found options does not affect parent');

# --- Test 3: Repeated prepare+find cycles don't leak parser state ---

for my $i (1..100) {
  my $tmp = Convert::ASN1->new;
  $tmp->prepare(q(
    Bar ::= SEQUENCE {
      x INTEGER,
      y BOOLEAN
    }
  ));
  my $f = $tmp->find('Bar');
  # encode/decode cycle to exercise the full path
  my $encoded = $f->encode({ x => $i, y => 1 });
  my $decoded = $f->decode($encoded);
  # Objects go out of scope here — should be fully reclaimable
}

{
  no strict 'refs';
  is($Convert::ASN1::parser::yyval, undef,
    'parser globals still clean after 100 prepare cycles');
  is(scalar @Convert::ASN1::parser::yyvs, 0,
    'parser @yyvs still clean after 100 prepare cycles');
}

# --- Test 4: registeroid on found object doesn't pollute parent ---

my $asn2 = Convert::ASN1->new;
$asn2->prepare(q(
  Msg ::= SEQUENCE {
    oid OBJECT IDENTIFIER,
    val ANY DEFINED BY oid
  }
));
my $found2 = $asn2->find('Msg');
$found2->registeroid('1.2.3.4', sub { 'test' });

ok(!exists $asn2->{oidtable}{'1.2.3.4'},
  'registeroid on found object does not pollute parent oidtable');
ok(!exists $asn2->{options}{oidtable}{'1.2.3.4'},
  'registeroid on found object does not pollute parent options oidtable');

# --- Test 5: registertype on found object doesn't pollute parent ---

$found2->{options}{handlers} = {} unless $found2->{options}{handlers};
$found2->registertype('Msg', 'INTEGER', sub { 'handler' });

ok(!exists $asn2->{options}{handlers}{'Msg'},
  'registertype on found object does not pollute parent handlers');

done_testing;
