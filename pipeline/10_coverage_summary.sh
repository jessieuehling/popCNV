#!/bin/bash
#SBATCH --nodes 1 --ntasks 16 --mem 8G --time 2-0:0:0 --out logs/coveragesummary.log

module load BBMap
module load samtools

CPU=$SLURM_CPUS_ON_NODE
if [ ! $CPU ]; then
 CPU=2
fi

PARALLELJOBS=$(expr $CPU / 2)
BAMLIST=all.bams.list
COVERAGEDIR=coverage

SAMPLELIST=samples.csv
CONFIG=config.txt

if [ ! -e $CONFIG ]; then
  echo "MISSING config.txt, using defaults for this tool"
else
 source $CONFIG
fi

DEPTHCOVERAGEDIR=$COVERAGEDIR/depth

if [ $DEPTHFILE ]; then
    DEPTHFILE=$DEPTHCOVERAGEDIR/$DEPTHFILE
else
    DEPTHFILE=$DEPTHCOVERAGEDIR/strain.depths.tab
fi
mkdir -p $DEPTHCOVERAGEDIR

pileup() {
    bam=$1
    dname=$(dirname $bam)
    b=$(basename $bam .bam)
    if [ ! -f $dname/$b.depth ]; then
	pileup.sh in=$bam out=$dname/$b.depth >& $dname/$b.pileup.log
    fi
}
export -f pileup

cat $BAMLIST | parallel -j $PARALLELJOBS pileup

# need to move this script folder to be easier to find
if [ ! -f $DEPTHFILE ]; then
 perl scripts/depth_alllib_sum.pl -b $BAMLIST -s $SAMPLELIST > $DEPTHFILE
fi
#perl scripts/combine_coverage_by_chrom.pl
