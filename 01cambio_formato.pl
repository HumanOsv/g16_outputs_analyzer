#!/usr/bin/perl -s

sub read_cart_file{
	my ($input_file)=@_;
	my @data=();
	open(FILE, "<", $input_file) or die "Can't open";
	my @lines=<FILE>;
	close(FILE);
	foreach $i (@lines){
		chomp($i);
		$data[++$#data]=$i;
	}
	return @data;
}

my ($file,$energy) = @ARGV;
if (not defined $file) {
	die "\nCambio_Formato must be run with:\n\nUsage:\n\tCambio_Formato.pl [file-all.xyz] [Energy]\n";
	exit(1);
}
if (not defined $energy) {
	die "\nCambio_Formato must be run with:\n\nUsage:\n\tCambio_Formato.pl [file-all.xyz] [Energy]\n";
	exit(1);
}
#read and parse
my @data   = read_cart_file($file);
my $word_1 = "Kcal";
my $word_2 = "mol";
my $word_3 = "H";
my $word_4 = "eV";
#
my @array_energy = ();
my @linearray_1  = ();
my @linearray_2  = ();
my $count = 0;
my $lines = 0;
#
foreach my $i (@data) {
	if ( ($i =~ m/$word_1/) && ($i =~ m/$word_2/) && ($i =~ m/$word_3/) && ($i =~ m/$word_4/) ) {
		$lines = $count;
		my @array_tabs = ();
		@array_tabs    = split ('\s+',$i);
		push (@linearray_1,$lines);
		push (@array_energy,$array_tabs[0]);
	}
	$count++;
}
#
for (my $i=0; $i < scalar(@linearray_1) ; $i++) {
	my $number_atoms = $linearray_1[1] - ($linearray_1[0] + 2);
	my $tmpsum_1     = $linearray_1[$i] + 1;
	my $tmpsum_2     = $linearray_1[$i] + $number_atoms;
	my $count        = 0;
	my @array_2      = ();
	for my $x ($tmpsum_1 .. $tmpsum_2) {
		push (@array_2,$data[$x]);
	}

	if ( $array_energy[$i] < $energy ) {
		my $number = sprintf '%04d', $i;
		#
		$filebase  = "LiSi-$number";
		$Input     = "$filebase.com";
		open (FILE, ">$Input");
	#	print FILE "%chk=$filebase.chk\n";
		print FILE "%mem=8gb\n";
		print FILE "%nproc=8\n";
		print FILE "#p PBE1PBE/Def2TZVP Freq Opt EmpiricalDispersion=GD3\n";

		#print FILE "#p CCSD(T)/Def2TZVP \n";
		print FILE "\n";
		print FILE "$filebase E=$array_energy[$i]\n";
		print FILE "\n";
		print FILE "0 1\n";
		foreach my $u (@array_2){
			print FILE "$u\n";
		}
		print FILE "\n";
		close (FILE);
	}
}
