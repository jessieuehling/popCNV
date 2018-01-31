#!/bin/bash

#SBATCH -p short --nodes 1 --ntasks 1 --mem 2G
#SBATCH --out logs/bamCov.%a.log -J bamCov

COVERAGEDIR=coverage

CONFIG=config.txt
if [ ! -e $CONFIG ]; then
 echo "Need a config.txt file"
 exit
fi
source $CONFIG

module load bedtools

BAMCOVERAGE=$COVERAGEDIR/bamCoverage
GENECOVERAGE=$COVERAGEDIR/geneCoverage
mkdir -p $GENECOVERAGE

N=${SLURM_ARRAY_TASK_ID}
CPU=1
if [ $SLURM_CPUS_ON_NODE ]; then
 CPU=$SLURM_CPUS_ON_NODE
fi

if [ ! $N ]; then
 N=$1
fi
MAX=$(ls $BAMCOVERAGE/*.bg.gz | wc -l | awk '{print $1}')

if [ $N -gt $MAX ]; then
 echo "$N is too big, only $MAX files in $BAMCOVERAGE folder"
 exit
fi
BEDGRAPH=$(ls $BAMCOVERAGE/*.bg.gz | sed -n ${N}p)
OUT=$(basename $BEDGRAPH | perl -p -e 's/\.bg(\.gz)?//')

if [ ! -f $GENECOVERAGE/$OUT.bed ]; then
  # -c 4 indicates the column used for computing depth
  bedtools map -a $GENOMEDIR/$PREFIX.genes.bed -b $BEDGRAPH -c 4 -o mean > $GENECOVERAGE/$OUT.bed
fi
