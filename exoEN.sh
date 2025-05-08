#!/bin/bash

# (a) Variable definitions
INPUT_DIR="assemblies_files"    # Working directory
LOG_FILE="abricate_pipeline.log" # Log file
SAMPLE_LIST="list.txt"          # List of samples

# (b) Redirecting output and errors to the log
exec > >(tee -a "$LOG_FILE") 2>&1

# Function for analysis with a specific database
run_analysis() {
    local db="$1"
    local category="$2"

    echo "========================== Starting $db analysis =========================="

    # Creating the output directory
    mkdir -p "$category/$db"

    # Analyzing samples
    while IFS= read -r sample; do
        local fasta="$INPUT_DIR/${sample}.fasta"
        local output="$category/$db/${sample}_${db}.tsv"

        echo "Processing $sample with $db..."
        abricate --db "$db" "$fasta" > "$output"

    done < "$SAMPLE_LIST"

    # Creating the summary file
    abricate --summary "$category/$db"/*.tsv > "$category/${db}_summary.tsv"

    echo "=== $db analysis finished ==="
}

# (c) Creating the list of samples
echo "Creating the list of samples..."
find "$INPUT_DIR" -name '*.fasta' -exec basename -s .fasta {} \; > "$SAMPLE_LIST"

# (d) Initializing the databases
echo "Updating databases..."
abricate --setupdb

# (e) AMR analysis
DATABASES_AMR=("resfinder" "card" "argannot" "ncbi" "megares")
for db in "${DATABASES_AMR[@]}"; do
    run_analysis "$db" "AMR"
done

# (f) Virulence factor analysis
run_analysis "vfdb" "Virulence"

# (g) Plasmid analysis
run_analysis "plasmidfinder" "Plasmids"

echo "Pipeline finished successfully!"
