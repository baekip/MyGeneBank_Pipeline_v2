#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use Sys::Hostname;
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use lib dirname (abs_path $0) . '/../library';
use Utils qw(make_dir checkFile read_config cmd_system);

my ($input, $output, $config, $sample, $threads, $indate); 

GetOptions (
    'input|i=s' => \$input,
    'output|o=s' => \$output,
    'config|c=s' => \$config,
    'sample|s=s' => \$sample,
    'threads|t=s' => \$threads,
    'date|d=s' => \$indate
);

my %info;
read_config ($config, \%info);
$output="$output/../../../MGB_result/$sample.$indate/";
if ( -d $output ) {
    `rm -rf $output`
}
my $cmd_mkdir = "mkdir -p $output";
system ($cmd_mkdir);

my @input_array = split /\,/, $input;
foreach my $path (@input_array){
    my $input_path = "$path/$sample"; 
    cp_file("$input_path/*$indate*", "$output/.");
} 

sub cp_file {
    my ($in_file, $out_file) = @_;
#    checkFile($in_file);
    make_dir($out_file);
    my $cp_cmd = "cp -r $in_file $out_file";
    system ($cp_cmd);
}

sub SoftLink{
    my ($in_file, $out_file) = @_;
#    checkFile($in_file);
    my $output_dir = dirname ($out_file);
    make_dir($output_dir);
    my $link_cmd = "ln -s $in_file $out_file";
    system ($link_cmd);
}
