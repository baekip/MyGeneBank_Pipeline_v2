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
    'date|d=s' => \$indate
);

my %info;
read_config ($config, \%info);

my $snpeff_input = "$input_path/$sample/$sample.snpeff.isoform.tsv";
my @snpeff_array = read_var($snpeff_input);

my $gene_input = $info{MGB_gene_list};
my @gene_array = read_var($gene_input);
my $gene_list = join '|', @gene_array;

my $clinvar_input = $info{MGB_clinvar_list};
my @clinvar_array = read_var($clinvar_input);
my $clinvar_list = join '|', @clinvar_array;


##1. grep snpeff from gene list
my @snpeff_vs_gene = grep (/$gene_list/, @snpeff_array);
my @snpeff_gene_vs_clinvar = grep (/$clinvar_list/, @snpeff_vs_gene);

##2. filter from KRGB, Clinvar, Cosmic
my $filter_out = "$output_path/Hereditary_Cancer_$sample.$indate.txt";
open my $fh_out, '>', $filter_out or die;

print $fh_out "dbSNP_ID\tGENE\tCLNDBN\tCLNSIG\n";
foreach my $line (@snpeff_gene_vs_clinvar){
    my @line_array = split /\t/, $line;
    my $chr = $line_array[0];
    my $rs_id = $line_array[2];
    my $ref = $line_array[3];
    my $alt = $line_array[4];
    my $gene = $line_array[12];
    my $clnsig = $line_array[30];
    my $clndbn = $line_array[31];
    my $COSMIC = $line_array[27];
    my $KRG_AF = $line_array[51];
#    print $chr."\n";
#    print $line."\n";
#    print $KRG_AF."\n";
#    print $COSMIC."\n";
    my @clndbn_array;
    my @clnsig_array;
    my %cln_hash;
    if ($KRG_AF eq "." && $COSMIC eq ".") {
        if ($clndbn =~ /,/ or $clndbn =~ /|/){
            @clndbn_array = split /[,|]+/, $clndbn;
        }else{
            push @clndbn_array, $clndbn;
        }if ($clnsig =~ /,/ or $clnsig =~ /|/){
            @clnsig_array = split /[,|]+/, $clnsig;
        }else{
            push @clnsig_array, $clnsig;
        }
    }
    if (scalar @clndbn_array == scalar @clnsig_array){
        for (my $i=0; $i<@clndbn_array; $i++){
            if ($clndbn_array[$i] =~ /Hereditary_cancer/ || $clndbn_array[$i] =~ /Familial/){
                my $cri = $clnsig_array[$i];
                my $critical;
                if ($cri eq "0" || $cri eq "1" || $cri eq "255"){
                    $critical = "L";
                }elsif ($cri eq "2"){
                    $critical  = "M"
                }elsif ($cri eq "3" || $cri eq "4" || $cri eq "6" || $cri eq "7"){
                    $critical = "H"
                }else {
                    die "ERROR! Check!! CLNSIG Number:$cri";
                }
                print $fh_out "$rs_id\t$gene\t$clndbn_array[$i]\t$critical\n";
#                print "$rs_id\t$gene\t$clndbn_array[$i]\t$criteria\n";
            }
#            $cln_hash{$i}->{cln_sig}=$clnsig_array[$i];
#            $cln_hash{$i}->{cln_dbn}=$clndbn_array[$i];
#            $cln_hash{$i}->{rs_id}=$rs_id;
        }
    }else{
        die "check your hash";
    }
#    print $fh_out "$rs_id\t$gene\t$clndbn$clnsig\n";
}close $fh_out;

$filter_out = "$output_path/Hereditary_Cancer_$sample.$indate.txt";
my $out_wc = `wc -l $filter_out`;
my ($wc, $name) = split /\s+/, $out_wc;
if ($wc eq "1") {
    checkFile ($filter_out);
    my $change_file = "$output_path/Hereditary_Cancer_No_Result_$sample.$indate.txt";
    my $cmd_mv = "mv $filter_out $change_file";
    system($cmd_mv);
}
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
