#!/bin/bash

sample_id=$1
project_path=/TBI/Share/HumanTeam/BioPipeline/MyGeneBank_v1/example/test/
bedtools=/TBI/Tools/bedtools/current/bin/bedtools
bed_file=/TBI/Share/HumanTeam/BioPipeline/MyGeneBank_v1/gene_list/gene.list.revise.bed
vcf_file=$project_path/$sample_id\.sorted.genome.PASS.vcf

$bedtools \
    intersect \
    -header \
    -a $vcf_file \
    -b $bed_file
