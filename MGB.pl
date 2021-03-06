#!/usr/bin/perl

=head1 Name
    
    MGB.pl -- MGB WGS pipeline script

=head1 Version
    
    Author: baekip (inpyo.baek@theragenetex.com)
    Version: 2.1
    Date: 2017-06-13 Tue

=head1 Usage

    perl pipeline.pl [option] file
        -c: input config <wgs.config.txt>
        -p: input pipeline <wgs.pipeline.txt>
        -h: output help information to screen

=head1 Subscript

    - isaac_pre.pl, 2017-02-21
    - fastqc.pl, 2017-02-22
    - isaac.pl, 2017-02-22
    - starling_pre.pl, 2017-02-23
    - starling.pl, 2017-02-23
    - gvcftools.pl, 2017-02-23
    - qualimap.pl, 2017-02-24
    - qualimap_stat.pl, 2017-02-28
    - statistics.pl, 2017-02-28
        .
        .
        .

=head1 Example

    perl MGB.pl -c wgs.config.txt -p wgs.pipeline.txt

=cut

use strict;
use warnings;
use Getopt::Long;
use File::Basename;
use Cwd qw(abs_path);
use lib dirname(abs_path $0) . '/library';
use Utils qw (read_config checkFile make_dir checkDir trim);
use Queue qw (CheckQsub pipe_arrange program_run);

my $pipeline_path = dirname(abs_path $0);
my $config = "$pipeline_path/config/wgs.MGB.config.txt";
checkFile($config);
my $pipeline = "$pipeline_path/config/wgs.MGB.pipeline.txt";
checkFile($pipeline);

my $help;
GetOptions (
#    'config=s' => \$config,
#    'pipeline=s' => \$pipeline,
    'help=s' => \$help
);

die `pod2text $0` if ( $help);
#die `pod2text $0` if (!defined $config || !defined $pipeline || $help);

#$pipeline = (abs_path $pipeline);
#$config  = (abs_path $config);

my %info;
read_config ($config, \%info);

#############################################################
#Requirement config source 
#############################################################
my $script_path = "$pipeline_path/script/";
my $project_path = $info{project_path};
my $rawdata_path = $info{rawdata_path};
my $result_path = $info{result_path};
my $project_id = $info{project_id};
my $sh_path = sprintf ('%s/sh_log_file', $result_path);
my $flag_orig_path = sprintf ('%s/flag_file/', $result_path);
my $log_path="$project_path/log/";
make_dir($log_path);
checkDir ($script_path);
make_dir($result_path);
make_dir($sh_path);

#############################################################
#STD IN config 
#############################################################
print "#############################################################\n";
print "#             MGB.pl -- MGB WGS pipeline V2 script          #\n";
print "#############################################################\n\n";
print "1. 샘플이름:";
my $sample_id = <STDIN>;
chomp $sample_id;
trim ($sample_id);
print "#############################################################\n\n";

print "2. 입고일시:";
my $indate = <STDIN>;
chomp $indate;
trim ($indate);
print "#############################################################\n";

my $log_file="$log_path/$sample_id\.log.file";
my @sample_list;
push @sample_list, $sample_id;
#############################################################
#Requirement config source 
#############################################################

read_pipeline_config ($config, $pipeline);
use Data::Dumper;

my @pipe_list;
sub read_pipeline_config{
    my ($config_config, $pipeline_config) = @_;
    open my $fh_pipe, '<:encoding(UTF-8)', $pipeline_config or die;
    while (my $row = <$fh_pipe>){
        chomp $row;
        if ($row =~ /^#|^\s+/) {next;}
        if (length $row == 0) {next;}
        push @pipe_list, $row;
    }
    close $fh_pipe;
}

my %pipe_hash;
pipe_arrange ($pipeline, \%pipe_hash);

open my $fh_log, '>', $log_file or die;
my $startdatestring = localtime();
print "------------------------------------------------------------------\n";
print "<Sample Name: $sample_id> START MGB WGS Pipeline: $startdatestring\n";
print "------------------------------------------------------------------\n";

print $fh_log "------------------------------------------------------------------\n";
print $fh_log "<Sample Name: $sample_id> START MGB WGS Pipeline: $startdatestring\n";
print $fh_log "------------------------------------------------------------------\n";

foreach my $row (@pipe_list){
    my $input_path;
    my ($order, $input_order, $program, $option, $type, $cluster, $threads) = split /\s+/, $row;
    if ($option =~ /,/){
        my @option_list = split /\,/, $option;
        $option = $option_list[0];
    }else{ }

    if ($input_order =~ /,/){
        my @input_list = split /\,/, $input_order;
        $input_order = join (",", @input_list);
    }else{ }

    if ($input_order eq '00'){ 
        $input_path = $rawdata_path; 
    }elsif ($input_order =~ /,/){
        my @input_list = split /\,/, $input_order;
        my @input_path_list;
        foreach my $input (@input_list){
            if ($input eq '00') { 
                $input_path = $rawdata_path;
            }push @input_path_list, sprintf ("%s/%s", $result_path, $pipe_hash{$input});
        }
        $input_path = join (",", @input_path_list);
    }else{
        $input_path = sprintf ("%s/%s", $result_path, $pipe_hash{$input_order});
    }
   
###flag start
    my $script = sprintf ("%s/%s.pl", $script_path, $program);
    my $output_path = sprintf ("%s/%s/", $result_path, $pipe_hash{$order});
    my $sh_program_path = sprintf ("%s/%s/", $sh_path, $pipe_hash{$order});
    my $flag_in = sprintf ("%s/%s/%s_flag.txt", $flag_orig_path, $pipe_hash{$order}, $pipe_hash{$order});
    my @flag_list;
    my $datestring=localtime();
    
    print "#PROCESS: $order-$program\n"; 
    print $fh_log "\#$order-$program PROCESS START: $datestring\n";
    
    if (-e $flag_in){
        open my $fh_in, '<:encoding(UTF-8)', $flag_in or die;
        while (my $row = <$fh_in>){
            chomp $row;
            push @flag_list, $row;
        }close $fh_in;
    }
    if ($cluster eq 'multisample') { 
        @sample_list = 'multisample';
    }
    my %flag_hash = map {$_ => 1} @flag_list;
    my @run_sample = grep (!defined $flag_hash{$_}, @sample_list);
    my @exist_sample = grep ($flag_hash{$_}, @sample_list);
    if (@run_sample == 0) {
        print "-------------------------------------------------------\n";
        print "Exist Flag $order: $datestring\n";
        print "-------------------------------------------------------\n";
        next;
    }

    my @job_list;
    my @run_list; 
    
    my $flag_path = sprintf ("%s/%s/", $flag_orig_path, $pipe_hash{$order});
    make_dir($flag_path);
    my $flag_file = sprintf ("%s/%s_flag.txt", $flag_path, $pipe_hash{$order});
    open my $fh_flag, '>', $flag_file or die;
    if ($cluster eq 'sample'){ 
        foreach my $sample (@run_sample){
            if ($type eq 'private'){
                my $program_bin = 'perl_script';
                my $cmd = program_run ($script, $program_bin, $input_path, $sample, $sh_program_path, $output_path, $threads, $config, $indate);
                my @stdout = qx($cmd);
                my $qlist = join (" ", @stdout);
                my @qjobsplit = split /\s/, $qlist;
                my @qlist = grep (/^\d+$/, @qjobsplit);
                push @job_list, @qlist;
                push @run_list, @exist_sample, $sample;
            }elsif ($type eq 'public'){
                my $program_bin = $info{$program};
                my $cmd = program_run ($script, $program_bin, $input_path, $sample, $sh_program_path, $output_path, $threads, $config, $indate);
                my @stdout = qx($cmd);
                my $qlist = join ("", @stdout);
                my @qjobsplit = split /\s/, $qlist;
                my @qlist = grep (/^\d+$/, @qjobsplit);
                push @job_list, @qlist;
                push @run_list, @exist_sample, $sample;
            }else {
                die "ERROR!! Check your pipeline configre <Order Number: $order> type option";
            }
        }
    }elsif ($cluster eq 'multisample') {
        my $sample = 'multisample';
        if ($type eq 'private'){
            my $program_bin = 'perl_script';
            my $cmd = program_run ($script, $program_bin, $input_path, $sample, $sh_program_path, $output_path, $threads, $config, $indate);
            my @stdout = qx($cmd);
            my $qlist = join (" ", @stdout);
            my @qjobsplit = split /\s/, $qlist;
            my @qlist = grep (/^\d+$/, @qjobsplit);
            push @job_list, @qlist;
            push @run_list, @exist_sample, $sample;
        }elsif ($type eq 'public'){
            my $program_bin = $info{$program};
            my $cmd = program_run ($script, $program_bin, $input_path, $sample, $sh_program_path, $output_path, $threads, $config, $indate);
            my @stdout = qx($cmd);
            my $qlist = join ("", @stdout);
            my @qjobsplit = split /\s/, $qlist;
            my @qlist = grep (/^\d+$/, @qjobsplit);
            push @job_list, @qlist;
            push @run_list, @exist_sample, $sample;
        }else {
            die "ERROR!! Check your pipeline configre <Order Number: $order> type option";
        }
    }else {
        die "ERROR! Check your pipeline config sample category <$order>";
    }
    CheckQsub(@job_list);
    print $fh_flag join ("\n", sort(@run_list));
    my $subenddatestring=localtime();
    print $fh_log "#$order-$program PROCESS END: $subenddatestring\n";
    close $fh_flag;
}
my $enddatestring = localtime();
print "-------------------------------------------------------\n";
print "END MGB WGS Pipeline: $enddatestring\n";
print "-------------------------------------------------------\n";

print $fh_log "--------------------------------------------------------------\n";
print $fh_log "<Sample Name: $sample_id> END MGB WGS Pipeline: $enddatestring\n";
print $fh_log "--------------------------------------------------------------\n";
close $fh_log;
