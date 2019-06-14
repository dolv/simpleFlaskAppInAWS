#!/usr/bin/env bash

set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
	CREATE USER dbuser WITH
      LOGIN
      NOSUPERUSER
      INHERIT
      NOCREATEDB
      CREATEROLE
      REPLICATION
      PASSWORD '22222';
EOSQL

psql grover dbuser < ./grover_db.dump