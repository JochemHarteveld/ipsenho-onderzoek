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
    echo "Extracting PostgreSQL config values..."

    # Extract shared_buffers and work_mem values from the config file, ignoring comments
    SHARED_BUFFERS=$(grep -E "^\s*shared_buffers\s*=" "$PG_CONF_FILE" | sed 's/^[^=]*=[[:space:]]*\([^#]*\).*/\1/' | xargs)
    WORK_MEM=$(grep -E "^\s*work_mem\s*=" "$PG_CONF_FILE" | sed 's/^[^=]*=[[:space:]]*\([^#]*\).*/\1/' | xargs)

    # Check if values are empty, then provide a default value
    if [ -z "$SHARED_BUFFERS" ]; then
        SHARED_BUFFERS="Not_Defined"
    fi
    if [ -z "$WORK_MEM" ]; then
        WORK_MEM="Not_Defined"
    fi

    echo "Shared Buffers: $SHARED_BUFFERS"
    echo "Work Mem: $WORK_MEM"
}

# Function to run benchmark queries and log the performance into a dynamically named CSV file
run_benchmark() {

    # Ensure shared_buffers and work_mem values are available
    if [ -z "$SHARED_BUFFERS" ] || [ -z "$WORK_MEM" ]; then
        echo "Error: shared_buffers or work_mem is not defined. Aborting benchmark."
        exit 1
    fi

    # Dynamically construct the CSV file name
    CSV_FILE="${LOG_DIR}/benchmark_results_SB_${SHARED_BUFFERS}_WM_${WORK_MEM}.csv"

    # Initialize CSV file with a header if it doesn't exist
    if [ ! -f "$CSV_FILE" ]; then
        echo "timestamp,read-heavy-query-time,write-heavy-query-time,large-table-scan-time" > "$CSV_FILE"
    fi

    # Timestamp for this benchmark
    TIMESTAMP=$(date +%Y-%m-%dT%H:%M:%S)

    # Query 1: Read-heavy with joins and aggregation
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

    # Query 2: Write-heavy (INSERT)
    query2_time=$(psql -U "$DB_USER" -d "$DB_NAME" -t -c "
        EXPLAIN ANALYZE
        INSERT INTO table1 (date, name)
        SELECT CURRENT_DATE, md5(random()::TEXT)
        FROM generate_series(1, 1000);
    " | grep "Execution Time" | awk '{print $3}')

    # Query 3: Large table scan
    query3_time=$(psql -U "$DB_USER" -d "$DB_NAME" -t -c "
        EXPLAIN ANALYZE
        SELECT COUNT(*) FROM large_table WHERE data_column LIKE 'abc%';
    " | grep "Execution Time" | awk '{print $3}')

    # Append the results to the CSV file
    echo "${TIMESTAMP},${query1_time:-Error},${query2_time:-Error},${query3_time:-Error}" >> "$CSV_FILE"
}

# Ensure the user provides the number of tests as an argument
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <number_of_tests>"
    exit 1
fi

# Number of iterations
NUM_TESTS=$1

# Extract PostgreSQL configuration values
log_pg_config

# Run the benchmark the specified number of times
for ((i=1; i<=NUM_TESTS; i++)); do
    echo "Running test $i of $NUM_TESTS..."
    run_benchmark
done

# Display all the results from the CSV file
CSV_FILE="${LOG_DIR}/benchmark_results_SB_${SHARED_BUFFERS}_WM_${WORK_MEM}.csv"
echo "All tests completed. Results:"
cat "$CSV_FILE"
