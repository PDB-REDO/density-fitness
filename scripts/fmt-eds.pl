#!/usr/bin/perl

use strict;
use warnings;

my $f = shift;

die "No such file $f\n" unless -f $f;

open(my $h, "<$f") or die "Could not open file $f: $!\n";

my $line = <$h>;

my @t = split(m/\s+/, $line);
my $nr = 0;
my %f_ix = map { $_ => $nr++ } @t;

print "RESIDUE\tRSR\tSRSR\tRSCCS\tNGRID\n";

while ($line = <$h>) {
	# print $line;
	chomp($line);

	my @f = split(m/\s+/, $line);

	my $res = "${f[0]}_${f[1]}_${f[2]}";

	my $rsr = 1.0 * $f[$f_ix{'Ra'}];
	my $srsr = 1.0 * $f[$f_ix{'SRGa'}];
	my $rsccs = 1.0 * $f[$f_ix{'CCSa'}];
	my $ngrid = int($f[$f_ix{'NPa'}]);

	# my ($r, $c, $n) = $line =~ m/(\w+)\s+(\w)\s+(\d+)/;
	# my $res = "${r}_${c}_${n}";

	# my $rsr = 1.0 * substr($line, 172, 5);
	# my $srsr = 1.0 * substr($line, 184, 5);
	# my $rsccs = 1.0 * substr($line, 191, 5);
	# my $ngrid = int(substr($line, 167, 4));

	print "${res}\t${rsr}\t${srsr}\t${rsccs}\t${ngrid}\n";
}
close($h);