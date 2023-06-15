($list_of_genes, @intersected_nano_files) = @ARGV;

%genes = ();
open (IN, '<', $list_of_genes) or die;
while ($l = <IN>) {
	chomp $l;
	@a = split/\t/, $l;
	$genes{$a[-1]} = ();
}
close IN;

foreach $nano (@intersected_nano_files) {
	%sample = ();
	%reads = ();
	open (IN, '<', $nano) or die;
	while ($l = <IN>) {
		chomp $l;
		@a = split/\t/, $l;
		next if ($a[5] ne $a[-2]);
		next if (exists($reads{$a[3]}));
		$reads{$a[3]} = 1;
		$sample{$a[-1]} += 1;
	}
	close IN;
	foreach $k (keys %genes) {
		$count = $sample{$k} if (exists($sample{$k}));
		$count = 0 unless (exists($sample{$k}));
		push @{$genes{$k}}, $sample{$k};
	}
}

foreach $k (sort keys %genes) {
	print $k;
	foreach $s (@{$genes{$k}}) {
		print "\t$s";
	}
	print "\n";
}
