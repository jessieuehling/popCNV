#!/usr/bin/bash
#SBATCH --nodes 1 --ntasks 2 --mem 8G --time 12:00:00 

module load IQ-TREE
module load vcftools
TREEDIR=strain_tree
VCF=Variants_filter/A_fumigiatus_Af293.EVOL_AF100.selected.SNP.vcf
VCFTAB=Variants_filter/A_fumigiatus_Af293.EVOL_AF100.selected.SNP.tab
OUTFAS=$(basename $VCFTAB .tab)".fasaln"
BOOTSTRAPS=100

if [ ! -f $VCFTAB ]; then
 vcf-to-tab < $VCF > $VCFTAB
fi

mkdir -p $TREEDIR

if [ ! -f $TREEDIR/$OUTFAS ]; then
 perl scripts/vcftab_to_fasta.pl -o $TREEDIR/$OUTFAS $VCFTAB
fi

pushd $TREEDIR

iqtree-omp -nt 2 -s $OUTFAS -b $BOOTSTRAPS -m GTR+ASC

