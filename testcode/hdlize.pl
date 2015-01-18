#!/usr/bin/perl

print "hdlize - (c) 2004-2007 Edmond Cote (edmond.cote@ece.queensu.ca)\n";

$in = $ARGV[0];

if (!$in) {
    die "Usage: hdlize.pl FILE\n";
}

# open file
$out = "rom_chip.inc";
open (IN, $in); open (OUT, ">$out");
binmode(IN);

# write rom data into verilog format
$count = 0;

while(read(IN,$buf,4)) {
    $n = length($buf);
    $s = 2*$n;
    print OUT $count . " : mem = 32'h" . unpack("H$s",$buf) . ";\n";
    $count++;
}

print OUT "default: mem = '0;";

# close file
close(IN); close(OUT);
