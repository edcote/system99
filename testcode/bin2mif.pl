#!/usr/bin/perl

print ERR "bin2mif - (c) 2004-2007 Edmond Cote (edmond.cote@ece.queensu.ca)\n";

$in = $ARGV[0];

if (!$in) {
    die "Usage: bin2mif.pl FILE\n";
}

# open file
open (IN, $in);
binmode(IN);

print <<EOM;
DEPTH = 1024;
WIDTH = 128;
ADDRESS_RADIX = DEC;
DATA_RADIX = HEX;
CONTENT
BEGIN

EOM

# write rom data into Altera MIF format
$count = 0;

while (read(IN,$buf,4)) {
    $n = length($buf);
    $s = 2*$n;
    print $count . " : " . unpack("H$s",$buf) . ";\n";
    $count+=4;
}

print "END;\n";

# close file
close(IN);
