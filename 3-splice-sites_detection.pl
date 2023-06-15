$map_bed = $ARGV[0];           ## accepts divided nano-file (run script divide_mappings.pl on nano-file)
$map_wide = $ARGV[1];          ## accepts nano-file
$splice_sites_file = $ARGV[2]; ## file with splice-sites

%map_fr = ();
%ss = ();

## SAVING GAPS BETWEEN MAPPED FRAGMENTS ##

open (MF, '<', $map_bed) or die;
while (<MF>) {
	s/\r?\n//;
	@a = split/\t/;
	if ($a[3] ne $read) {
		$read = $a[3];
		$left = $a[2];
	} else {
		$right = $a[1];
		$map_fr{$a[3]} = $map_fr{$a[3]}."$a[0]\t$left\t$right\t$a[3]\n";
		$left = $a[2];
	}
}
close MF;

print "Read name\tChromosome\tStarting coordinate\tEnding coordinate\tStrand\tCoordinates of putative introns\n";

## SAVING SPLICE SITES ##

open (SSF, '<', $splice_sites_file) or die;
while (<SSF>) {
	s/\r?\n//;
	$ss{$_} = 1;
}
close SSF;

## WORKING THROUGH ALL MAPPED READS ##

open (MP, '<', $map_wide) or die;
%used_reads = ();
while (<MP>) {

	($chr, $start, $end, $read, $xero, $strand) = split/\t/;
	next if (exists($used_reads{$read}));
	$used_reads{$read} = 1;

	## IF THE READ WAS MAPPED WITHOUT GAPS ##

	unless (exists($map_fr{$read})) {
		print "$read\t$chr\t$start\t$end\t$strand\t-\n";    
		next;
	}

	## GAPS FOR THE READ ##

	$gu = $map_fr{$read};
	@gaps = split/\n/, $gu;

	## GET PUTATIVE INTRONS ##

	$line = '';

	foreach $gap (@gaps) {
		next if ($gap eq '');
		@w = split/\t/, $gap;
		$ss_left = '';
		$ss_right = '';
		$dist_left = 20;
		$dist_right = 20;
		$splice_interval = '';

	## LEFT SPLICE SITE ##

		for ($i=$w[1]-10;$i<=$w[1]+10;$i++) {
			if ((exists($ss{"$w[0]\t$i"})) && (abs($i-$w[1]) <= $dist_left)) {
				$ss_left = $i;
				$dist_left = abs($i-$w[1]);
			}
		}

	## RIGHT SPLICE SITE ##

		for ($i=$w[2]-10;$i<=$w[2]+10;$i++) {
			if ((exists($ss{"$w[0]\t$i"})) && (abs($i-$w[2]) < $dist_right)) {
				$ss_right = $i;
				$dist_right = abs($i-$w[2]);
			}
		}

	## CHECKING FOR ERRORS AND FINALIZING SLICE-SITE INTERVAL ##

		if (($ss_left eq '') || ($ss_right eq '')) {
			$splice_interval = 'Error in gap '.$w[1].'-'.$w[2];
		} else {
			if ($ss_left < $ss_right) {
				$splice_interval = $ss_left.'-'.$ss_right;
			} else {
				$splice_interval = 'Error in gap '.$w[1].'-'.$w[2];
			}
		}

	## ADDING SLICE-SITE INTERVAL ##

		if ($line eq '') {
			$line = $splice_interval;
		} else {
			$line = $line.';'.$splice_interval;
		}
	}
	
	print "$read\t$chr\t$start\t$end\t$strand\t$line\n";
}

close MP;