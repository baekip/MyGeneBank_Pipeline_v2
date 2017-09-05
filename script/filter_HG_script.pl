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
    my ($rs, $strand, $rs_ref, $re_alt, $ori_ref) = split /\t/, $rs_tmp;
    $strand_hash2->{$rs}=$strand;
    push @rs_id_array2, $rs;
}

my @snpeff_vs_rs2;
foreach my $check_rs (@rs_id_array2){
    push @snpeff_vs_rs2, grep (/(\t+|rs(\d);)$check_rs(\t+|;rs(\d+)+)/, @snpeff_array);
}

## write HG2 output
my $HG_out2 = "$output_path/HelloGene_V2_$sample.$indate.csv";
open my $fh_HG2, '>:encoding(utf8)', $HG_out2 or die;

foreach my $rs_line (@rs_array2){
    my ($rs, $strand, $rs_ref, $rs_alt, $ori_ref) =  split /\t/, $rs_line;
    my @intersect_snpeff2 = grep {/(\t+|rs(\d+);)$rs(\t+|\;rs(\d+)+)/} @snpeff_vs_rs2;
    if (scalar @intersect_snpeff2 == 1) {
        foreach my $row (@intersect_snpeff2) {
            my ($chr, $pos, $id, $ref, $alt, $qual, $filter, $info, $format, $default) = split /\t/, $row;
            my ($GT,$GQ,$GQX,$DP,$DPF,$AD) = split /\:/, $default;
            
            if ($strand eq "-"){
                $ref=$nucle_reverse{$ref};
                $alt=$nucle_reverse{$alt};
            }
        
            if ($GT eq "1/1"){
                print $fh_HG2 "$rs,$alt$alt\n";
            }else {
                print $fh_HG2 "$rs,$ref$alt\n";
            }
        }
    }elsif (scalar @intersect_snpeff2 == 0){
        print $fh_HG2 "$rs,$ori_ref$ori_ref\n";
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
    my ($rs, $strand, $rs_ref, $re_alt, $ori_ref) = split /\t/, $rs_tmp;
    $strand_hash3->{$rs}=$strand;
    push @rs_id_array3, $rs;
}

my @snpeff_vs_rs3;
foreach my $check_rs (@rs_id_array3){
    push @snpeff_vs_rs3, grep (/(\t+|rs(\d+);)$check_rs(\t+|;rs(\d+)+)/, @snpeff_array);
}

##write HG3 output
my $HG_out3 = "$output_path/HelloGene_V3_$sample.$indate.csv";
open my $fh_HG3, '>:encoding(utf8)', $HG_out3 or die;

foreach my $rs_line (@rs_array3){
    my ($rs, $strand, $rs_ref, $rs_alt, $ori_ref) =  split /\t/, $rs_line;
    my @intersect_snpeff3 = grep {/(\t+|rs(\d+);)$rs(\t+|\;rs(\d+)+)/} @snpeff_vs_rs3;
    if (scalar @intersect_snpeff3 == 1) {
        foreach my $row (@intersect_snpeff3) {
            my ($chr, $pos, $id, $ref, $alt, $qual, $filter, $info, $format, $default) = split /\t/, $row;
            my ($GT,$GQ,$GQX,$DP,$DPF,$AD) = split /\:/, $default;
            
            if ($strand eq "-"){
                $ref=$nucle_reverse{$ref};
                $alt=$nucle_reverse{$alt};
            }
            
            if ($GT eq "1/1"){
                print $fh_HG3 "$rs,$alt$alt\n";
            }else {
                print $fh_HG3 "$rs,$ref$alt\n";
            }
        }
    }elsif (scalar @intersect_snpeff3 == 0){
        print $fh_HG3 "$rs,$ori_ref$ori_ref\n";
    }else{
        print $rs."\n";
        die "Error!! Check your snpeff file <$snpeff_input>\n";
    }
}
close $fh_HG3;

###sub###
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
