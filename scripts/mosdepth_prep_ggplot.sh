#!/bin/bash

# this may need to be customized
for WINDOW in 5000 10000 50000;
do
 for file in coverage/mosdepth/*.${WINDOW}bp.regions.bed.gz
 do
 b=$(basename $file .${WINDOW}bp.regions.bed.gz )
 GROUP=$(echo $b)
# echo "$GROUP $b"
 mean=$(zcat $file | awk '{total += $4} END { print total/NR}') 
 zcat $file | awk 'BEGIN{OFS="\t"} {print $1,$2,$3,$4/'$mean','\"$GROUP\"','\"$b\"'}' 
 done > coverage/mosdepth.${WINDOW}bp.gg.tab
done
