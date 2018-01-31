#!/usr/bin/perl

use strict;
use warnings;
use File::Spec;
use Getopt::Long;

my ($bamlist,$srainfo,$gene);
GetOptions('b|bamlist:s'  => \$bamlist,
	   's|srastrain:s' => \$srainfo,
	   'g|gene:s'      => \$gene,
    );

if( ! $gene ) {
    warn("No gene provided\n");
    $gene = 'DEFAULT';
}
if ( ! $bamlist || ! -f $bamlist ) {
    die "need the bamlist";
}



my %info2strain;
if( $srainfo ) {
    open(my $fh => $srainfo) || die $!;
    while(<$fh>) {
	next if /^\#/;
	#my ($proj,$run,$sample,$strain,$lib,$geo) = split;
	my ($info,$strain) = split;
	$info2strain{$info} = $strain;
	#$info2strain{$run} = $strain;
	#$info2strain{$sample} = $strain;
    }
}

my @bamfiles;
open(my $fh => $bamlist) || die $!;
while(<$fh>) {
    my (undef,undef,$file) = File::Spec->splitpath($_);
    my ($base);
    if ($file =~ /(\S+)\.realign\.bam/) {
	my ($libname) = ($1);
	my $strain = $info2strain{$libname} || $libname;
	push @bamfiles, [$file,$strain];
    } else {
	warn("cannot parse $file\n");
    }
}
my %suminfo;
my $bases = 0;
while(<>) {
    my ($chr,$pos,@matches) = split;
    my $i = 0;
    for my $m ( @matches ) {
	$suminfo{$bamfiles[$i]->[1]} += $m;
	$i++;
    }
    $bases++;
}
print join("\t", '#GENE',qw(LENGTH), sort keys %suminfo), "\n";
print join("\t", $gene, $bases, map { sprintf("%.2f",$suminfo{$_} / $bases) } sort keys %suminfo),"\n";
