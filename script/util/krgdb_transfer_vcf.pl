#!/usr/bin/perl

=head1 Usage

    perl krgdb_transfer_vcf.pl [option] file
        -i: input text file (krg.*.txt)
        -o: output vcf file (*.vcf)
        -h: output help information to screen 

=cut

use strict;
use warnings;
use Getopt::Long;

my ($input, $output, $help);
GetOptions (
    'input|i=s' => \$input,
    'output|o=s' => \$output,
    'help=s' => \$help
);
die `pod2text $0` if (!defined $input || !defined $output || $help);

open my $fh_in, '<:encoding(UTF-8)', $input or die;
my @column;
my @total_column;
while (my $row =  <$fh_in>) {
    chomp $row;
    $row = trim ($row);
    if ($row =~ /^#/) {next;}
    if (length $row == 0) {next;}
    push @total_column, $row; 
}

open my $fh_out, '>', $output or die;
print $fh_out "##fileformat=VCFv4.1\n";
print $fh_out "##INFO=<ID=KRG_AF,Number=A,Type=Float,Description=\"Allele Frequency, for each ALT allele, in the same order as listed\">\n";
print $fh_out "#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\n";

foreach my $row (@total_column) {
    my @my_row = split /\t/, $row;
    my $alt_freq = $my_row[6];
    my @total_alt_list = split /\,/, $alt_freq; 
    if (@total_alt_list == 2)  {
        my ($alt_freq_1) = split /\,/, $alt_freq;
        my ($alt_1, $val_1) = split /\:/, $alt_freq_1;
        my $real_alt = trim ($alt_1);
        $val_1 = trim ($val_1);
        my $val = "KRG_AF=$val_1";
        print $fh_out "$my_row[0]\t$my_row[1]\t$my_row[2]\t$my_row[4]\t$real_alt\t\.\t\.\t$val\n";
    }elsif( @total_alt_list > 2 ){
        my @alt_list;
        my @val_list; 
        foreach (@total_alt_list) {
            my $temp_string = trim ($_);
            my ($alt, $val) = split /\:/, $temp_string;
            $alt = trim ($alt);
            $val = trim ($val);
            push @alt_list, $alt;
            push @val_list, $val;
        }
        @alt_list = trim (@alt_list);
        @val_list = trim (@val_list);
        my $real_alt = join (",", @alt_list);
        my $real_val = join (",", @val_list);
        $real_alt =~ s/,$//; #replace comma at the end of the string with empt
        $real_val =~ s/,$//; 
        $real_val = "KRG_AF=$real_val";
        print $fh_out "$my_row[0]\t$my_row[1]\t$my_row[2]\t$my_row[4]\t$real_alt\t\.\t\.\t$real_val\n";
    }
}
close $fh_out;

sub trim {
    my @result = @_;

    foreach (@result){
        s/^\s+//;
        s/\s+$//;
    }

    return wantarray ? @result : $result[0];
}





