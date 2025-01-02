#!/bin/bash

################## Configuration ##################

# Base paths
export IMDB_HOME="/home/ubuntu/imdb" # "${HOME}/imdb" 
export IMDB_DATA_DIR="${IMDB_HOME}/data"
export IMDB_TSV_DIR="${IMDB_DATA_DIR}/tsv"
export IMDB_SQL_DIR="${IMDB_HOME}/sql"

# Scripts location
readonly SCRIPT_DIR="${IMDB_HOME}/scripts"
readonly FETCH_SCRIPT="${SCRIPT_DIR}/fetch_datasets.sh"
readonly IMPORT_SCRIPT="${SCRIPT_DIR}/import_to_mysql.sh"

# MySQL configuration
export MYSQL_DEFAULTS_FILE="${IMDB_HOME}/mysql.cnf"
export MYSQL_DATABASE="imdb_base"
export MYSQL_HOST="localhost"

# Common settings
export MAX_RETRY_COUNT=3
export WAIT_TIME_BEFORE_RETRY=5

# List of IMDb datasets
export IMDB_DATASETS=(
    "name_basics"
    "title_basics"
    "title_akas"
    "title_crew"
    "title_episode"
    "title_principals"
    "title_ratings"
)

################### Functions ####################

check_prerequisites() {
    # Check MySQL configuration
    if [ ! -f "$MYSQL_DEFAULTS_FILE" ]; then
        echo "Error: MySQL defaults file not found at $MYSQL_DEFAULTS_FILE"
        return 1
    fi

    if ! mysql --defaults-file="$MYSQL_DEFAULTS_FILE" -h "$MYSQL_HOST" -e "SELECT 1;" &>/dev/null; then
        echo "Error: Cannot connect to MySQL server"
        return 1
    fi

    # Check if scripts exist
    local missing_requirements=0
    for script in "$FETCH_SCRIPT" "$IMPORT_SCRIPT"; do
        if [ ! -f "$script" ] || [ ! -x "$script" ]; then
            echo "Error: Required script not found or not executable: $script"
            missing_requirements=1
        fi
    done

    # Check if directories exist/can be created
    for dir in "$IMDB_DATA_DIR" "$IMDB_TSV_DIR" "$IMDB_SQL_DIR"; do
        if ! mkdir -p "$dir"; then
            echo "Error: Cannot create directory: $dir"
            missing_requirements=1
        fi
    done

    return "$missing_requirements"
}

################### Execution ###################

main() {
    echo "Checking prerequisites..."
    if ! check_prerequisites; then
        echo "Error: Prerequisites check failed"
        exit 1
    fi

    # echo "Starting IMDb dataset fetch..."
    # if ! source "$FETCH_SCRIPT"; then
    #     echo "Error: Fetch process failed"
    #     exit 1
    # fi

    echo "Starting IMDb dataset import..."
    if ! source "$IMPORT_SCRIPT"; then
        echo "Error: Import process failed"
        exit 1
    fi

    echo "IMDb dataset setup completed successfully!"
}

main
