#!/usr/bin/bash
#SBATCH --nodes 1 --ntasks 8 --mem 16G --time 2:00:00 -p short --out logs/init.log
mkdir -p logs

module load bwa/0.7.15
module load GEM
module load kent # need Jim Kent UCSC tools

CPU=$SLURM_CPUS_ON_NODE
pushd genome

if [ ! -e config.txt ]; then
 echo "Cannot run without a config file"
 exit
fi
source config.txt

if [ ! $GFFURL ]; then
 echo "need GFF variable in the config file"
 exit
fi
if [ ! $FASTAURL ]; then
 echo "need FASTA for genome in the config file"
 exit
fi
if [ ! $PREFIX ]; then
 echo "need PREFIX for this project/genome in the config file"
 exit
fi

GFF=$(basename $GFFURL)
FASTA=$(basename $FASTAURL)

if [ ! -f $GFF ]; then
 curl -o $GFF $GFFURL 
 # make sure genes are sorted
 grep -P "\tgene\t" $GFF | awk 'BEGIN{OFS="\t"} {print $1,$4,$5,$9}' | perl -p -e 's/ID=([^;]+);.+/$1/' | sort -k1,1 -k2,2n > $PREFIX.genes.bed
fi
if [ ! -f $FASTA ]; then
 curl -o $FASTA $FASTAURL 
 ln -s $FASTA $PREFIX.fasta
fi

if [ ! -f $PREFIX.amb ]; then
 bwa index -p $PREFIX $FASTA
fi

if [ ! -f $PREFIX.gem ]; then
 gem-indexer -i $PREFIX.fasta -o $PREFIX -T $CPU
fi

for size in 100 150 200 250 300;
do
   gem-mappability -I $PREFIX.gem -o $PREFIX.${size} -l $size -T 2
   gem-2-wig -I $PREFIX.gem -i $PREFIX.${size}.mappability -o $PREFIX.${size}
done

if [ ! -f $PREFIX.2bit ]; then
 faToTwoBit $PREFIX.fasta $PREFIX.2bit
fi
popd
