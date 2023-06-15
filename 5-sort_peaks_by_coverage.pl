($list_of_genes, $osc_level2, $counts_file) = @ARGV;

%genes = ();
%coordinates = ();
open (IN, '<', $list_of_genes) or die;
while ($l = <IN>) {
	chomp $l;
	@a = split/\t/, $l;
	$genes{$a[-1]} = ();
	if ($a[3] eq '+') {
		for ($i=$a[1]-100;$i<=$a[2];$i++) {
			$coordinates{"$a[0]$a[3]$i"} = $a[-1];
		}
	} else {
		for ($i=$a[1];$i<=$a[2]+100;$i++) {
			$coordinates{"$a[0]$a[3]$i"} = $a[-1];
		}
	}
}
close IN;

open (IN, '<', $counts_file) or die;
while ($l = <IN>) {
	chomp $l;
	@a = split/\t/, $l;
	for ($i=1;$i<=$#a;$i++) {
		push @{$genes{$a[0]}}, $a[$i] if (exists($genes{$a[0]}));
	}
}
close IN;

open (IN, '<', $osc_level2) or die;
while ($l = <IN>) {
	next if ($l =~ (/^#/) || ($l =~ /^id\t/));
	@a = split/\t/, $l;
	$gene = '';
	for ($i=$a[2];$i<=$a[3];$i++) {
		if (exists($coordinates{"$a[1]$a[4]$i"})) {
			$gene = $coordinates{"$a[1]$a[4]$i"};
			last;
		}
	}
	next if ($gene eq '');
	@sums = @{$genes{$gene}};
	$k = 0;
	$n = @sums;
	for ($j=0;$j<=$#sums;$j++) {
		next if (($sums[$j] == 0) || ($sums[$j] eq '')); 
		$k += 1 if ($a[6+$j]/$sums[$j] >= 0.01);
	}
	print "$a[1]\t$a[2]\t$a[3]\t$a[4]\t$a[5]\t$gene\n" unless ($k < $n);
}
close IN;