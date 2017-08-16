#!/bin/bash
#$ -N snpeff.TN1701D2408
#$ -wd /TBI/Share/HumanTeam/BioProject/Oversea-WGS-2017-03-TBO170064/result/sh_log_file/11_snpeff_run//TN1701D2408/ 
#$ -pe smp 4
sample_id=$1
project_path=/TBI/Share/HumanTeam/BioPipeline/MyGeneBank_v1/example/test/
vcf_file=$project_path/$sample_id\.sorted.genome.PASS.vcf
log_file=$project_path/$sample_id\.log.file

exec >$log_file 2>&1

date
/usr/bin/java -Xmx4g -Djava.io.tmpdir=$project_path/tmp/ \
	-jar /TBI/Share/HumanTeam/BioTools/snpeff/snpEff_v4.2/snpEff.jar \
	-geneId \
	-c /TBI/Share/HumanTeam/BioTools/snpeff/snpEff_v4.2/snpEff.config \
	-v hg19 \
	-s $project_path/$sample_id\.snpeff.html \
	-o vcf \
	 $vcf_file | \

/usr/bin/java -Xmx4g -Djava.io.tmpdir=$project_path/tmp/ \
	-jar /TBI/Share/HumanTeam/BioTools/snpeff/snpEff_v4.2/SnpSift.jar \
	gwasCat -v - | \

/usr/bin/java -Xmx4g -Djava.io.tmpdir=$project_path/tmp/ \
	-jar /TBI/Share/HumanTeam/BioTools/snpeff/snpEff_v4.2/SnpSift.jar \
	varType -v - | \

/usr/bin/java -Xmx4g -Djava.io.tmpdir=$project_path/tmp/ \
	-jar /TBI/Share/HumanTeam/BioTools/snpeff/snpEff_v4.2/SnpSift.jar \
	annotate -noID -info COSMID -v /TBI/Share/HumanTeam/BioResource/DBs/COSMICDB/v71/CosmicCodingMuts.anno.vcf.gz - | \

/usr/bin/java -Xmx4g -Djava.io.tmpdir=$project_path/tmp/ \
	-jar /TBI/Share/HumanTeam/BioTools/snpeff/snpEff_v4.2/SnpSift.jar \
	annotate -dbsnp -v - | \

/usr/bin/java -Xmx4g -Djava.io.tmpdir=$project_path/tmp/ \
	-jar /TBI/Share/HumanTeam/BioTools/snpeff/snpEff_v4.2/SnpSift.jar \
	annotate -clinvar -v - | \

/usr/bin/java -Xmx4g -Djava.io.tmpdir=$project_path/tmp/ \
	-jar /TBI/Share/HumanTeam/BioTools/snpeff/snpEff_v4.2/SnpSift.jar \
	dbNSFP -v -  | \

/usr/bin/java -Xmx4g -Djava.io.tmpdir=$project_path/tmp/ \
	-jar /TBI/Share/HumanTeam/BioTools/snpeff/snpEff_v4.2/SnpSift.jar \
        annotate -v /TBI/Share/HumanTeam/BioResource/DBs/KRGDB/KRG1100_common_variants/total_variants1100_cmm_sort.vcf | \

/usr/bin/java -Xmx4g -Djava.io.tmpdir=$project_path/tmp/ \
	-jar /TBI/Share/HumanTeam/BioTools/snpeff/snpEff_v4.2/SnpSift.jar \
        annotate -v /TBI/Share/HumanTeam/BioResource/DBs/KRGDB/KRG1100_rare_variants/variants1100_rare_sort.vcf | \

/usr/bin/java -Xmx4g -Djava.io.tmpdir=$project_path/tmp/ \
	-jar /TBI/Share/HumanTeam/BioTools/snpeff/snpEff_v4.2/SnpSift.jar \
	annotate -v /TBI/Share/HumanTeam/BioResource/DBs/EXAC/release0.3/ExAC.r0.3.sites.vep.header.vcf.gz | sed "s/dbNSFP_GERP++/dbNSFP_GERP/g" | grep -v "hg38_chr" > $project_path/$sample_id\.snpeff.vcf 

cat $project_path/$sample_id\.snpeff.vcf | /TBI/Share/HumanTeam/BioTools/snpeff/snpEff_v4.2/scripts/vcfEffOnePerLine.pl | /usr/bin/java -Xmx4g \
	-Djava.io.tmpdir=$project_path/tmp/ \
	-jar /TBI/Share/HumanTeam/BioTools/snpeff/snpEff_v4.2/SnpSift.jar \
	extractFields -e "." - CHROM POS ID REF ALT FILTER VARTYPE \
	"GEN['$sample_id'].GT" "GEN['$sample_id'].AD" "GEN['$sample_id'].DP" \
	"ANN[*].EFFECT" \
	"ANN[*].IMPACT" \
	"ANN[*].GENE" \
	"ANN[*].FEATURE" \
	"ANN[*].FEATUREID" \
	"ANN[*].BIOTYPE" \
	"ANN[*].RANK" \
	"ANN[*].HGVS_C" \
	"ANN[*].HGVS_P" \
	"ANN[*].CDNA_POS" \
	"ANN[*].CDNA_LEN" \
	"ANN[*].CDS_POS" \
	"ANN[*].CDS_LEN" \
	"ANN[*].AA_POS" \
	"ANN[*].AA_LEN" \
	"ANN[*].DISTANCE" \
	GWASCAT_TRAIT \
	COSMID \
	"CLNDSDBID" \
	"CLNORIGIN" \
	"CLNSIG" \
	"CLNDBN" \
	"dbNSFP_Uniprot_acc" \
	"dbNSFP_Interpro_domain" \
	"dbNSFP_SIFT_pred" \
	"dbNSFP_Polyphen2_HDIV_pred" \
	"dbNSFP_Polyphen2_HVAR_pred" \
	"dbNSFP_LRT_pred" \
	"dbNSFP_MutationTaster_pred" \
	"dbNSFP_GERP___NR" \
	"dbNSFP_GERP___RS" \
	"dbNSFP_phastCons100way_vertebrate" \
	"dbNSFP_1000Gp1_AF" \
	"dbNSFP_1000Gp1_AFR_AF" \
	"dbNSFP_1000Gp1_EUR_AF" \
	"dbNSFP_1000Gp1_AMR_AF" \
	"dbNSFP_1000Gp1_ASN_AF" \
	"dbNSFP_ESP6500_AA_AF" \
	"dbNSFP_ESP6500_EA_AF" \
	"EXAC_AC" \
	"EXAC_AN" \
        "KRG_AF" \
        "KRG_Rare_AF" \
	> $project_path/$sample_id\.snpeff.tsv.tmp 
python /TBI/Share/HumanTeam/BioPipeline/Isaac_Pipeline_v1/script/../util/merge_isofrom_snv.py -i $project_path/$sample_id\.snpeff.tsv.tmp -o $project_path/$sample_id\.snpeff.isoform.tsv 
#python /TBI/Share/HumanTeam/BioPipeline/Isaac_Pipeline_v1/script/../util/write_xlsx_from_tsv.py -i $project_path/$sample_id\.snpeff.isoform.tsv -o $project_path/$sample_id\.snpeff.isoform.xlsx 
#python /TBI/Share/HumanTeam/BioPipeline/Isaac_Pipeline_v1/script/../util/write_xlsx_from_tsv.py -i $project_path/$sample_id\.snpeff.tsv.tmp -o $project_path/$sample_id\.snpeff.xlsx 
date
