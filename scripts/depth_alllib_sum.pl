#!/usr/bin/perl

use strict;
use warnings;
use File::Spec;
use Getopt::Long;
use List::Util qw(sum);

my ($bamlist,$srainfo);
GetOptions('b|bamlist:s'  => \$bamlist,
	   's|srastrain:s' => \$srainfo);

if ( ! $bamlist || ! -f $bamlist ) {
    die "need the bamlist";
}

my %info2strain;
if( $srainfo ) {
    open(my $fh => $srainfo) || die $!;
    while(<$fh>) {
	next if /^\#/;
	chomp;
	my ($strain) = split(/[\t,]/,$_);
	$info2strain{$strain} = $strain;
    }
}
my %suminfo;
open(my $fh => $bamlist) || die $!;
while(<$fh>) {
    my (undef,$bdir,$file) = File::Spec->splitpath($_);
    my ($base);
    if ($file =~ /(\S+)\.bam/) {
	my ($libname) = ($1);
	$libname =~ s/realign\.//;
	my $strain = $info2strain{$libname} || $libname;
	open(my $depthfh => "$bdir/$strain.depth") || die "cannot open $bdir/$strain.depth";
	my @depths;
	while(<$depthfh>) {
	 next if /^mito|MT_|\#/;
	 my @row = split;
         push @depths,$row[1];
	}
	$suminfo{$strain} = sprintf("%.2f",sum(@depths) / scalar @depths);
    } else {
	warn("cannot parse $file\n");
    }
}
print join("\t", '#STRAIN',qw(AVG_COVERAGE)),"\n";
for my $strain ( sort keys %suminfo ) {
 # add in read count later on perhaps
    print join("\t", $strain, $suminfo{$strain}),"\n";
}
