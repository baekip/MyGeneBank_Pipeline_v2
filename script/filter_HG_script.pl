#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use Sys::Hostname;
use Cwd qw(abs_path);
use Data::Dumper;
use File::Basename qw(dirname);
use lib dirname (abs_path $0) . '/../library';
use Utils qw(make_dir checkFile read_config cmd_system trim);

my ($input_path, $output_path, $config, $sample, $indate); 

GetOptions (
    'input|i=s' => \$input_path,
    'output|o=s' => \$output_path,
    'config|c=s' => \$config,
    'sample|s=s' => \$sample,
    'date|d=s' =>\$indate
);

my %info;
read_config ($config, \%info);


my %nucle_reverse = (
    "A" => "T",
    "C" => "G",
    "G" => "C",
    "T" => "A",
);

my $snpeff_input = "$input_path/$sample/$sample.snpeff.vcf";
my @snpeff_array = read_var($snpeff_input);

####################################################################################
# HelloGene Version 2.0
####################################################################################

my $rs_input2 = $info{MGB_HG_list_v2};
my @rs_array2 = read_var($rs_input2);
my @rs_id_array2;
my $strand_hash2;

foreach my $rs_tmp (@rs_array2){
    my ($rs, $strand, $rs_ref, $re_alt) = split /\t/, $rs_tmp;
    $strand_hash2->{$rs}=$strand;
    push @rs_id_array2, $rs;
}
my $rs_id_list2 = join '|', @rs_id_array2;
my @snpeff_vs_rs2 = grep (/$rs_id_list2/, @snpeff_array);

## write HG2 output
my $HG_out2 = "$output_path/HelloGene_V2_$sample.$indate.csv";
open my $fh_HG2, '>:encoding(utf8)', $HG_out2 or die;

foreach my $rs_line (@rs_array2){
    my ($rs, $strand, $rs_ref, $rs_alt) =  split /\t/, $rs_line;
#    my @intersect_snpeff = grep {/$rs/i} @snpeff_array;
    my @intersect_snpeff2 = grep {/$rs\t+/i} @snpeff_vs_rs2;
    if (scalar @intersect_snpeff2 == 1) {
        print $fh_HG2 "$rs,$rs_ref$rs_alt\n";
    }elsif (scalar @intersect_snpeff2 == 0){
        $rs_alt = $rs_ref;
        print $fh_HG2 "$rs,$rs_ref$rs_alt\n";
    }else{
        print $rs."\n";
        die "Error!! Check your snpeff file <$snpeff_input>\n";
    }
}
close $fh_HG2;


####################################################################################
# HelloGene Version 3.0
####################################################################################

my $rs_input3 = $info{MGB_HG_list_v3};
my @rs_array3 = read_var($rs_input3);
my @rs_id_array3;
my $strand_hash3;
foreach my $rs_tmp (@rs_array3){
    my ($rs, $strand, $rs_ref, $re_alt) = split /\t/, $rs_tmp;
    $strand_hash3->{$rs}=$strand;
    push @rs_id_array3, $rs;
}
my $rs_id_list3 = join '|', @rs_id_array3;
my @snpeff_vs_rs3 = grep (/$rs_id_list3/, @snpeff_array);
#print Dumper ($strand_hash);

##write HG3 output
my $HG_out3 = "$output_path/HelloGene_V3_$sample.$indate.csv";
open my $fh_HG3, '>:encoding(utf8)', $HG_out3 or die;

foreach my $rs_line (@rs_array3){
    my ($rs, $strand, $rs_ref, $rs_alt) =  split /\t/, $rs_line;
#    my @intersect_snpeff = grep {/$rs/i} @snpeff_array;
    my @intersect_snpeff3 = grep {/$rs\t+/i} @snpeff_vs_rs3;
    if (scalar @intersect_snpeff3 == 1) {
        print $fh_HG3 "$rs,$rs_ref$rs_alt\n";
    }elsif (scalar @intersect_snpeff3 == 0){
        $rs_alt = $rs_ref;
        print $fh_HG3 "$rs,$rs_ref$rs_alt\n";
    }else{
        print $rs."\n";
        die "Error!! Check your snpeff file <$snpeff_input>\n";
    }
}
close $fh_HG3;
#my $rs_list = join '|', @rs_id_array;

##1. grep snpeff from gene list
#my @snpeff_vs_rs = grep (/$rs_list/, @snpeff_array);

##2. filter from KRGB, Clinvar, Cosmic

#foreach my $line (@snpeff_vs_rs){
#    my @line_array = split /\t/, $line;
#    my $chr = $line_array[0];
#    my $rs_id = $line_array[2];
#    my $ref = $line_array[3];
#    my $alt = $line_array[4];
#    my $COSMIC = $line_array[27];
#    my $KRG_AF = $line_array[51];
##    print $chr."\n";
##    print $line."\n";
##    print $KRG_AF."\n";
##    print $COSMIC."\n";
#    print "$rs_id,$ref$alt\n";
##    print $fh_HG "$rs_id,$ref$alt\n";
#}
#foreach my $line (@snpeff_gene_vs_rs) {
#    my @line_array = split /\t/, $line;
#    my $rs_id = $line_array[2];
#    my $ref = $line_array[3];
#    my $alt = $line_array[4];
#    print $fh_HG "$rs_id,$alt\n";
#    print $fh_GS "$rs_id,$alt\n";
#}

#
#foreach (@snpeff_gene_vs_rs) {
#    print "$_\n";
#}

#my %rs_hash;
#while (my $row = <$fh_rs>){
#    chomp $row;
#    if ($row =~ /^#/) {next;}
#    if (length($row) == 0) {next;}
#    my ($rs, $risk, $non_risk) = split /\t/, $row;
#    $rs_hash{$rs}->{risk}=trim($risk);
#    $rs_hash{$rs}->{non_risk}=trim($non_risk);
#}

sub read_var {
    my $file =  shift;
    my @array;
    open my $fh, '<:encoding(UTF-8)', $file or die;
    while (my $row = <$fh>){
        chomp $row;
        if ($row =~ /^#/) {next;}
        $row = trim($row);
        push @array, $row;
    }
    close $fh;
    return @array;
}
