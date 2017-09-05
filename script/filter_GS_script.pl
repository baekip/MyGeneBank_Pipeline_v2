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

my $rs_input = $info{MGB_GS_list};
my @rs_array = read_var($rs_input);
my @rs_id_array;
my $strand_hash;
foreach my $rs_tmp (@rs_array){
    my ($rs, $strand, $rs_ref, $re_alt, $ori_ref) = split /\t/, $rs_tmp;
    $strand_hash->{$rs}=$strand;
    push @rs_id_array, $rs;
}

my @snpeff_vs_rs;
foreach my $check_rs (@rs_id_array) {
    push @snpeff_vs_rs, grep (/(\t+|rs(\d+);)$check_rs(\t+|;rs(\d+)+)/, @snpeff_array);
}


## write GS output
my $GS_out = "$output_path/GeneStyle_$sample.$indate.csv";
open my $fh_GS, '>:encoding(utf8)', $GS_out or die;

foreach my $rs_line (@rs_array){
    my ($rs, $strand, $rs_ref, $rs_alt, $ori_ref) =  split /\t/, $rs_line;
    my @intersect_snpeff = grep {/(\t+|rs(\d+);)$rs(\t+|\;rs(\d+)+)/} @snpeff_vs_rs;
    if (scalar @intersect_snpeff == 1) {
        foreach my $row (@intersect_snpeff) {
            my ($chr, $pos, $id, $ref, $alt, $qual, $filter, $info, $format, $default) = split /\t/, $row;
            my ($GT,$GQ,$GQX,$DP,$DPF,$AD) = split /\:/, $default;
            
            if ($rs eq "rs1799750") {
                $ref = "2G";
                $alt = "1G";
            }
            if ($strand eq "-"){
                $ref=$nucle_reverse{$ref};
                $alt=$nucle_reverse{$alt};
            }

            if ($GT eq "1/1"){
                print $fh_GS "$rs,$alt$alt\n";
            }else { 
                print $fh_GS "$rs,$ref$alt\n";
            }
        }
    }elsif (scalar @intersect_snpeff == 0){
        print $fh_GS "$rs,$ori_ref$ori_ref\n";
    }else{
        print $rs."\n";
        die "Error!! Check your snpeff file <$snpeff_input>\n";
    }
}
close $fh_GS;

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
