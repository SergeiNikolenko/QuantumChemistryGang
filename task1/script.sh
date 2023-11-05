#!/bin/bash

# Define directories
neutral_dir="neutral"
cations_dir="cations"
anions_dir="anions"
report_dir="report"

# Clear the report directory before starting
rm -rf "$report_dir/*"

# Make sure the report directory exists
mkdir -p "$report_dir"

# Function to extract total energy from ORCA output
get_total_energy() {
  grep "FINAL SINGLE POINT ENERGY" "$1" | tail -n 1 | awk '{print $5}'
}

# Function to extract HOMO and LUMO energies from ORCA output
get_homo_lumo() {
  grep -A 1 "HOMO" "$1" | tail -n 2 | awk 'NR==1{print "HOMO: " $5 " eV"} NR==2{print "LUMO: " $5 " eV"}'
}

# Function to format the geometry

extract_and_format_geometry() {
  local trj_file=$1
  # Ищем последний блок с координатами - он будет иметь самую низкую энергию
  local last_block=$(tac "$trj_file" | awk '/^2$/{exit}1' | tac)
  local IFS=$'\n' # Установка разделителя строк для корректного чтения массива

  # Подготовка массива для хранения данных таблицы
  local -a table_lines
  table_lines+=("| Atom | X (Å) | Y (Å) | Z (Å) |")
  table_lines+=("|------|--------|--------|--------|")

  # Чтение координат из блока и добавление их в массив
  local line energy
  for line in $last_block; do
    if [[ $line =~ E\ +(-?[0-9]+\.[0-9]+) ]]; then
      energy=${BASH_REMATCH[1]}
    elif [[ $line =~ ^\ +([A-Za-z]+)\ +(-?[0-9]+\.[0-9]+)\ +(-?[0-9]+\.[0-9]+)\ +(-?[0-9]+\.[0-9]+) ]]; then
      table_lines+=("| ${BASH_REMATCH[1]} | ${BASH_REMATCH[2]} | ${BASH_REMATCH[3]} | ${BASH_REMATCH[4]} |")
    fi
  done

  # Преобразование массива в строку для Markdown
  local markdown_table=$(printf '%s\n' "${table_lines[@]}")
  echo -e "### Равновесная геометрия с минимальной энергией: $energy Hartree\n$markdown_table"
}


# Function to create the Markdown report
create_markdown_report() {
  local base_name=$1
  local neutral_energy=$2
  local cation_energy=$3
  local anion_energy=$4
  local ionization_potential=$5
  local electron_affinity=$6
  local homo_lumo=$7
  local geometry_markdown=$8
  local report_file=$9

  {
    echo "# Отчет о вычислениях молекулы ${base_name/_guess/}"
    echo "Дата: $(date +%d.%m.%Y)"
    echo ""
    echo "## 1. Методология"
    echo "### Параметры запуска"
    echo "\`\`\`"
    echo "!B3LYP D3BJ 6-311G"
    echo "!RIJCOSX AutoAux printbasis"
    echo "!Opt Freq"
    echo "!DEFGRID3 TightSCF"
    echo "\`\`\`"
    echo "\`B3LYP\` – уровень теории для DFT-вычислений.<br>"
    echo "\`D3BJ\` – Becke-Johnson damping, коррекция дисперсии.<br>"
    echo "\`6-311G\` – базисный набор, предложен 6-31G, но решил взять больше функций для большей точности.<br>"
    echo "\`RIJCOSX AutoAux\` – настройки SVD, какой дополнительный базис выбрать и как считать.<br>"
    echo "\`printbasis\` – если использовались дополнительные базисы, то вывести в итоге тот, который изначально подразумевался (6-311G).<br>"
    echo "\`Opt Freq\` – оптимизировать геометрию и рассчитать частоты колебаний.<br>"
    echo "\`DEFGRID3 TightSCF\` – настройки точности вычислений и SCF.<br>"
    echo ""
    echo "## 2. Результаты"
    echo "### 2.1 Равновесная геометрия"
    echo "$geometry_markdown"
    echo "### 2.2 Энергетические параметры"
    echo "$homo_lumo"
    echo "### 2.3 Потенциал ионизации и сродство к электрону"
    echo "Ионизационный потенциал: $ionization_potential eV"
    echo "Сродство к электрону: $electron_affinity eV"
    echo ""
    echo "## 3. Выводы"
    echo ""
  } > "$report_file"
}

# Loop over the neutral molecule directories
for dir in $neutral_dir/*; do
  if [ -d "$dir" ]; then
    base_name=$(basename "$dir")

    # Extract the total energy for the neutral molecule
    neutral_energy_file="$dir/$base_name.out"
    neutral_energy=$(get_total_energy "$neutral_energy_file")

    # Extract HOMO and LUMO energies
    homo_lumo=$(get_homo_lumo "$neutral_energy_file")

    # Extract the last geometry from trajectory file
    trj_file="$dir/${base_name}_trj.xyz"
    if [ -f "$trj_file" ]; then
      geometry_markdown=$(extract_and_format_geometry "$neutral_energy_file")
    else
      echo "Trajectory file for $base_name not found."
      geometry_markdown="Geometry not found."
    fi

    # Calculate ionization potential and electron affinity
    cation_energy_file="$cations_dir/${base_name}_cat/${base_name}_cat.out"
    anion_energy_file="$anions_dir/${base_name}_an/${base_name}_an.out"
    cation_energy=$(get_total_energy "$cation_energy_file")
    anion_energy=$(get_total_energy "$anion_energy_file")

    # Convert energies to eV and calculate IP and EA
    ionization_potential=$(echo "scale=6; ($neutral_energy - $cation_energy) * 27.2114" | bc)
    electron_affinity=$(echo "scale=6; ($anion_energy - $neutral_energy) * 27.2114" | bc)

    # Create Markdown report
    report_file="$report_dir/${base_name}_report.md"
    create_markdown_report $base_name $neutral_energy $cation_energy $anion_energy $ionization_potential $electron_affinity "$homo_lumo" "$geometry_markdown" $report_file
  fi
done

echo "All reports have been written to $report_dir in Markdown format."
