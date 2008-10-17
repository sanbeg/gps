#! /usr/bin/perl -w

use strict;
use Fatal 'read';
my $buf='';
my $n;
my $read_bytes = 0;
my $sum = 0;

sub rb($;$) {
    my ($len,$t) = @_;
    $read_bytes += $len;
    read FH, $buf, $len;
    unpack "$t", $buf if defined $t;
};

sub readfname() {
    my $name;
    read FH, $name, 12;
    $sum ^= $_ for unpack 'n[6]', $name;
    $name =~ s/\0+/./;
    return $name;
};

sub readfdata() {
    #values are unknown, offset, size
    my $buf;
    read FH, $buf, 12;
    $sum ^= $_ for unpack 'n[6]', $buf;
    unpack 'LLL', $buf;
};

my $file = shift;
open FH, $file or die "$file: $!";

my $count = rb 4, 'L';
my $verify = rb 4, 'L';
die "Invalid POI file" unless $count == $verify;

my @index;

for my $i (1..$count) {
    my $n=readfname;
    my @d = readfdata;
    push @index, [$n, @d];
}

#verify checksum
$n = rb 2, 'n';

die "checksum error: $n = $sum" unless $n == $sum;
rb 8; #and another 22 0s
die "Invalid POI file" unless $buf eq 'MAGELLAN';

print "extracting $count files:\n";

foreach my $ent (@index) {
    my ($name, undef, $offset, $size) = @{$ent};

    seek FH, $offset, 0 or die;

    open OFH, ">$name" or die "$name: $!";
    print "  $name\n";
    
    while ($size > 0) {
	my $block = 1024;
	if ($size > $block) {
	    $size -= $block;
	} else {
	    $block = $size;
	    $size = 0;
	};

	my $bs = read FH,$buf,$block;
	print OFH $buf;
    }
    close OFH;
}
close FH;


