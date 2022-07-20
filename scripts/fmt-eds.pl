#!/usr/bin/perl

use strict;
use warnings;

my $f = shift;

die "No such file $f\n" unless -f $f;

open(my $h, "<$f") or die "Could not open file $f: $!\n";

my $line = <$h>;
print "RESIDUE\tRSR\tSRSR\tRSCCS\tNGRID\n";

while ($line = <$h>) {
	# print $line;
	chomp($line);

	my ($r, $c, $n) = $line =~ m/(.{3})\s+(\w)\s+(\d+)/;
	my $res = "${r}_${c}_${n}";

	my $rsr = 1.0 * substr($line, 172, 5);
	my $srsr = 1.0 * substr($line, 184, 5);
	my $rsccs = 1.0 * substr($line, 191, 5);
	my $ngrid = int(substr($line, 167, 4));

	print "${res}\t${rsr}\t${srsr}\t${rsccs}\t${ngrid}\n";
}
close($h);