#!/usr/local/bin/perl

# Test asn_read timeout parameter to prevent hanging on dropped connections

use Convert::ASN1 qw(:io);

print "1..4\n";

# Build a sample ASN.1 PDU for testing
my $pdu = pack("C*", 0x30, 0x0D,
               0x04, 0x04, 0x46, 0x72, 0x65, 0x64,
               0x04, 0x05, 0x57, 0x6F, 0x72, 0x6C, 0x64);

# Test 1: asn_read with timeout succeeds when data is available
{
    pipe(my $rd, my $wr) or die "pipe: $!";
    syswrite($wr, $pdu, length($pdu));
    close($wr);
    my $buf = '';
    my $n = asn_read($rd, $buf, 0, 5);
    close($rd);
    print "not " unless defined $n && $n == length($pdu) && $buf eq $pdu;
    print "ok 1\n";
}

# Test 2: asn_read with timeout returns undef when no data arrives within timeout
{
    pipe(my $rd, my $wr) or die "pipe: $!";
    my $buf = '';
    my $start = time();
    my $n = asn_read($rd, $buf, 0, 1);
    my $elapsed = time() - $start;
    close($rd);
    close($wr);
    # Should have timed out (returned undef) and set $@
    print "not " if defined $n;
    print "ok 2\n";
}

# Test 3: $@ is set to "Timeout" on timeout
{
    pipe(my $rd, my $wr) or die "pipe: $!";
    my $buf = '';
    $@ = '';
    asn_read($rd, $buf, 0, 1);
    close($rd);
    close($wr);
    print "not " unless $@ =~ /Timeout/i;
    print "ok 3\n";
}

# Test 4: asn_read without timeout parameter still works (backward compat)
{
    pipe(my $rd, my $wr) or die "pipe: $!";
    syswrite($wr, $pdu, length($pdu));
    close($wr);
    my $buf = '';
    my $n = asn_read($rd, $buf);
    close($rd);
    print "not " unless defined $n && $buf eq $pdu;
    print "ok 4\n";
}
