#!/usr/bin/bash

#SBATCH -p short --nodes 1 --ntasks 24 --mem 64G
#SBATCH --out logs/bamCov.%a.log -J bamCov

BAMLIST=all.bams.list
OUTDIR=coverage/bamCoverage
mkdir -p $OUTDIR
N=${SLURM_ARRAY_TASK_ID}
CPU=1
if [ $SLURM_CPUS_ON_NODE ]; then
 CPU=$SLURM_CPUS_ON_NODE
fi

if [ ! -e config.txt ]; then
 echo "Need a config.txt file"
 exit
fi
INDIR=aln
OUTDIR=reports
COVERAGEDIR=coverage
DISTANCE=10000
EFFECTIVE_GENOME_SIZE=28115088
FRAGMENTLENGTH=200
source config.txt
COVERAGEBIAS=$COVERAGEDIR/GCbiasCorrect
GENOME2BIT=$GENOMEDIR/$PREFIX.2bit

if [ ! $N ]; then
 N=$1
fi

if [ ! $N ]; then
 echo "need to provide a number by --array slurm or on the cmdline"
 exit
fi

MAX=`wc -l $BAMLIST | awk '{print $1}'`

if [ $N -gt $MAX ]; then
 echo "$N is too big, only $MAX lines in $BAMLIST"
 exit
fi
BAM=$(sed -n ${N}p $BAMLIST)
OUT=$(basename $BAM .bam)
if [ ! -f  $OUTDIR/$OUT.bg ]; then
 bamCoverage -b $BAM -o $OUTDIR/$OUT.bg -bs 50 -p $CPU -of bedgraph --ignoreDuplicates
fi
