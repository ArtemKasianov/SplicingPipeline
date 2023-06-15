($tc_filter, @nano_input) = @ARGV;
$num_samples = @nano_input;

print "##FileFormat = OSCtable\n";
print "##ProtocolREF = OP-CAGE-Tag-Clustering-v1.1\n";
print "##ParameterValue[level1_script_version] = 2015.04.06\n";
print "##ParameterValue[threshold] = 1.000000\n";
print "##ParameterValue[flag_select] = 0x0\n";
print "##ParameterValue[flag_skip] = 0x4\n";
print "##ParameterValue[quality] = 0.000000\n";
print "##ParameterValue[identity] = 0.000000\n";
print "##Date = 2222-22-02\n";
print "##ContactName = LSA support staff\n";
print "##ContactEmail = kovtunas25@gmail.com\n";

@sum_reads = ();
%overall = ();
%chr_names = ();
$raw_names = '';
$norm_names = '';
$file_number = 0;

foreach $file (@nano_input) {
	print "##InputFile = $file\n";
	$raw_names = $raw_names."\traw.".$file;
	$norm_names = $norm_names."\tnorm.".$file;
	$rc = 0;
	%hash = ();
	open (IN, '<', $file) or die;
	while ($line = <IN>) {
		($chr, $left, $right, $readname, $smth, $strand) = split/\t/, $line;
		$chr_names{$chr} = 1;
		if ($strand eq '+') {
			$hash{"$chr\t$strand\t$right"} += 1;
		} else {
			$hash{"$chr\t$strand\t$left"} += 1;
		}
		$rc += 1;	
	}
	foreach $k (keys %hash) {
		@a = split/\t/, $k;
		unless (exists($overall{$a[0]}{$a[1]}{$a[2]})) {
			for ($i=0;$i<$num_samples;$i++) {
				push @{$overall{$a[0]}{$a[1]}{$a[2]}}, 0;
			}
		}
		@tmp = @{$overall{$a[0]}{$a[1]}{$a[2]}};
		$tmp[$file_number] = $hash{$k};
		@{$overall{$a[0]}{$a[1]}{$a[2]}} = @tmp;
	}
	push @sum_reads, $rc;
	$file_number += 1;
}

$l = '';
foreach $chr_name (sort keys %chr_names) {
	if ($l eq '') {
		$l = $chr_name;
	} else {
		$l = $l.','.$chr_name;
	}
}
print "##ChromosomeNameOrder = $l\n";
print "##ColumnVariable[id] = identifier of the level-1 promoter\n";
print "##ColumnVariable[chrom] = name of the chromosome, identical to what is written in genome assembly\n";
print "##ColumnVariable[start] = start genomic coordinate of the promoter, starting from 0\n";
print "##ColumnVariable[end] = end genomic coordinate of the promoter, always equal to start+1\n";
print "##ColumnVariable[strand] = genomic strand on which the promoter is located\n";
print "##ColumnVariable[raw.leaf_replicate_1.expressed] = rescued tag count of sample leaf_replicate_1.expressed\n";
print "##ColumnVariable[raw.leaf_replicate_2.expressed] = rescued tag count of sample leaf_replicate_2.expressed\n";
print "##ColumnVariable[raw.leaf_replicate_3.expressed] = rescued tag count of sample leaf_replicate_3.expressed\n";
print "##ColumnVariable[norm.leaf_replicate_1.expressed] = normalized expression for sample leaf_replicate_1.expressed\n";
print "##ColumnVariable[norm.leaf_replicate_2.expressed] = normalized expression for sample leaf_replicate_2.expressed\n";
print "##ColumnVariable[norm.leaf_replicate_3.expressed] = normalized expression for sample leaf_replicate_3.expressed\n";
print "id\tchrom\tstart.0base\tend\tstrand$raw_names$norm_names\n";

foreach $chr (sort keys %overall) {
	foreach $pos (sort {$a<=>$b} keys %{$overall{$chr}{'+'}}) {
		$left = $pos-1;
		$peak_name = 'L1_None_'.$chr.'_+_'.$pos;
		$line = "$peak_name\t$chr\t$left\t$pos\t".'+';
		@tpms = ();
		@tag_counts = @{$overall{$chr}{'+'}{$pos}};
		$check_tc_filter = 0;
		for ($i=0;$i<=$#tag_counts;$i++) {
			$line = $line."\t$tag_counts[$i]";
			$check_tc_filter += 1 if ($tag_counts[$i] < $tc_filter);
			$t = $tag_counts[$i]*1000000/$sum_reads[$i];
			push @tpms, $t;
		}
		next if ($check_tc_filter == $num_samples);
		foreach $tpm (@tpms) {
			$line = $line."\t$tpm";
		}
		print "$line\n";
	}
	foreach $pos (sort {$a<=>$b} keys %{$overall{$chr}{'-'}}) {
		$left = $pos-1;
		$peak_name = 'L1_None_'.$chr.'_-_'.$pos;
		$line = "$peak_name\t$chr\t$left\t$pos\t".'-';
		@tpms = ();
		@tag_counts = @{$overall{$chr}{'-'}{$pos}};
		$check_tc_filter = 0;
		for ($i=0;$i<=$#tag_counts;$i++) {
			$line = $line."\t$tag_counts[$i]";
			$check_tc_filter += 1 if ($tag_counts[$i] < $tc_filter);
			$t = $tag_counts[$i]*1000000/$sum_reads[$i];
			push @tpms, $t;
		}
		next if ($check_tc_filter == $num_samples);
		foreach $tpm (@tpms) {
			$line = $line."\t$tpm";
		}
		print "$line\n";
	}
}