#!/usr/bin/perl

use strict;
use warnings;

###################################
# read files
sub read_file {
	# filename
	my ($filename) = @_;
	(my $input_file = $filename) =~ s/\s//g;
	my @array          = ();
	# open file
	open(FILE, "<", $input_file ) || die "Can't open $input_file: $!";
	while (my $row = <FILE>) {
		chomp($row);
		push (@array,$row);
	}
	close (FILE);
	# return array
	return @array;
}

sub distribute {
    my ($n, $array) = @_;

    my @parts;
    my $i = 0;
    foreach my $elem (@$array) {
        push @{ $parts[$i++ % $n] }, $elem;
    };
    return \@parts;
}

my $number_paral = 10;
my $partition    = "slims";
#
my $filex = "lista.txt";
my @files = read_file($filex);

my $arr     = distribute($number_paral,\@files);
my @loarr   = @{$arr};
my $div     = int ( scalar (@files) / $number_paral);
for (my $i = 0; $i < scalar (@loarr) ; $i++) {
  my $slrm = "Lanz-$i";
  open (SLURMFILE, ">$slrm.slrm");
  print SLURMFILE "#!/bin/bash \n";
  print SLURMFILE "#SBATCH --job-name=$slrm \n";
  print SLURMFILE "#SBATCH --output=$slrm.out \n";
  print SLURMFILE "#SBATCH --error=error_$slrm \n";
  print SLURMFILE "#SBATCH --partition=$partition \n";
  print SLURMFILE "#SBATCH --nodes=1 \n";
  print SLURMFILE "#SBATCH -c 8 \n";
  print SLURMFILE "#SBATCH --mail-user=osvyanezosses\@gmail.com \n";
  print SLURMFILE " \n";
  print SLURMFILE "ml g16/B.01 \n";
  print SLURMFILE " \n";
  print SLURMFILE " cd \$SLURM_SUBMIT_DIR \n";
  print SLURMFILE " scontrol show hostname \$SLURM_NODELIST > hostlist.dat \n";
  print SLURMFILE " \n";
  print SLURMFILE " # # \n";
  print SLURMFILE " # Enviar muchos calculos \n";
  print SLURMFILE " \n";
  #my @tmp_arr = ();
  for (my $j = 0; $j < $div ; $j++) {
    #push (@tmp_arr,$loarr[$i][$j]);
    print SLURMFILE " srun g16 $loarr[$i][$j] \n";
  }
  print SLURMFILE "\n\n\n\n\n";

  system ("sbatch $slrm.slrm");

}
