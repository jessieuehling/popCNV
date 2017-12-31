#!/bin/bash
#SBATCH -p short --ntasks 48 --nodes 1 --out logs/bamstats_gcbias.%a.log -J bamstats  --time 2:00:00 --mem 4G

module unload python
module load python/2.7.5
BAMLIST=all.bams.list
CPU=$SLURM_CPUS_ON_NODE
if [ ! $CPU ]; then 
 CPU=1
fi
N=${SLURM_ARRAY_TASK_ID}
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

mkdir -p $OUTDIR
mkdir -p $COVERAGEBIAS

file=$(ls $INDIR/*.bam | sed -n ${N}p)
 b=$(basename $file .bam)
 if [ ! -f $OUTDIR/$b.bamPEFragsize.txt ]; then
  bamPEFragmentSize -p $CPU --distanceBetweenBins $DISTANCE $file > $OUTDIR/$b.bamPEFragsize.txt
 fi
 if [ ! -f coverage/GCbiasCorrect/$b.gcbias ]; then
  computeGCBias --bam $file -freq $COVERAGEBIAS/$b.gcbias --biasPlot $COVERAGEBIAS/$b.plot.png \
  -p $CPU --genome $GENOME2BIT --effectiveGenomeSize $EFFECTIVE_GENOME_SIZE -l $FRAGMENTLENGTH
 fi
