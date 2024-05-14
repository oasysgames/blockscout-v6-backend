#!/bin/bash

# Set Java environment variables
export JAVA_HOME=/usr/lib/jvm/jre-11
export JAVA_OPTS="-Xmx2048M -Xms2048M"

# Define the path to the environment file
ENV_FILE=./config/.env

# Load environment variables from the file
export $(grep -v '^#' "$ENV_FILE" | xargs -d '\n')

# Initialize array for tables to migrate
declare -a tables=()

# Parse command line options
while getopts ":t:" opt; do
  case $opt in
    t)
      IFS=',' read -ra tables <<< "$OPTARG"
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

# Define paths and filenames
dump_dir=~/dump

# Ensure the dump directory exists
mkdir -p "$dump_dir"

# Dump tables from source database
for table in "${tables[@]}"; do
   PGPASSWORD=$SOURCE_PASS pg_dump -h "$SOURCE_HOST" -p "$SOURCE_PORT" -U "$SOURCE_USER" -t "$table" -d "$SOURCE_DB" --data-only > "$dump_dir/$table.sql" &
done

wait

# Truncate tables in sink database
for table in "${tables[@]}"; do
        PGPASSWORD=$SINK_PASS psql -h "$SINK_HOST" -p "$SINK_PORT" -U "$SINK_USER"  -d "$SINK_DB" -c "TRUNCATE TABLE $table CASCADE;" &
done
wait


# Restore dumped tables to sink database
for table in "${tables[@]}"; do
        PGPASSWORD=$SINK_PASS psql -h "$SINK_HOST" -p "$SINK_PORT" -U "$SINK_USER"  -d "$SINK_DB" -f "$dump_dir/$table.sql" 
        wait
done

wait

echo "Database migration completed successfully."