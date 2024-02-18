#! /bin/bash

Charge=0
Mult=1

# Define DFT methods, dispersion corrections, and basis sets
DFT=( "blyp" "pbe" "b3lyp" "pbe0" )
Disp=( "d3bj" "d4" )
Basis=( "6-31g" "def2-svp" "def2-tzvp" )

# Get the initial directory
inidir=$(pwd)

# Loop through standard DFT methods
for dft in "${DFT[@]}"; do
    for disp in "${Disp[@]}"; do
        for basis in "${Basis[@]}"; do
            workdir="$dft-$disp-$basis"
            mkdir -p "$workdir"
            cp "$inidir/ini.xyz" "$workdir/"
            cp "$inidir/re-do.sh" "$workdir/"
            cd "$workdir"
            cat > mol.inp <<EOF
! Opt Freq TightSCF Mass2016 MiniPrint
! $dft $disp $basis

%maxcore 10000

%pal
  nprocs 10
end

* xyzfile $Charge $Mult ini.xyz
EOF
            sbatch -n 10 re-do.sh
            cd "$inidir"
        done
    done
done

# Loop through composite methods
CompMethods=( "hf-3c" "pbeh-3c" "r2scan-3c" )
for method in "${CompMethods[@]}"; do
    workdir="$method"
    mkdir -p "$workdir"
    cp "$inidir/ini.xyz" "$workdir/"
    cp "$inidir/re-do.sh" "$workdir/"
    cd "$workdir"
    cat > mol.inp <<EOF
! Opt NumFreq TightSCF Mass2016 MiniPrint
! $method

%maxcore 10000

%pal
  nprocs 10
end

* xyzfile $Charge $Mult ini.xyz
EOF
    sbatch -n 10 re-do.sh
    cd "$inidir"
done
