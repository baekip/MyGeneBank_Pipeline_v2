#!/bin/bash

rs_list=$1
db_snp=/TBI/Share/HumanTeam/BioResource/hg19/dbsnp_137.hg19.vcf
output=$1\.output.txt

for rs_number in `cat $rs_list | cut -f 1`
do
    awk '{if ($3 == "$rs_number") print $1,$2,$3,$4,$5}' $db_snp >> $output
done
