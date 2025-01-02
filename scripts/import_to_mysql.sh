#!/bin/bash

################### Functions ####################

create_database() {
    echo "Creating and initializing database..."
    mysql --defaults-file="$MYSQL_DEFAULTS_FILE" -h "$MYSQL_HOST" \
        -e "DROP DATABASE IF EXISTS ${MYSQL_DATABASE}; CREATE DATABASE ${MYSQL_DATABASE};"
    
    if ! mysql --defaults-file="$MYSQL_DEFAULTS_FILE" -h "$MYSQL_HOST" \
        "$MYSQL_DATABASE" < "$IMDB_SQL_DIR/scheme.sql"; then
        echo "Error: Failed to initialize database schema"
        return 1
    fi
}

optimize_mysql() {
    echo "Optimizing MySQL settings for bulk import..."
    mysql --defaults-file="$MYSQL_DEFAULTS_FILE" -h "$MYSQL_HOST" "$MYSQL_DATABASE" <<EOF
    SET SESSION unique_checks = 0;
    SET SESSION foreign_key_checks = 0;
    SET SESSION sql_log_bin = 0;
    SET SESSION autocommit = 0;
EOF
}

restore_mysql_settings() {
    echo "Restoring MySQL settings..."
    mysql --defaults-file="$MYSQL_DEFAULTS_FILE" -h "$MYSQL_HOST" "$MYSQL_DATABASE" <<EOF
    SET SESSION unique_checks = 1;
    SET SESSION foreign_key_checks = 1;
    SET SESSION sql_log_bin = 1;
    SET SESSION autocommit = 1;
EOF
}

copy_to_secure_location() {
    local file_name=$1
    local source_file="${IMDB_TSV_DIR}/${file_name}.tsv"
    local target_file="${MYSQL_SECURE_DIR}/${file_name}.tsv"
    
    [ -f "$source_file" ] || {
        echo "ERROR: Source file not found: ${source_file}"
        return 1
    }
    
    if ! cp "$source_file" "$target_file"; then
        echo "Error: Failed to copy file to secure location"
        return 1
    fi
    
    echo "${target_file}"
    return 0
}

cleanup_secure_file() {
    local file_path=$1
    echo "Cleaning up temporary file..."
    rm -f "$file_path"
}

import_data() {
    local file_name=$1
    local table_name=$2
    local retry_count=0
    local success=false
    local secure_file
    
    echo "Starting copy_to_secure_location for ${file_name}"
    if ! secure_file=$(copy_to_secure_location "$file_name"); then
        echo "ERROR: copy_to_secure_location failed"
        return 1
    fi
    
    [ -f "$secure_file" ] || {
        echo "ERROR: Secure file not found at: ${secure_file}"
        return 1
    }
    
    echo "Starting import of ${file_name} into ${table_name}..."
    while [ $retry_count -lt $MAX_RETRY_COUNT ] && [ "$success" = false ]; do
        echo "Attempt $((retry_count + 1))/${MAX_RETRY_COUNT}"
        
        mysql --defaults-file="$MYSQL_DEFAULTS_FILE" -h "$MYSQL_HOST" "$MYSQL_DATABASE" \
            -e "TRUNCATE TABLE ${table_name};"
        
        if mysql --defaults-file="$MYSQL_DEFAULTS_FILE" -h "$MYSQL_HOST" "$MYSQL_DATABASE" <<EOF
        LOAD DATA INFILE '${secure_file}'
        INTO TABLE ${table_name}
        FIELDS TERMINATED BY '\t'
        ESCAPED BY ''
        LINES TERMINATED BY '\n'
        IGNORE 1 ROWS;
        FIELDS NULL AS '\N';
        COMMIT;
EOF
        then
            success=true
            echo "Successfully imported ${file_name}"
        else
            ((retry_count++))
            if [ $retry_count -lt $MAX_RETRY_COUNT ]; then
                echo "Import failed. Waiting ${WAIT_TIME_BEFORE_RETRY} seconds before retry..."
                sleep $WAIT_TIME_BEFORE_RETRY
            fi
        fi
    done

    cleanup_secure_file "$secure_file"

    if [ "$success" = false ]; then
        echo "Failed to import ${file_name} after ${MAX_RETRY_COUNT} attempts"
        return 1
    fi
    
    return 0
}

################### Execution ###################

main() {
    # Get secure_file_priv directory if not set in environment
    if [ -z "$MYSQL_SECURE_DIR" ]; then
        MYSQL_SECURE_DIR=$(mysql --defaults-file="$MYSQL_DEFAULTS_FILE" -h "$MYSQL_HOST" -N -B \
            -e "SHOW VARIABLES LIKE 'secure_file_priv';" | cut -f 2)

        if [ -z "$MYSQL_SECURE_DIR" ] || [ "$MYSQL_SECURE_DIR" = "NULL" ]; then
            echo "Error: secure_file_priv is not set or disabled"
            exit 1
        fi
    fi

    if ! create_database; then
        echo "Error: Database creation failed"
        exit 1
    fi

    optimize_mysql
    trap restore_mysql_settings EXIT

    local overall_success=true
    for table in "${IMDB_DATASETS[@]}"; do
        if ! import_data "${table//_/.}" "$table"; then
            overall_success=false
            echo "Critical error: Import failed for ${table//_/.}"
        fi
    done

    if [ "$overall_success" = false ]; then
        echo "Import process completed with errors."
        exit 1
    else
        echo "Import process completed successfully!"
    fi
}

main
