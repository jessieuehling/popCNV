#!/usr/bin/bash

#SBATCH --nodes 1 --ntasks 1 -p short --out logs/calcgenecoverage.%a.log

module load bedtools
module load samtools

CONFIG=config.txt

if [ ! -e $CONFIG ]; then
 echo "Need a config $CONFIG file"
 exit
fi
BAMLIST=all.bams.list
SAMPLELIST=samples.csv
INTERVAL_CHUNK_RUN=1000
COVERAGEDIR=coverage
GENECOVERAGEDIR=$COVERAGEDIR/gene_coverage

source $CONFIG

GENEBEDFILE=$GENOMEDIR/$PREFIX.genes.bed

mkdir -p $GENECOVERAGEDIR

N=${SLURM_ARRAY_TASK_ID}
if [ ! $N ]; then
 N=$1
 if [ ! $N ]; then
   echo "need an N to start, will use 1"
   N=1
 fi
fi

MAX=$(wc -l $GENEBEDFILE | awk '{print $1}')
START=$(python -c "print $N*$INTERVAL_CHUNK_RUN")
if [ $START -eq 0 ]; then
 START=1
fi
END=$(python -c "print ($N*$INTERVAL_CHUNK_RUN) + $INTERVAL_CHUNK_RUN- 1")
echo "START=$START END=$END"
for n in $(seq $START 1 $END);
do
 if [ $n -gt $MAX ]; then
   echo "reached end $MAX lines"
   exit
 fi
 sed -n ${n}p $GENEBEDFILE | while read CHR START END NAME;
 do
    # one coverage file per gene, each file has N 
    if [ ! -f $GENECOVERAGEDIR/$NAME.bamcoverage.tab ]; then
	if [ $DEBUG ]; then
	    echo "$CHR $START $END name=$NAME $GENECOVERAGEDIR/$NAME.bamcoverage.tab"
	fi
     samtools depth -r $CHR:$START-$END -f $BAMLIST \
 | perl scripts/depth2perlib_sum.pl -g $NAME -b $BAMLIST -s $SRA \
  > $GENECOVERAGEDIR/$NAME.bamcoverage.tab     
    fi
 done
done
