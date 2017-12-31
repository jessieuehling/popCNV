#!/usr/bin/bash
#SBATCH --nodes 1 --ntasks 1 --mem 8G --time 2-0:0:0

module load samtools
BAMLIST=all.bams.list
STRAINS=strains.tab
OUTDIR=coverage/depth
INFOLDER=coverage/bamCoverage
DEPTHFILE=$OUTDIR/strain.bamcov_depths.tab
mkdir -p $OUTDIR

if [ ! -f $DEPTHFILE ]; then
 ./scripts/bamCov2meandepth.py $INFOLDER/*.bg > $DEPTHFILE
fi

perl scripts/combine_coverage_by_chrom.pl
