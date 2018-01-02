#!/bin/bash
#SBATCH --ntasks 24 --nodes 1
#SBATCH --out logs/bamgcbias.%a.log -J bamgcbias  --time 8:00:00 --mem 48G

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

mkdir -p $OUTDIR
mkdir -p $COVERAGEBIASDIR
mkdir -p $GCBIASCORBAMDIR

bamfile=$(ls $BAMDIR/*.bam | sed -n ${N}p)
b=$(basename $bamfile .bam)

if [ ! -f $OUTDIR/$b.bamPEFragsize.txt ]; then
  bamPEFragmentSize -p $CPU --distanceBetweenBins $SAMPLING_DISTANCE \
  $bamfile > $OUTDIR/$b.bamPEFragsize.txt
fi

# estimate GC bias 
if [ ! -f $COVERAGEBIASDIR/$b.plot.png ]; then
  computeGCBias --bam $file -freq $COVERAGEBIASDIR/$b.gcbias \
   --biasPlot $COVERAGEBIASDIR/$b.plot.png \
  -p $CPU --genome $GENOME2BIT \
  --effectiveGenomeSize $EFFECTIVE_GENOME_SIZE -l $FRAGMENT_LENGTH
fi

# generate GC-corrected bam file
mkdir -p $GCBIASCORBAMDIR

CORRECTEDBAM=$GCBIASCORBAMDIR/$b.bam
if [ ! -f $CORRECTEDBAM ]; then
    correctGCBias --bamfile $bamfile \
    --effectiveGenomeSize $EFFECTIVE_GENOME_SIZE \
    --GCbiasFrequenciesFile $COVERAGEBIASDIR/$b.gcbias \
    --correctedFile $CORRECTEDBAM --genome $GENOME2BIT
fi

# compute coverage stats

if [ ! -f  $OUTDIR/$b.bg ]; then
  bamCoverage --bam $CORRECTEDBAM -o $OUTDIR/$b.bg \
  -bs 50 -p $CPU -of bedgraph --normalizeTo1x $EFFECTIVE_GENOME_SIZE 
fi

