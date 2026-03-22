#!/usr/local/bin/perl

#
# Tests for issue #38: decoding CDRs written in fixed block sizes with padding bytes
#

use Convert::ASN1;
BEGIN { require './t/funcs.pl' }

print "1..12\n";

my $asn = Convert::ASN1->new;
btest 1, $asn->prepare('seq SEQUENCE { id INTEGER, name OCTET STRING }') or warn $asn->error;

# Encode a simple record
my $encoded = $asn->encode(seq => { id => 42, name => "hello" }) or die $asn->error;
btest 2, length($encoded) > 0;

# Without padding, decode works normally
btest 3, $asn->decode($encoded) or warn $asn->error;

# Pad to 512-byte block with null bytes (simulating CDR fixed-block-size file)
my $block_size = 512;
my $padded = $encoded . "\x00" x ($block_size - length($encoded));
btest 4, length($padded) == $block_size;

# Without block_size option, decoding the padded buffer should fail
my $ret = $asn->decode($padded);
btest 5, !defined($ret);

# Configure with block_size option
my $asn_bs = Convert::ASN1->new;
btest 6, $asn_bs->prepare('seq SEQUENCE { id INTEGER, name OCTET STRING }') or warn $asn_bs->error;
$asn_bs->configure(decode => { block_size => $block_size });
btest 7, 1; # configure() does not return a meaningful value

# With block_size configured, padded buffer decodes successfully
my $result = $asn_bs->decode($padded);
btest 8, defined($result) or warn $asn_bs->error;
ntest 9, 42, $result->{seq}{id};
stest 10, "hello", $result->{seq}{name};

# Decoding unpadded data still works when block_size is set
my $result2 = $asn_bs->decode($encoded);
btest 11, defined($result2) or warn $asn_bs->error;
ntest 12, 42, $result2->{seq}{id};
