#usr/bin/perl

use strict;
use warnings;
use Benchmark; # entrega cuando demora el proceso, cuanto de CPU utilizó, etc
#
my $tiempo_inicial = new Benchmark; #funcion para el tiempo de ejecucion del programa
#
# Modo de uso
my ($tempf) = ($0 =~ m<([^\\/]+?\.log)$>i);
#
#my $input_file    = $ARGV[0];
# leer directorio solo los archivos .out o .log
my $dir = ".";
my @files = glob "$dir/*.log";
#my @files = glob "$dir/*.out";
my @array_Freq   = ();
my @array_energy = ();
my @array_coords = ();
my @array_files  = ();

my @columns_4N = ();
# numero de atomos
my $atom_numb;
#
for (0..$#files){
        #
        $files[$_] =~ s/\.txt$//;
        #
        my $input_file    = $files[$_];
        #############
        # Main
        my @Secuencias = ();
        # coodenadas
        my @coords;
        # energia
        my $energy;
		my $zero_point;
        #
        my $file = $input_file;
        my $seqlinea;
        # # # #
        open (IN, "<$file")||die "cannot open $file in readseq subroutine:$!\n";
        while ($seqlinea = <IN>) {
                chomp($seqlinea);
                push (@Secuencias, $seqlinea);
        }
        close IN;
        #
        my @columns_1N = ();
        my @columns_2N = ();
        my @columns_3N = ();
        my @columns_4N = ();
        #
        my $count_lines = 0;
        #
        foreach my $a_1 (@Secuencias){
                # SCF Done:  E(RPBE1PBE) =  -56.7829127857     A.U. after   40 cycles
                if ( ($a_1=~/SCF/gi ) && ($a_1=~/Done/gi ) && ($a_1=~/after/gi ) ){
                        my @array_tabs = ();
                        #
                        @array_tabs = split (/ /,$a_1);
                        #
                        push (@columns_1N  ,$array_tabs[7]);
                }
                # Standard orientation:
                if ( ($a_1=~/Standard/gi ) && ($a_1=~/orientation/gi ) && ($a_1=~/:/gi ) ){
                        #
                        push (@columns_2N  ,$count_lines);
                }
                # Rotational constants (GHZ):
                if ( ($a_1=~/Rotational/gi ) && ($a_1=~/constants/gi ) && ($a_1=~/GHZ/gi ) ){
                        #
                        push (@columns_3N  ,$count_lines);
                }

                # Rotational constants (GHZ):
                if ( ($a_1=~/Low frequencies ---/gi ) ){
                        #
                        push ( @columns_4N,$count_lines);
                }


				        # Zero-point correction=
                if ( ($a_1=~/Zero-point/gi ) && ($a_1=~/correction/gi ) ){
                        #
                        my @array_tabs = ();
                        #
                        @array_tabs = split '\s+',$a_1;
                        #
                        push (@columns_4N  ,$array_tabs[3]);
                }
				#
                $count_lines++;
        }
        #
        if ( scalar (@columns_1N) > 0 ){
                for (my $i=0; $i < scalar (@columns_1N); $i++){
                        #
                        my $start = $columns_2N[$i] + 5;
                        my $end   = $columns_3N[$i] - 2;
                        $atom_numb = $end - $start + 1;
                        #
                        $energy     = $columns_1N[$i];
                        #
                        @coords = ();
                        foreach my $j (@Secuencias[$start..$end]){
                                push (@coords,$j);
                        }
                }
                #
                my @total_coords = ();
                foreach my $i (@coords){
                        my @tmp = ();
                        @tmp =  split (/\s+/,$i);
                        push (@total_coords,"$tmp[2]\t$tmp[4]\t$tmp[5]\t$tmp[6]");
                }
                # Frecuencia
                my @array_tmp = split (/\s+/,$Secuencias[$columns_4N[1]]);
                #
                push(@array_Freq,$array_tmp[4]);
                push(@array_energy,$energy);
                push(@array_coords,[@total_coords]);
                push(@array_files,$input_file);
        #
        } else {
                print "No presenta SCF: $input_file\n";
        }
}

my @array_energy_zero = ();
for (my $i=0; $i < scalar (@array_energy); $i++){
	my $sum = ($array_energy[$i] + $columns_4N[$i]);
	push (@array_energy_zero,$sum);
}

# sort, same thing in reversed order
my @value_freque_sort = ();
my @value_energy_sort = ();
my @value_coords_sort = ();
my @value_files_sort  = ();
my @idx = sort { $array_energy_zero[$a] <=> $array_energy_zero[$b] } 0 .. $#array_energy_zero;

@value_freque_sort = @array_Freq[@idx];
@value_energy_sort = @array_energy_zero[@idx];
@value_coords_sort = @array_coords[@idx];
@value_files_sort  = @array_files[@idx];
#
my $filename = "all_coords.xyz";
open(my $fh, '>', $filename) or die "Could not open file '$filename' $!";
for (my $i=0; $i < scalar (@value_energy_sort); $i++){
        # resta # -2984.223085
        my $resta = abs($value_energy_sort[0]) - abs($value_energy_sort[$i]);
#        my $resta = abs(-2984.223085) - abs($value_energy_sort[$i]);
        # 1 Hartree = 27,2114 ev
        # 1 Hartree = 627,509 Kcal/mol
        my $eV      = sprintf("%06f",(27.2114 * $resta ));
        my $Kcalmol = sprintf("%06f",(627.509 * $resta ));
        my $Hartree = sprintf("%06f",$value_energy_sort[$i]);
        print $fh "$atom_numb\n";
        print $fh "$Kcalmol Kcal/mol $eV eV $Hartree H\t$value_files_sort[$i]  $value_freque_sort[$i]\n";
		print "$Hartree\t$value_files_sort[$i]\n";
        for (my $j=0; $j < $atom_numb; $j++){
                print $fh "$value_coords_sort[$i][$j]\n";
        }
}
close $fh;


##############################################################
my $tiempo_final = new Benchmark;
my $tiempo_total = timediff($tiempo_final, $tiempo_inicial);
print "\n\tTiempo de ejecucion: ",timestr($tiempo_total),"\n";
print "\n";
