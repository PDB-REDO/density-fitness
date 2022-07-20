#!/usr/bin/perl

use strict;
use warnings;
use POSIX;

my %FIELDS = (
	RSR => 0,
	SRSR => 1,
	RSCCS => 2,
	NGRID => 3,
	EDIAm => 4,
	OPIA => 5 
);

# die "Usage: plot-eds.pl FILE1 FILE2 <fld>\n" unless $#ARGV == 1;

my $f1 = shift;		die "$f1 bestaat niet: $!\n" unless defined $f1 and -f $f1;
my $f2 = shift;		die "$f1 bestaat niet: $!\n" unless defined $f1 and -f $f2;
my $field = shift;	$field = 'RSCCS' unless defined $field;

my $fld = $FIELDS{$field};

print "using field ${field}\n";

my %data;
my $min = $fld == $FIELDS{'NGRID'} ? 1e6 : 1.0;
my $max = $fld == $FIELDS{'NGRID'} ? 0 : 1.0;

open(my $h, "<", $f1) or die "Kon $f1 niet openen: $!\n";
while (my $line = <$h>) {
	next if $line =~ m/^RESIDUE\s/;
	my ($id, @v) = split(m/\t/, $line);
	
	my %e = (
		"v1" => $v[$fld] * 1.0
	);
	
	$data{$id} = \%e;
}
close($h);

open($h, "<", $f2) or die "Kon $f2 niet openen: $!\n";
while (my $line = <$h>) {
	next if $line =~ m/^RESIDUE\s/;
	my ($id, @v) = split(m/\t/, $line);
	
	next unless defined $data{$id};
	
	$data{$id}->{"v2"} = $v[$fld] * 1.0;
}
close($h);

my $data_file = `mktemp /tmp/eds-data-XXXXXXXX`;
chomp($data_file);
open($h, ">", $data_file) or die "Kon $data_file niet aanmaken: $!\n";
foreach my $key (keys %data) {
	next unless defined $data{$key}->{"v2"};
	
print "min: $min, max: $max, v1: $data{$key}->{v1}, v2: $data{$key}->{v2}\n";
	$min = $data{$key}->{"v1"} if $min > $data{$key}->{"v1"};
	$min = $data{$key}->{"v2"} if $min > $data{$key}->{"v2"};

	$max = $data{$key}->{"v1"} if $max < $data{$key}->{"v1"};
	$max = $data{$key}->{"v2"} if $max < $data{$key}->{"v2"};

	print $h join("\t", $key, $data{$key}->{"v1"}, $data{$key}->{"v2"}), "\n";
}
close($h);

$min = 0.1 * int($min * 10);
$max = 10 * int(POSIX::ceil($max / 10)) if $fld == $FIELDS{'NGRID'};

my $svg_file = `mktemp /tmp/svg-plot-XXXXXXXX`;
chomp $svg_file;

my $l1=$f1;	$l1 =~ s/_/-/g;
my $l2=$f2;	$l2 =~ s/_/-/g;

open($h, "|gnuplot -p > $svg_file") or die "Kon gnuplot niet opstarten: $!\n";
print $h <<EOF;
set terminal svg mouse standalone
set size square
set termoption enhanced

# define axis
# remove border on top and right and set color to gray
set style line 11 lc rgb '#707070' lt 1
set border 3 back ls 11
set tics nomirror

# define grid
set style line 12 lc rgb '#707070' lt 0 lw 1
set grid back ls 12

set style line 1 lc rgb '#8b1a0e' pt 1 ps 1 lt 1 lw 2 # --- red

set xlabel "$l1"
set ylabel "$l2"

set xrange [$min:$max]
set yrange [$min:$max]

f(x) = a*x+b
fit f(x) '$data_file' using 2:3 via a,b

stats '$data_file' using 2:3 name "S"

plot '$data_file' using 2:3:1 with labels hypertext point pt 7 ps 0.25 title 'eds vergelijking voor ${field}', f(x) with lines title sprintf('f(x) = %.2f * x + %.2f, R = %.2f', a, b, S_correlation) ls 1
EOF
close($h);

unlink($data_file);
system("firefox $svg_file");

