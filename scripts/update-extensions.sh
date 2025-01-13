#!/bin/bash
set -e

echo "Updating extensions..."

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    ALTER EXTENSION postgis UPDATE;
    -- Add other extension update commands here
EOSQL
