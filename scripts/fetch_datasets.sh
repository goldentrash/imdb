#!/bin/bash

# Base URL for IMDb datasets
readonly IMDB_REGISTRY="https://datasets.imdbws.com"

################### Functions ####################

fetch_dataset() {
    local dataset=$1
    local file_name="${dataset//_/.}"
    local retry_count=0
    local success=false

    while [ $retry_count -lt $MAX_RETRY_COUNT ] && [ "$success" = false ]; do
        echo "Fetching ${file_name}.tsv.gz (Attempt $((retry_count + 1))/${MAX_RETRY_COUNT})"
        
        if wget -q --show-progress "${IMDB_REGISTRY}/${file_name}.tsv.gz"; then
            if gunzip -t "${file_name}.tsv.gz" &>/dev/null; then
                success=true
                echo "Successfully fetched and verified ${file_name}"
            else
                echo "Downloaded file is corrupted"
                rm -f "${file_name}.tsv.gz"
                ((retry_count++))
            fi
        else
            ((retry_count++))
            if [ $retry_count -lt $MAX_RETRY_COUNT ]; then
                echo "Fetch failed. Waiting ${WAIT_TIME_BEFORE_RETRY} seconds before retry..."
                sleep $WAIT_TIME_BEFORE_RETRY
                rm -f "${file_name}.tsv.gz"
            fi
        fi
    done

    if [ "$success" = false ]; then
        echo "Failed to fetch ${file_name} after ${MAX_RETRY_COUNT} attempts" >&2
        return 1
    fi
    
    return 0
}

extract_files() {
    echo "Extracting files..."
    local extract_failed=0
    
    for file in *.gz; do
        echo "Extracting $file..."
        if ! gunzip -f "$file"; then
            echo "Failed to extract $file" >&2
            extract_failed=1
        fi
    done

    return "$extract_failed"
}

################### Execution ###################

main() {
    # Clean or create directory
    if [ -d "$IMDB_TSV_DIR" ]; then
        echo "Cleaning existing directory: $IMDB_TSV_DIR"
        rm -f "$IMDB_TSV_DIR"/*
    else
        echo "Creating directory: $IMDB_TSV_DIR"
        if ! mkdir -p "$IMDB_TSV_DIR"; then
            echo "Error: Failed to create directory: $IMDB_TSV_DIR" >&2
            exit 1
        fi
    fi

    # Change to working directory
    if ! cd "$IMDB_TSV_DIR"; then
        echo "Error: Failed to change to directory: $IMDB_TSV_DIR" >&2
        exit 1
    fi

    local overall_success=true
    for dataset in "${IMDB_DATASETS[@]}"; do
        if ! fetch_dataset "$dataset"; then
            overall_success=false
            echo "Critical error: Fetch failed for ${dataset}" >&2
            break
        fi
    done

    if [ "$overall_success" = true ]; then
        if ! extract_files; then
            overall_success=false
        fi
    fi

    if [ "$overall_success" = false ]; then
        echo "Fetch process completed with errors."
        exit 1
    else
        echo "Fetch process completed successfully!"
    fi
}

main
