#!/usr/bin/bash

#SBATCH --mem 4G --ntasks 8 --nodes 1 -J bwa 
#SBATCH --out logs/bwa.%a.log --time 8:00:00

module load bwa/0.7.15
module unload java
module load java/8
module load picard
SAM_CN_CENTER=UNK
CONFIG=config.txt
GENOMEDIR=genome
READSDIR=input
BAMDIR=aln
TEMP=/scratch
SAMPLELIST=samples.csv
if [ ! -f $CONFIG ]; then
 echo "Need a $CONFIG file to proceed"
 exit
fi

GENOME=$GENOMEDIR/$PREFIX
mkdir -p $BAMDIR

N=${SLURM_ARRAY_TASK_ID}
CPU=1
if [ $SLURM_CPUS_ON_NODE ]; then 
 CPU=$SLURM_CPUS_ON_NODE
fi

if [ ! $N ]; then
 N=$1
fi

if [ ! $N ]; then 
 echo "need to provide a number by --array or cmdline"
 exit
fi

MAX=`wc -l $SAMPLELIST | awk '{print $1}'`

if [ $N -gt $MAX ]; then 
 echo "$N is too big, only $MAX lines in $SAMPLELIST"
 exit
fi

IFS=,
sed -n ${N}p $SAMPLELIST | while read STRAIN FWD REV;
do
  LIBRARY=$(basename $FWD .fastq.gz)
  LIBRARY1=$(basename $FWD .fastq.gz)
  LIBRARY2=$(basename $REV .fastq.gz)
  PAIR1=${INDIR}/$LANE/${LIBRARY1}_val_1.fq.gz
  PAIR2=${INDIR}/$LANE/${LIBRARY2}_val_2.fq.gz
  
  echo "... files are $PAIR1 $PAIR2 $LIBRARY"
  SAMFILE=NULL
   
  if [ -f $PAIR2 ]; then
   SAMFILE=$OUTDIR/${STRAIN}.PE.unsrt.sam
   echo "SAMFILE is $SAMFILE"
   if [ ! -f $SAMFILE ]; then
	bwa mem -t $CPU -R "@RG\tID:$STRAIN\tSM:$STRAIN\tLB:$LIBRARY\tPL:illumina\tCN:$CENTER" $GENOME $PAIR1 $PAIR2 > $SAMFILE
   fi 
   if [ ! -f $OUTDIR/${STRAIN}.PE.bam ]; then
	samtools fixmate -O bam $SAMFILE $TEMP/${STRAIN}.fixmate.bam
	samtools sort -O bam -o  $OUTDIR/${STRAIN}.PE.bam -T $TEMP $TEMP/${STRAIN}.fixmate.bam
	/usr/bin/rm $TEMP/${STRAIN}.fixmate.bam
   fi
  else
   SAMFILE=$OUTDIR/${ID}.SE.unsrt.sam
   echo "SAMFILE is $SAMFILE"
   if [ ! -f $SAMFILE ]; then
    	bwa mem -t $CPU -R "@RG\tID:$STRAIN\tSM:$STRAIN\tLB:$LIBRARY\tPL:illumina\tCN:Seqmatic" $GENOME $PAIR1 > $SAMFILE
   fi
   if [ ! -f $OUTDIR/${STRAIN}.SE.bam ]; then
	samtools view -b $SAMFILE > $TEMP/${STRAIN}.unsrt.bam	
	samtools sort -O bam -o $OUTDIR/${STRAIN}.SE.bam -T $TEMP $TEMP/${STRAIN}.unsrt.bam
	/usr/bin/rm $TEMP/${STRAIN}.unsrt.bam
    fi
 fi
 done
done
