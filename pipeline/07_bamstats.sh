#!/bin/bash
#SBATCH --ntasks 24 --nodes 1
#SBATCH --out logs/bamgcbias.%a.log -J bamgcbias --time 24:00:00 --mem 24G 

# THIS REQUIRES DEEPTOOLS https://github.com/deeptools/deepTools

CONFIG=config.txt
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

if [ ! -e $CONFIG ]; then
 echo "Need a config.txt ($CONFIG) file"
 exit
fi
BAMDIR=aln
GCBIASCORBAMDIR=$BAMDIR/GCbiascor
OUTDIR=reports
COVERAGEDIR=coverage
SAMPLING_DISTANCE=10000

FRAGMENT_LENGTH=200

source $CONFIG

if [ ! $EFFECTIVE_GENOME_SIZE ]; then
 echo "Need EFFECTIVE_GENOME_SIZE variable set in config"
 exit
fi

if [ ! $PREFIX ]; then
 echo "Need PREFIX set whi\ch would have generated index files in 00_init.sh"
 exit
fi

COVERAGEBIASDIR=$COVERAGEDIR/GCbiasCorrect
GENOME2BIT=$GENOMEDIR/$PREFIX.2bit
BAMCOVDIR=$COVERAGEDIR/bamCoverage

mkdir -p $OUTDIR
mkdir -p $COVERAGEBIASDIR
mkdir -p $GCBIASCORBAMDIR
mkdir -p $BAMCOVDIR

base=$(basename $BAM .bam)

if [ ! -f $OUTDIR/$base.bamPEFragsize.txt ]; then
  bamPEFragmentSize -p $CPU --distanceBetweenBins $SAMPLING_DISTANCE \
  $BAM > $OUTDIR/$base.bamPEFragsize.txt
fi

# estimate GC bias 
if [ ! -f $COVERAGEBIASDIR/$base.plot.png ]; then
  computeGCBias --bam $BAM -freq $COVERAGEBIASDIR/$base.gcbias \
   --biasPlot $COVERAGEBIASDIR/$base.plot.png \
  -p $CPU --genome $GENOME2BIT \
  --effectiveGenomeSize $EFFECTIVE_GENOME_SIZE -l $FRAGMENT_LENGTH 
fi

# generate GC-corrected bam file
mkdir -p $GCBIASCORBAMDIR

CORRECTEDBAM=$GCBIASCORBAMDIR/$base.bam
if [ ! -f $CORRECTEDBAM ]; then
    correctGCBias --bamfile $BAM \
    --effectiveGenomeSize $EFFECTIVE_GENOME_SIZE \
    --GCbiasFrequenciesFile $COVERAGEBIASDIR/$base.gcbias \
    --correctedFile $CORRECTEDBAM --genome $GENOME2BIT
fi

# compute coverage stats

#if [ ! -f  $BAMCOVDIR/$base.bg.gz ]; then
#  bamCoverage --bam $CORRECTEDBAM -o $BAMCOVDIR/$base.bg \
#  -bs 10 -p $CPU -of bedgraph --normalizeTo1x $EFFECTIVE_GENOME_SIZE 
#  pigz $BAMCOVDIR/$base.bg
#fi

