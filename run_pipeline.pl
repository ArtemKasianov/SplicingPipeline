#! /usr/bin/perl

use Getopt::Long;
use File::Spec;
use warnings;
use strict;

## GETTING OPTIONS ##

my $option_list = $ARGV[0];

my $fastq_files = '';
my @fastq_list = ();
my $reference = '';
my $splice = '';
my $annotation_bed = '';

my $output_dir = '';
my $output_prefix = '';

my $cutadapt_options = '';
my $minimap2_options = '';
my $samtools_view_options = '';
my $samtools_sort_options = '';

if ($option_list eq '') {
	print "Specify the options' file!\n";
	exit;
}
unless (-e $option_list ) {
	print "The specified options' file $option_list not found!\n";
	exit;
}

open (OPTS, '<', $option_list) or die;
my @opts_file = <OPTS>;
for (my $i=0;$i<=$#opts_file;$i++) {
	if ($opts_file[$i] =~ /^!input FASTQ-file/) {
		$fastq_files = $opts_file[$i+1];
		$fastq_files =~ s/\r?\n//;
		@fastq_list = split/,/, $fastq_files;
	} elsif ($opts_file[$i] =~ /^!input reference FATSA-file/) {
		$reference = $opts_file[$i+1];
		$reference =~ s/\r?\n//;
	} elsif ($opts_file[$i] =~ /^!input list of splice-sites/) {
		$splice = $opts_file[$i+1];
		$splice =~ s/\r?\n//;
	} elsif ($opts_file[$i] =~ /^!input annotation in BED-format/) {
		$annotation_bed = $opts_file[$i+1];
		$annotation_bed =~ s/\r?\n//;
	} elsif ($opts_file[$i] =~ /^!output directory/) {
		$output_dir = $opts_file[$i+1];
		$output_dir =~ s/\r?\n//;
	} elsif ($opts_file[$i] =~ /^!output prefix/) {
		$output_prefix = $opts_file[$i+1];
		$output_prefix =~ s/\r?\n//;
	} elsif ($opts_file[$i] =~ /^!cutadapt options/) {
		$cutadapt_options = $opts_file[$i+1];
		$cutadapt_options =~ s/\r?\n//;
	} elsif ($opts_file[$i] =~ /^!minimap2 options/) {
		$minimap2_options = $opts_file[$i+1];
		$minimap2_options =~ s/\r?\n//;
	} elsif ($opts_file[$i] =~ /^!samtools view options/) {
		$samtools_view_options = $opts_file[$i+1];
		$samtools_view_options =~ s/\r?\n//;
	} elsif ($opts_file[$i] =~ /^!samtools sort options/) {
		$samtools_sort_options = $opts_file[$i+1];
		$samtools_sort_options =~ s/\r?\n//;
	}
}
close OPTS;

## Error messages for the options ##

if ($fastq_files eq '') {
	print "No input FASTQ-files specified!\n";
	exit;
}

foreach my $file (@fastq_list) {
	unless (-e $file) {
		print "The specified FASTQ-file $file is not found!\n";
		exit;
	}
}

if ($reference eq '') {
	print "No input FASTA specified!\n";
	exit;
}

unless (-e $reference) {
	print "The specified FASTA-file $reference is not found!\n";
	exit;
}

if ($splice eq '') {
	print "No input list of splice-sites specified!\n";
	exit;
}

unless (-e $splice) {
	print "The specified list of splice-sites $splice is not found!\n";
	exit;
}

if ($output_dir ne '') {
	$output_dir = $output_dir.'/' if ($output_dir !~ /\/$/);
	unless (-d $output_dir) {
		print "The specified output folder not found! Creating the folder for you.\n";
		system ("mkdir $output_dir");
	}
}

if ($annotation_bed eq '') {
	print "No input annotation in BED-format specified!\n";
	exit;
}

unless (-e $annotation_bed) {
	print "The specified annotation $annotation_bed is not found!\n";
	exit;
}

## GETTING PATHS TO ALL NEEDED TOOLS ##
## By default, they are all supposed to be in PATH ##

my $path = File::Spec->rel2abs( __FILE__ );
$path =~ s/run_pipeline\.pl$//;
my $configuration_file = $path.'CONFIGURATION.txt';
print "$configuration_file\n";
open (my $CONFIGURE, '<', $configuration_file) or die "Configuration file not found!\n";
my @configure = <$CONFIGURE>;
close $CONFIGURE;

my $cutadapt = $configure[4];
my $minimap2 = $configure[6];
my $samtools = $configure[8];
my $bam2bigg = $configure[10];
my $bedtools = $configure[12];

$cutadapt =~ s/\r?\n//;
$minimap2 =~ s/\r?\n//;
$samtools =~ s/\r?\n//;
$bam2bigg =~ s/\r?\n//;
$bedtools =~ s/\r?\n//;

my $make_list_of_genes = $path.'1-make_list_of_genes.pl';
my $get_reads_for_expressed_genes = $path.'2-get_reads_for_expressed_genes.pl';
my $splice_sites_detection = $path.'3-splice-sites_detection.pl';
my $make_peak_counts_per_gene = $path.'4-make_peak_counts_per_gene.pl';
my $level1_starts_script = $path.'promoterpipeline_level1_starts.pl';
my $level1_ends_script = $path.'promoterpipeline_level1_ends.pl';
my $level2_script = $path.'promoterpipeline_level2.py';
my $sort_peaks_by_coverage = $path.'5-sort_peaks_by_coverage.pl';
my $finalize_isoforms = $path.'6-finalize_isoforms.pl';

## MAPPING ALL INPUT FILES AND SORTING THE MAPPINGS ##

my $list_of_bedtools = '';

for (my $i=0;$i<=$#fastq_list;$i++) {

	my $fastq = $fastq_list[$i];

	## PREPARING READS FOR MAPPING ##

	print "\nPREPARING READS FOR MAPPING\n";

	my $cutadapt_output = $output_dir.$output_prefix.$i.'.READS.TRIM.fasta';

	if ($cutadapt eq 'cutadapt') {
	
		system ("$cutadapt $cutadapt_options -o $cutadapt_output $fastq");
	} else {
		system ("python3 $cutadapt $cutadapt_options -o $cutadapt_output $fastq");
	}

	## MAPPING ##

	print "\nMAPPING\n";

	my $minimap2_output = $output_dir.$output_prefix.$i.'.MINIMAP2';
	my $samtools_output = $output_dir.$output_prefix.$i.'.MAPPING.bam';
	my $bigg_mappings = $output_dir.$output_prefix.$i.'.MAPPING.NANO.bed';
	my $bedtools = $output_dir.$output_prefix.$i.'.MAPPING.NANO.bedtools';

	system ("$minimap2 $minimap2_options $reference $cutadapt_output > $minimap2_output");
	system ("$samtools view $samtools_view_options $minimap2_output | $samtools sort $samtools_sort_options - > $samtools_output");
	system ("$samtools index $samtools_output");
	system ("$bam2bigg -b $samtools_output -o $bigg_mappings -s 0");
	system ("bedtools intersect -a $bigg_mappings -b $annotation_bed -wa -wb -f 0.8 > $bedtools");
	
	$list_of_bedtools = $bedtools if ($list_of_bedtools eq '');
	$list_of_bedtools = $list_of_bedtools.' '.$bedtools if ($list_of_bedtools ne '');
}

## SORTING MAPPINGS BY 10x COVERAGE PER GENE ##

my $sorted_genes_list = $output_dir.'sorted_genes.txt';
system ("perl $make_list_of_genes $annotation_bed $list_of_bedtools > $sorted_genes_list");
system ("perl $get_reads_for_expressed_genes $sorted_genes_list $list_of_bedtools");

## DIVIDING MAPPINGS AND SEARCHING FOR SPLICE-SITES IN THE READS ##

my $list_of_final_mappings = '';
my $list_of_splicing_files = '';
my $final_mappings = '';
my $divided_mappings = '';

for (my $i=0;$i<=$#fastq_list;$i++) {

	print "\nDIVIDING MAPPINGS\n";
	
	$final_mappings = $output_dir.$output_prefix.$i.'.MAPPING.NANO.bed_sorted';
	$divided_mappings = $output_dir.$output_prefix.$i.'.MAPPING.NANO.DIVIDED.bed';

	open (my $NANOBED, '<', $final_mappings) or die;
	open (my $DIVIDED, '>', $divided_mappings) or die;
	while (<$NANOBED>) {
		my @a = split/\t/;
		my $chromosome = $a[0];
		my $start_c = $a[1];
		my $read = $a[3];
		my @len = split/,/, $a[10];
		my @starts = split/,/, $a[11];
		for (my $i=0;$i<=$#len;$i++) {
			my $start = $start_c + $starts[$i];
			my $end = $start + $len[$i];
			print $DIVIDED "$chromosome\t$start\t$end\t$read\n";
		}
	}
	close $NANOBED;
	close $DIVIDED;

	print "\nSEARCHING FOR SPLICE-SITES IN THE READS\n";

	my $splice_sites = $output_dir.$output_prefix.$i.'.SPLICE-SITES.txt';

	system ("perl $splice_sites_detection $divided_mappings $final_mappings $splice > $splice_sites");

	$list_of_final_mappings = $final_mappings if ($list_of_final_mappings eq '');
	$list_of_final_mappings = $list_of_final_mappings.' '.$final_mappings if ($list_of_final_mappings ne '');

	$list_of_splicing_files = $splice_sites if ($list_of_splicing_files eq '');
	$list_of_splicing_files = $list_of_splicing_files.' '.$splice_sites if ($list_of_splicing_files ne '');
}

## OBTAINING STARTING AND ENDING POSITIONS ##

print "\nOBTAINING PEAKS FOR STARTS AND ENDS OF ISOFORMS\n";

my $level1_starts = $output_dir.'level1_starts';
my $level1_ends = $output_dir.'level1_ends';
my $level2_starts_raw = $output_dir.'level2_starts_raw';
my $level2_ends_raw = $output_dir.'level2_ends_raw';
my $gene_read_counts = $output_dir.'gene_read_counts';
my $level2_starts_filtered = $output_dir.'level2_starts_filtered';
my $level2_ends_filtered = $output_dir.'level2_ends_filtered';
my $removedStarts = $output_dir.'level1_starts_removed';
my $removedEnds = $output_dir.'level1_ends_removed';

system ("perl $level1_starts_script 0 $list_of_final_mappings > $level1_starts");
system ("perl $level1_ends_script 0 $list_of_final_mappings > $level1_ends");
system ("python2 $level2_script -r $removedStarts -o $level2_starts_raw  -t 0 -s 5 $level1_starts");
system ("python2 $level2_script -r $removedEnds -o $level2_ends_raw -t 0 -s 5 $level1_ends");

system ("perl $make_peak_counts_per_gene $sorted_genes_list $list_of_bedtools > $gene_read_counts");
system ("perl $sort_peaks_by_coverage $sorted_genes_list $level2_starts_raw $gene_read_counts > $level2_starts_filtered");
system ("perl $sort_peaks_by_coverage $sorted_genes_list $level2_ends_raw $gene_read_counts > $level2_ends_filtered");

## MAKING ISOFORMS ##

print "\nMAKING ISOFORMS\n";

system ("perl $finalize_isoforms $level2_starts_filtered $level2_ends_filtered $gene_read_counts unmapped_reads.list.txt $list_of_splicing_files");