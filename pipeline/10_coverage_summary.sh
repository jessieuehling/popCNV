#!/usr/bin/bash
#SBATCH --nodes 1 --ntasks 1 --mem 8G --time 2-0:0:0
module load BBMap

module load samtools
BAMLIST=all.bams.list
STRAINS=strains.tab
OUTDIR=coverage/depth
INFOLDER=coverage/bamCoverage
DEPTHFILE=$OUTDIR/strain.bamcov_depths.tab
mkdir -p $OUTDIR

if [ ! -f $DEPTHFILE ]; then
  for bam in $(cat $BAMLIST)
  do
   dname=$(dirname $bam)
   b=$(basename $bam .bam)
   if [ ! -f $dname/$b.depth ]; then
    pileup.sh in=$bam out=$dname/$b.depth
   fi
  done
fi
perl scripts/depth_alllib_sum.pl -b all.bams.list -s Af100_samples.csv   > coverage/depth/strain.depths.tab
#perl scripts/combine_coverage_by_chrom.pl
