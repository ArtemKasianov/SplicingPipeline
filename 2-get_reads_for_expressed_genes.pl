($genes_file, @bedtools) = @ARGV;
open (IN, '<', $genes_file) or die;
%genes = ();
while (<IN>) {
	@a = split/\t/;
	$genes{$a[-1]} = 1;
}
close IN;

foreach $file (@bedtools) {
	%sample = ();
	open (IN, '<', $file) or die;
	while (<IN>) {
		@a = split/\t/;
		next if ($a[5] ne $a[-2]);
		$sample{$a[3]} = 1 if (exists($genes{$a[-1]}));
	}
	close IN;
	%check = ();
	$mapping = $file;
	$mapping =~ s/tools$//;
	$output = $mapping.'_sorted';
	open (IN, '<', $mapping) or die;
	open (OUT, '>', $output) or die;
	while (<IN>) {
		@a = split/\t/;
		next if (exists($check{$a[3]}));
		$chech{$a[3]} = 1;
		print OUT if (exists($sample{$a[3]}));
	}
	close IN;
	close OUT;
}
