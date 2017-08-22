#!/bin/bash

list=$1
bam_file=/TBI/Share/HumanTeam/BioProject/MGB_Test/result/04_starling_pre_orig/KPGP-00265/KPGP-00265.bam
output=$1\.output.list

for pos in `cat $1`
do
    samtools tview $bam_file -d T -p $pos | head -n 3 | tail -n 1 >> $output
done
