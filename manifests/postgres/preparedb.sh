#!/bin/bash

function createdb {
	/usr/bin/psql -U postgres -c "UPDATE pg_database SET datistemplate = FALSE WHERE datname = 'template1';"
	/usr/bin/psql -U postgres -c "DROP DATABASE template1;"
	/usr/bin/psql -U postgres -c "CREATE DATABASE template1 WITH TEMPLATE = template0 ENCODING = 'UTF8';"
    /usr/bin/psql -U postgres -c "CREATE DATABASE ezp WITH ENCODING 'UTF8'"
    /usr/bin/psql -U postgres -c "CREATE USER ezp WITH PASSWORD 'ezp'"
    /usr/bin/psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE ezp to ezp;"
    /usr/bin/psql -U postgres --dbname=ezp -c "create extension pgcrypto;"
    /usr/bin/psql -U postgres --dbname=ezp -c "\i '/usr/share/postgresql/9.1/extension/pgcrypto--1.0.sql'"
}

createdb