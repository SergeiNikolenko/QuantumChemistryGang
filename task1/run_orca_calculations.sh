#!/bin/bash

# Define path to ORCA executable
orca_path="/home/sergei/Documents/quant/bin/orca/orca"

# Clear existing directories
rm -rf neutral/* cations/* anions/*

# Create directories for neutral molecules, cations, and anions
mkdir -p neutral cations anions

# Process all .xyz files in the molecules folder
for xyz_file in molecules/*.xyz; do
  base_name=$(basename "$xyz_file" .xyz)
  
  echo "Processing molecule: $base_name"

  # Neutral molecule calculations
  dir_name="neutral/$base_name"
  mkdir -p "$dir_name"
  cd "$dir_name"
  cat > "${base_name}.inp" <<EOL
! B3LYP D3BJ 6-31G RIJCOSX AutoAux printbasis DEFGRID3 TightSCF Opt
%PAL NPROCS 16 END

* xyzfile 0 1 ../../$xyz_file
EOL
  $orca_path "${base_name}.inp" > "${base_name}.out"
  cd ../..

  # Cation calculations
  dir_name="cations/${base_name}_cat"
  mkdir -p "$dir_name"
  cd "$dir_name"
  cat > "${base_name}_cat.inp" <<EOL
! B3LYP D3BJ 6-31G RIJCOSX AutoAux printbasis DEFGRID3 TightSCF Opt
%PAL NPROCS 16 END

* xyzfile +1 2 ../../$xyz_file
EOL
  $orca_path "${base_name}_cat.inp" > "${base_name}_cat.out"
  cd ../..

  # Anion calculations
  dir_name="anions/${base_name}_an"
  mkdir -p "$dir_name"
  cd "$dir_name"
  cat > "${base_name}_an.inp" <<EOL
! B3LYP D3BJ 6-31G RIJCOSX AutoAux printbasis DEFGRID3 TightSCF Opt
%PAL NPROCS 16 END

* xyzfile -1 2 ../../$xyz_file
EOL
  $orca_path "${base_name}_an.inp" > "${base_name}_an.out"
  cd ../..

  echo "Finished molecule: $base_name"
done

echo "All calculations are complete!"
