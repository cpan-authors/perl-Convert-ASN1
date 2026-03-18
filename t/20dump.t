#!/usr/local/bin/perl

#
# Tests for asn_dump() - github issue #24
# asn_dump() was printing -1 for big integers (> 4 bytes) instead
# of the actual value, because printf "%d" cannot handle Math::BigInt objects.
#

use Convert::ASN1 qw(asn_dump);
BEGIN { require './t/funcs.pl' }

print "1..2\n";

# Capture asn_dump() output to a string
sub capture_dump {
    my $data = shift;
    my $output = '';
    open my $fh, '>', \$output or die "Cannot open string ref: $!";
    asn_dump($fh, $data);
    close $fh;
    return $output;
}

# Test 1: asn_dump of a 5-byte INTEGER (> 4 bytes triggers big integer path)
# Encoding of integer 17179869184 (= 2^34 = 0x400000000):
#   Tag:    0x02 (INTEGER)
#   Length: 0x05
#   Value:  0x04 0x00 0x00 0x00 0x00
{
    my $data = pack("C*", 0x02, 0x05, 0x04, 0x00, 0x00, 0x00, 0x00);
    my $out = capture_dump($data);
    # Should show the actual value, not -1
    btest 1, ($out =~ /=\s*17179869184/ && $out !~ /=\s*-1/);
}

# Test 2: asn_dump of a large positive INTEGER (RSA-key sized, 129 bytes)
# Value is 2^1024 - represented as 129 bytes: 0x01 followed by 128 zero bytes
# (The leading 0x00 pad byte is needed because MSB is 0x80 in 0x01..., wait no)
# Actually 2^1024 in ASN.1 DER:
#   The value bytes for 2^1024 = 0x01 followed by 128 zero bytes (129 bytes total)
#   No padding needed since MSB of 0x01 is 0 (positive, no sign ambiguity)
{
    my $value_bytes = pack("C", 0x01) . pack("C*", (0x00) x 128); # 129 bytes = 2^1024
    my $len = length($value_bytes); # 129
    my $data = pack("C", 0x02) . pack("C*", 0x81, $len) . $value_bytes;
    my $out = capture_dump($data);
    # Should show a large number, definitely not -1
    btest 2, ($out !~ /=\s*-1/);
}
