#!/bin/bash

# Database credentials
DB_NAME=testdb
DB_USER=postgres
DB_PASS=postgres

# PostgreSQL config file location
PG_CONF_FILE="/etc/postgresql/postgresql.conf"


# Function to extract values from the postgresql.conf file
extract_pg_config() {
    # Extract shared_buffers and work_mem values from the config file, ignoring comments
    SHARED_BUFFERS=$(grep -E "^\s*shared_buffers\s*=" $PG_CONF_FILE | sed 's/^[^=]*=[[:space:]]*\([^#]*\).*/\1/' | xargs)
    WORK_MEM=$(grep -E "^\s*work_mem\s*=" $PG_CONF_FILE | sed 's/^[^=]*=[[:space:]]*\([^#]*\).*/\1/' | xargs)

    # Check if values are empty, then provide a default value
    if [ -z "$SHARED_BUFFERS" ]; then
        SHARED_BUFFERS="Not Defined"
    fi
    if [ -z "$WORK_MEM" ]; then
        WORK_MEM="Not Defined"
    fi
}

# Function to log the configuration values into a PostgreSQL table
log_pg_config() {
    echo "Logging PostgreSQL config..."

    # Create a table if it doesn't exist to log the values (you can adjust schema as needed)
    psql -U $DB_USER -d $DB_NAME -c "
    CREATE TABLE IF NOT EXISTS config_log (
        id SERIAL PRIMARY KEY,
        shared_buffers TEXT,
        work_mem TEXT,
        log_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    "

    # Insert the shared_buffers and work_mem into the table
    psql -U $DB_USER -d $DB_NAME -c "
    INSERT INTO config_log (shared_buffers, work_mem)
    VALUES ('$SHARED_BUFFERS', '$WORK_MEM');
    "
}

# Function to run benchmark queries
run_benchmark() {
    echo "Running benchmark with:"
    echo "shared_buffers = $1"
    echo "work_mem = $2"

    # Query 1: Read-heavy with joins and aggregation
    psql -U $DB_USER -d $DB_NAME -c "
        EXPLAIN ANALYZE
        SELECT t1.name, t2.name, SUM(t3.amount)
        FROM table1 t1
        JOIN table2 t2 ON t1.id = t2.t1_id
        JOIN table3 t3 ON t2.id = t3.t2_id
        GROUP BY t1.name, t2.name
        ORDER BY SUM(t3.amount) DESC
        LIMIT 10;
    "

    # Query 2: Write-heavy (INSERT)
    psql -U $DB_USER -d $DB_NAME -c "
        EXPLAIN ANALYZE
        INSERT INTO table1 (date, name)
        SELECT CURRENT_DATE, md5(random()::TEXT)
        FROM generate_series(1, 1000);
    "

    # Query 3: Large table scan
    psql -U $DB_USER -d $DB_NAME -c "
        EXPLAIN ANALYZE
        SELECT COUNT(*) FROM large_table WHERE data_column LIKE 'abc%';
    "
}

# Extract PostgreSQL config values from the postgresql.conf file
extract_pg_config

# Log PostgreSQL config to the database
log_pg_config

# Run benchmark with the extracted configuration
run_benchmark $SHARED_BUFFERS $WORK_MEM
