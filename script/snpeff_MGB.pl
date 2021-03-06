#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use Cwd qw(abs_path);
use Sys::Hostname; 
use File::Basename qw(dirname);
use lib dirname (abs_path $0) . '/../library';
use Utils qw(make_dir checkFile read_config cmd_system);


my ($script, $program, $input_path, $sample, $sh_path, $output_path, $threads, $option, $config_file, $indate);

GetOptions (
    'script|S=s' => \$script,
    'program|p=s' => \$program,
    'input_path|i=s' => \$input_path,
    'sample_id|S=s' => \$sample,
    'log_path|l=s' => \$sh_path,
    'output_path|o=s' => \$output_path,
    'threads|t=s' => \$threads,
    'option|r=s' => \$option,
    'config|c=s' => \$config_file,
    'date|d=s' => \$indate
);

my $hostname=hostname;
#my $queue;
#if ( $host eq 'eagle'){
#    $queue = 'isaac.q';
#}else{
#    $queue = 'all.q';
#}


##################################################################################
# Requirement Value
##################################################################################
make_dir ($sh_path);
make_dir ($output_path);
$input_path="$input_path/$sample/";
my $sh_file = sprintf ('%s/%s', $sh_path, "snpeff.MGB.$sample.sh");

my %info;
read_config ($config_file, \%info);
my $script_path = dirname(abs_path $0);
my $reference = $info{reference};
my $java = $info{java_1_7};
my $tmp_dir = sprintf ("%s/tmp/", $output_path);
make_dir ($tmp_dir);
my $snpeff = $info{snpeff};
my $snpsift = $info{snpsift};
my $snpeff_config = $info{snpeff_config};
my $snpeff_db = $info{snpeff_db};
my $cosmic_db = $info{cosmic_db};
my $KRG1100_db = $info{KRG1100_db};
my $KRG1100_rare_db = $info{KRG1100_rare_db};
my $exac_db = $info{exac_db};
my $vcf_per_line = $info{vcf_per_line};
##################################################################################
# make a run script
##################################################################################
open my $fh_sh, '>', $sh_file or die;
print $fh_sh "#!/bin/bash\n";
print $fh_sh "#\$ -N snpeff.MGB.$sample\n";
print $fh_sh "#\$ -wd $sh_path \n";
print $fh_sh "#\$ -pe smp $threads\n";
#print $fh_sh "#\$ -q $queue\n";
print $fh_sh "date\n";

printf $fh_sh ("%s -Xmx%dg -Djava.io.tmpdir=%s \\\n", $java, $threads, $tmp_dir);
printf $fh_sh ("\t-jar %s \\\n", $snpeff);
printf $fh_sh ("\t-geneId \\\n");
printf $fh_sh ("\t-c %s \\\n", $snpeff_config);
printf $fh_sh ("\t-v %s \\\n", $snpeff_db);
printf $fh_sh ("\t-s %s/%s.snpeff.html \\\n", $output_path, $sample);
printf $fh_sh ("\t-o vcf \\\n"); 
printf $fh_sh ("\t %s/%s.bedtools.MGB.vcf \| \\\n\n", $input_path, $sample);

printf $fh_sh ("%s -Xmx%dg -Djava.io.tmpdir=%s \\\n", $java, $threads, $tmp_dir);
printf $fh_sh ("\t-jar %s \\\n", $snpsift);
printf $fh_sh ("\tgwasCat -v - \| \\\n\n");

printf $fh_sh ("%s -Xmx%dg -Djava.io.tmpdir=%s \\\n", $java, $threads, $tmp_dir);
printf $fh_sh ("\t-jar %s \\\n", $snpsift);
printf $fh_sh ("\tvarType -v - \| \\\n\n");

printf $fh_sh ("%s -Xmx%dg -Djava.io.tmpdir=%s \\\n", $java, $threads, $tmp_dir);
printf $fh_sh ("\t-jar %s \\\n", $snpsift);
printf $fh_sh ("\tannotate -noID -info COSMID -v %s - \| \\\n\n", $cosmic_db);

printf $fh_sh ("%s -Xmx%dg -Djava.io.tmpdir=%s \\\n", $java, $threads, $tmp_dir);
printf $fh_sh ("\t-jar %s \\\n", $snpsift);
printf $fh_sh ("\tannotate -dbsnp -v - \| \\\n\n");

printf $fh_sh ("%s -Xmx%dg -Djava.io.tmpdir=%s \\\n", $java, $threads, $tmp_dir);
printf $fh_sh ("\t-jar %s \\\n", $snpsift);
printf $fh_sh ("\tannotate -clinvar -v - \| \\\n\n");

printf $fh_sh ("%s -Xmx%dg -Djava.io.tmpdir=%s \\\n", $java, $threads, $tmp_dir);
printf $fh_sh ("\t-jar %s \\\n", $snpsift);
printf $fh_sh ("\tannotate -v %s  \| \\\n\n", $KRG1100_db);

printf $fh_sh ("%s -Xmx%dg -Djava.io.tmpdir=%s \\\n", $java, $threads, $tmp_dir);
printf $fh_sh ("\t-jar %s \\\n", $snpsift);
printf $fh_sh ("\tannotate -v %s  \| \\\n\n", $KRG1100_rare_db);

printf $fh_sh ("%s -Xmx%dg -Djava.io.tmpdir=%s \\\n", $java, $threads, $tmp_dir);
printf $fh_sh ("\t-jar %s \\\n", $snpsift);
printf $fh_sh ("\tdbNSFP -v -  \| \\\n\n");

printf $fh_sh ("%s -Xmx%dg -Djava.io.tmpdir=%s \\\n", $java, $threads, $tmp_dir);
printf $fh_sh ("\t-jar %s \\\n", $snpsift);
printf $fh_sh ("\tannotate -v %s \| sed \"s/dbNSFP_GERP++/dbNSFP_GERP/g\" \| grep -v \"hg38_chr\" > %s \n\n", $exac_db, "$output_path/$sample.snpeff.vcf");

printf $fh_sh ("cat %s \| %s | %s -Xmx%dg \\\n", "$output_path/$sample.snpeff.vcf", $vcf_per_line, $java, $threads);
printf $fh_sh ("\t-Djava.io.tmpdir=%s \\\n", $tmp_dir);
printf $fh_sh ("\t-jar %s \\\n", $snpsift);
printf $fh_sh ("\textractFields -e \".\" - CHROM POS ID REF ALT FILTER VARTYPE \\\n");
printf $fh_sh ("\t\"GEN[\'%s\'].GT\" \"GEN[\'%s\'].AD\" \"GEN['%s'].DP\" \\\n", $sample, $sample, $sample);
printf $fh_sh ("\t\"ANN[*].EFFECT\" \\\n");
printf $fh_sh ("\t\"ANN[*].IMPACT\" \\\n");
printf $fh_sh ("\t\"ANN[*].GENE\" \\\n");
printf $fh_sh ("\t\"ANN[*].FEATURE\" \\\n");
printf $fh_sh ("\t\"ANN[*].FEATUREID\" \\\n");
printf $fh_sh ("\t\"ANN[*].BIOTYPE\" \\\n");
printf $fh_sh ("\t\"ANN[*].RANK\" \\\n");
printf $fh_sh ("\t\"ANN[*].HGVS_C\" \\\n");
printf $fh_sh ("\t\"ANN[*].HGVS_P\" \\\n");
printf $fh_sh ("\t\"ANN[*].CDNA_POS\" \\\n");
printf $fh_sh ("\t\"ANN[*].CDNA_LEN\" \\\n");
printf $fh_sh ("\t\"ANN[*].CDS_POS\" \\\n");
printf $fh_sh ("\t\"ANN[*].CDS_LEN\" \\\n");
printf $fh_sh ("\t\"ANN[*].AA_POS\" \\\n");
printf $fh_sh ("\t\"ANN[*].AA_LEN\" \\\n");
printf $fh_sh ("\t\"ANN[*].DISTANCE\" \\\n");
printf $fh_sh ("\tGWASCAT_TRAIT \\\n");
printf $fh_sh ("\tCOSMID \\\n");
printf $fh_sh ("\t\"CLNDSDBID\" \\\n");
printf $fh_sh ("\t\"CLNORIGIN\" \\\n");
printf $fh_sh ("\t\"CLNSIG\" \\\n");
printf $fh_sh ("\t\"CLNDBN\" \\\n");
printf $fh_sh ("\t\"dbNSFP_Uniprot_acc\" \\\n");
printf $fh_sh ("\t\"dbNSFP_Interpro_domain\" \\\n");
printf $fh_sh ("\t\"dbNSFP_SIFT_pred\" \\\n");
printf $fh_sh ("\t\"dbNSFP_Polyphen2_HDIV_pred\" \\\n");
printf $fh_sh ("\t\"dbNSFP_Polyphen2_HVAR_pred\" \\\n");
printf $fh_sh ("\t\"dbNSFP_LRT_pred\" \\\n");
printf $fh_sh ("\t\"dbNSFP_MutationTaster_pred\" \\\n");
printf $fh_sh ("\t\"dbNSFP_GERP___NR\" \\\n");
printf $fh_sh ("\t\"dbNSFP_GERP___RS\" \\\n");
printf $fh_sh ("\t\"dbNSFP_phastCons100way_vertebrate\" \\\n");
printf $fh_sh ("\t\"dbNSFP_1000Gp1_AF\" \\\n");
printf $fh_sh ("\t\"dbNSFP_1000Gp1_AFR_AF\" \\\n");
printf $fh_sh ("\t\"dbNSFP_1000Gp1_EUR_AF\" \\\n");
printf $fh_sh ("\t\"dbNSFP_1000Gp1_AMR_AF\" \\\n");
printf $fh_sh ("\t\"dbNSFP_1000Gp1_ASN_AF\" \\\n");
printf $fh_sh ("\t\"dbNSFP_ESP6500_AA_AF\" \\\n");
printf $fh_sh ("\t\"dbNSFP_ESP6500_EA_AF\" \\\n");
printf $fh_sh ("\t\"EXAC_AC\" \\\n");
printf $fh_sh ("\t\"EXAC_AN\" \\\n");
printf $fh_sh ("\t\"KRG_AF\" \\\n");
printf $fh_sh ("\t\"KRG_Rare_AF\" \\\n");

printf $fh_sh ("\t> %s \n", "$output_path/$sample.snpeff.tsv.tmp");
printf $fh_sh ("python %s -i %s -o %s \n", "$script_path/util/merge_isofrom_snv.py", "$output_path/$sample.snpeff.tsv.tmp", "$output_path/$sample.snpeff.isoform.tsv");
#printf $fh_sh ("python %s -i %s -o %s \n", "$script_path/util/write_xlsx_from_tsv.py", "$output_path/$sample.snpeff.isoform.tsv", "$output_path/$sample.snpeff.isoform.xlsx");
#printf $fh_sh ("python %s -i %s -o %s \n", "$script_path/util/write_xlsx_from_tsv.py", "$output_path/$sample.snpeff.tsv.tmp", "$output_path/$sample.snpeff.xlsx");


print $fh_sh "date\n";
close $fh_sh;
cmd_system ($sh_path, $hostname, $sh_file);
