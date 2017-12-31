#!/usr/bin/bash

#SBATCH --nodes 1 --ntasks 1 -p short --out logs/calcgenecoverage.%a.log

module load bedtools
module load samtools
BEDFILE=genome/Af293.genes.bed
BAMLIST=all.bams.list
SRA=Af100_samples.csv
OUTDIR=coverage/gene_coverage
mkdir -p $OUTDIR
RANGE=1000
N=${SLURM_ARRAY_TASK_ID}
if [ ! $N ]; then
 N=$1
 if [ ! $N ]; then
   echo "need an N to start, will use 1"
   N=1
 fi
fi

MAX=$(wc -l $BEDFILE | awk '{print $1}')
START=$(python -c "print $N*$RANGE")
if [ $START -eq 0 ]; then
 START=1
fi
END=$(python -c "print ($N*$RANGE) + $RANGE - 1")
echo "START=$START END=$END"
for n in $(seq $START 1 $END);
do
 if [ $n -gt $MAX ]; then
   echo "reached end $MAX lines"
   exit
 fi
 sed -n ${n}p $BEDFILE | while read CHR START END NAME;
 do
    echo "$CHR $START $END name=$NAME"
    # one coverage file per gene, each file has N 
    if [ ! -f $OUTDIR/$NAME.bamcoverage.tab ]; then
   #   echo "will run on $NAME.bamcoverage.tab"
     samtools depth -r $CHR:$START-$END -f $BAMLIST | perl scripts/depth2perlib_sum.pl -g $NAME -b $BAMLIST -s $SRA > $OUTDIR/$NAME.bamcoverage.tab     
    fi
 done
done
