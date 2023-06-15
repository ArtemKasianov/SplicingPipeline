($starts, $ends, $readcounts, @files) = @ARGV;
$num_files = @files;

open (STARTS, '<', $starts) or die;
%st = ();
while (<STARTS>) {
	@a = split/\t/;
	for ($i=$a[1];$i<=$a[2];$i++) {
		$st{"$a[0]$a[3]$i"} = $_;
	}
}
close STARTS;

open (ENDS, '<', $ends) or die;
%end = ();
while (<ENDS>) {
	@a = split/\t/;
	for ($i=$a[1];$i<=$a[2];$i++) {
		$end{"$a[0]$a[3]$i"} = $_;
	}
}
close ENDS;

for ($f=0;$f<=$#files;$f++) {

open (RCS, '<', $readcounts) or die;
%rc = ();
while (<RCS>) {
	chomp;
	@a = split/\t/;
	$check_size = @a;
	next if ($check_size != $num_files+1);
	$rc{$a[0]} = $a[$f+1];
}
close RCS;

open (IN, '<', $files[$f]) or die;
$output = $files[$f];
$output =~ s/SPLICE-SITES/FINAL_ISOFORMS/;
open (OUT, '>', $output) or die;
%isoforms = ();
while (<IN>) {
	next if (/^Read\sname/);
	next if (/Error/);
	chomp;
	($readname, $chr, $left, $right, $strand, $splice) = split/\t/;
	$isoform = '';
	if ($strand eq '+') {
		if (exists($st{"$chr$strand$left"}) && exists($end{"$chr$strand$right"})) {
			@a = split/\t/, $st{"$chr$strand$left"};
			@b = split/\t/, $end{"$chr$strand$right"};
		} else {
			next;
		}
	} else {
		if (exists($st{"$chr$strand$right"}) && exists($end{"$chr$strand$left"})) {
			@a = split/\t/, $end{"$chr$strand$left"};
			@b = split/\t/, $st{"$chr$strand$right"};
		} else {
			next;
		}
	}
	$left_peak = $a[1]."-".$a[2];
	$right_peak = $b[1]."-".$b[2];
	chomp $a[-1];
	$isoform = "$chr\t$a[4]\t$b[4]\t$strand\t$splice\t$left_peak\t$right_peak\t$a[-1]";
	$isoforms{$isoform} += 1;
}

$num_used_reads = 0;
foreach $k (sort keys %isoforms) {
	@a = split/\t/, $k;
	next unless (exists($rc{$a[-1]}));
	$p = $isoforms{$k}/$rc{$a[-1]};
	print OUT "$k\n" if (($isoforms{$k} >= 5) && ($p >= 0.01));
}


close IN;
close OUT;

}