($annotation, @bedtools) = @ARGV;
$n = @bedtools;

open (IN, '<', $annotation) or die;
%hash = ();
while (<IN>) {
	chomp;
	@a = split/\t/;
	$hash{$a[-1]} = 0;
}
close IN;

for ($i=0;$i<=$#bedtools;$i++) {
	open (IN, '<', $bedtools[$i]) or die;
	%reads = ();
	%count = ();
	while ($q = <IN>) {
		chomp $q;
		@a = split/\t/, $q;
		next if ($a[5] ne $a[-2]);
		next if (exists($reads{$a[3]}));
		$reads{$a[3]} = 1;
		$count{$a[-1]} += 1;
	}
	close IN;
	foreach $k (keys %hash) {
		$hash{$k} += 1 if ($count{$k} >= 10);
	}
}

open (IN, '<', $annotation) or die;
while (<IN>) {
	chomp;
	@a = split/\t/;
	print "$_\n" if ($hash{$a[-1]} == $n);
}
close IN;
