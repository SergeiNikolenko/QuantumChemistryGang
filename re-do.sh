#!/bin/bash

#SBATCH --nodes=1                             # Number of nodes.
#SBATCH --ntasks=10                           # Total number of tasks (cores).
#SBATCH --job-name=orca
#SBATCH --output=job.out                      # File to which STDOUT will be written
#SBATCH --error=job.err                       # File to which STDERR will be written

module purge
module load prog/orca5

N=10
np=$N

INP=$(ls | grep -m 1 '\.inp$')
OUT=$(echo $INP | sed 's/inp$/log/g')

rdir=$(pwd)

echo "Procs:" $N "  " $np
echo "Input: " $INP
echo "Output: " $OUT


tdir=$rdir
mkdir -p $tdir

export ORCA_TMPDIR=$tdir

cp $INP $tdir/
cd $tdir

perl -pi -e "s|^nprocs.*|nprocs $np|" $INP

export LD_PRELOAD=""
source /etc/profile.d/modules.sh
module load prog/orca5

$(which orca) $INP > $OUT

rm -f job.err
rm -f job.out
rm -f *.opt
rm -f *.gbw
rm -f *.densities
rm -f mol_atom*.out
rm -f *property.txt
rm -f mol.engrad
rm -f mol_trj.xyz
rm -f re-do.sh
rm -f ini.xyz

trap EXIT
