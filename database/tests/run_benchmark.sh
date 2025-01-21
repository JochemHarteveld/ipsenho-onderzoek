#!/bin/bash

# Database credentials
DB_NAME="testdb"
DB_USER="postgres"
DB_PASS="postgres" # Not used but retained for potential future use

# PostgreSQL config file location
PG_CONF_FILE="/etc/postgresql/postgresql.conf"

# Log directory
LOG_DIR="../logs"
mkdir -p "$LOG_DIR"

# Function to extract values from the postgresql.conf file
log_pg_config() {
    echo "Logging PostgreSQL config..."

    # Extract shared_buffers and work_mem values from the config file, ignoring comments
    SHARED_BUFFERS=$(grep -E "^\s*shared_buffers\s*=" "$PG_CONF_FILE" | sed 's/^[^=]*=[[:space:]]*\([^#]*\).*/\1/' | xargs)
    WORK_MEM=$(grep -E "^\s*work_mem\s*=" "$PG_CONF_FILE" | sed 's/^[^=]*=[[:space:]]*\([^#]*\).*/\1/' | xargs)

    # Check if values are empty, then provide a default value
    if [ -z "$SHARED_BUFFERS" ]; then
        SHARED_BUFFERS="Not Defined"
    fi
    if [ -z "$WORK_MEM" ]; then
        WORK_MEM="Not Defined"
    fi

    echo "shared_buffers: $SHARED_BUFFERS"
    echo "work_mem: $WORK_MEM"
}

# Function to run benchmark queries and log the performance into a file
run_benchmark() {

    # Ensure shared_buffers and work_mem values are available
    if [ -z "$SHARED_BUFFERS" ] || [ -z "$WORK_MEM" ]; then
        echo "Error: shared_buffers or work_mem is not defined. Aborting benchmark."
        exit 1
    fi

    # Create the log file name based on parameters and timestamp
    TIMESTAMP=$(date +%Y%m%d%H%M%S)
    LOG_FILE="${LOG_DIR}/sb_${SHARED_BUFFERS}_wm_${WORK_MEM}_$TIMESTAMP.txt"

    # Write the configuration to the log file
    echo "Benchmark Log for shared_buffers = $SHARED_BUFFERS and work_mem = $WORK_MEM" > "$LOG_FILE"
    echo "Timestamp: $TIMESTAMP" >> "$LOG_FILE"
    echo "----------------------------------------------------" >> "$LOG_FILE"

    # Query 1: Read-heavy with joins and aggregation
    echo "Running Query 1: Read-heavy with joins and aggregation" >> "$LOG_FILE"
    query1_time=$(psql -U "$DB_USER" -d "$DB_NAME" -t -c "
        EXPLAIN ANALYZE
        SELECT t1.name, t2.name, SUM(t3.amount)
        FROM table1 t1
        JOIN table2 t2 ON t1.id = t2.t1_id
        JOIN table3 t3 ON t2.id = t3.t2_id
        GROUP BY t1.name, t2.name
        ORDER BY SUM(t3.amount) DESC
        LIMIT 10;
    " | grep "Execution Time" | awk '{print $3}')

    echo "Query 1 execution time: ${query1_time:-Error} ms" >> "$LOG_FILE"

    # Query 2: Write-heavy (INSERT)
    echo "Running Query 2: Write-heavy (INSERT)" >> "$LOG_FILE"
    query2_time=$(psql -U "$DB_USER" -d "$DB_NAME" -t -c "
        EXPLAIN ANALYZE
        INSERT INTO table1 (date, name)
        SELECT CURRENT_DATE, md5(random()::TEXT)
        FROM generate_series(1, 1000);
    " | grep "Execution Time" | awk '{print $3}')

    echo "Query 2 execution time: ${query2_time:-Error} ms" >> "$LOG_FILE"

    # Query 3: Large table scan
    echo "Running Query 3: Large table scan" >> "$LOG_FILE"
    query3_time=$(psql -U "$DB_USER" -d "$DB_NAME" -t -c "
        EXPLAIN ANALYZE
        SELECT COUNT(*) FROM large_table WHERE data_column LIKE 'abc%';
    " | grep "Execution Time" | awk '{print $3}')

    echo "Query 3 execution time: ${query3_time:-Error} ms" >> "$LOG_FILE"

    # Add separator for clarity
    echo "----------------------------------------------------" >> "$LOG_FILE"

    echo "Benchmark completed. Logs written to $LOG_FILE"
}

# Log PostgreSQL config to the database
log_pg_config

# Run benchmark with the extracted configuration
run_benchmark
