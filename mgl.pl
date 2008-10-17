#! /usr/bin/perl -w

use strict;

my $file = shift;
open FH, $file or die "$file: $!";

#seek FH, 292, 0;
#seek FH, 300, 0; #offset can vary...

sub get_name() {
    read FH, my($name), 36;
    $name =~ s/\0+//;

    return $name;
};

sub next_poi {
    print "  POI:", tell(FH),"\n";
    
    my $name = get_name;
    print "    name:        ", $name, "\n";

    my $desc = get_name;
    print "    description: ",$desc, "\n";
    
    read FH,my($coord), 10;
    read FH,my($zero), 2;
    warn "unexpected nonzero" unless $zero eq "\0\0";

    my ($long, $lat, $alt ) = unpack "llS", $coord;
    #print "    $lat x $long $alt \n";
    printf "    %0.5fN %0.5fE $alt\n", $lat/100_000, $long/100_000;
}

#next_poi for 1..4;

sub print_unknown{
    my $unk = shift;
    my $len = length($unk);
    printf "  Unknown: ".("%0.2x "x $len)."\n", 
    unpack(("C" x $len),$unk);
};

sub next_cat {
    my $name = get_name;

    print "Category:\n";
    print "  name:       ", $name, "\n";

    my $desc = get_name;
    print "  description:", $desc, "\n";


    my $unk;
    read FH, $unk, 4;
#first 4 are #poi x 2.
    my($npoi, $npoi_v) = unpack "SS", $unk;
    print "  Group has $npoi POIs\n";
    
#4 unknown bytes
    my @unk;
    read FH, $unk, 8;
    @unk = unpack 'l[2]', $unk;
    print "  Alert: $unk[0] (257=on, 1=off)\n";
    print "  Detection angle: $unk[1]\n";
    read FH, my($d1s), 2;;
    my $d1 = unpack "S", $d1s;
    my $tone1 = get_name;
    print "  t1: $tone1 = $d1 meters\n";
    
    read FH, my($d2s), 2;
    my $d2 = unpack "S", $d2s;
    my $tone2 = get_name;
    print "  t2: $tone2 = $d2 meters\n";
    
    read FH, $unk, 2; #is gb part of name or something else?
    my $icon = get_name;
    print "  icon: $unk $icon\n";
    
    # read FH, $unk, 32;
#     @unk = unpack 'l[4]', $unk;
#     # $unk[3] changes if longitude of POI changes, 2&3 if lat changes?
#     # none for altitude or name change
#     #print "  Unknown: @unk\n";
#     printf "  Unknown: %x %x %x %x\n", @unk;

    read FH, $unk, 10;
    print_unknown($unk);

    #read a few extra (1 before & after), see what we get..
    print "  bounding box:\n";
    for (1..2) {
	read FH, my($coord), 8;
	my ($long, $lat ) = unpack "ll", $coord;
	printf "    %0.5fN %0.5fE\n", $lat/100_000, $long/100_000;
    };
    read FH, $unk, 6;
    print_unknown($unk);
    
    read FH, $unk, 8*($npoi);
    print_unknown($unk);


#     read FH, $unk,8*$npoi;
#     my @off = unpack "l" x ($npoi*2), $unk;
#     print "  POI flags=@off\n";

    
    next_poi for 1..$npoi;
}

seek FH, 37, 0;
read FH,my($buf),1;
my $ncat = unpack 'C', $buf;
print "file has $ncat categories\n";
next_cat for 1 .. $ncat;
