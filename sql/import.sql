-- Disable constraints and optimizations for batch processing
SET SESSION foreign_key_checks = 0;
SET SESSION unique_checks = 0;
SET SESSION sql_log_bin = 0;
SET SESSION autocommit = 0;

-- Clear existing data
TRUNCATE TABLE __TABLE_NAME__;

-- Import TSV data with NULL handling
LOAD DATA INFILE '__FILE_PATH__'
INTO TABLE __TABLE_NAME__
    FIELDS TERMINATED BY '\t'
    ESCAPED BY ''
    LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Commit transaction
COMMIT;

-- Note: Session settings will be restored when connection ends
