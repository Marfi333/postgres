#!/bin/bash
set -e

# Initialize database if not exists
if [ ! -s "$PGDATA/PG_VERSION" ]; then
    initdb -D "$PGDATA" \
        --auth-host=scram-sha-256 \
        --auth-local=trust \
        --locale=hu_HU.UTF-8 \
        --encoding=UTF8

    # Configure PostgreSQL
    echo "host all all 0.0.0.0/0 scram-sha-256" >> "$PGDATA/pg_hba.conf"
    echo "listen_addresses = '*'" >> "$PGDATA/postgresql.conf"
    echo "lc_messages = 'hu_HU.UTF-8'" >> "$PGDATA/postgresql.conf"
    echo "lc_monetary = 'hu_HU.UTF-8'" >> "$PGDATA/postgresql.conf"
    echo "lc_numeric = 'hu_HU.UTF-8'" >> "$PGDATA/postgresql.conf"
    echo "lc_time = 'hu_HU.UTF-8'" >> "$PGDATA/postgresql.conf"

    # Start postgres temporarily to set password
    pg_ctl -D "$PGDATA" -w start

    # Set password and create database
    psql -v ON_ERROR_STOP=1 --username postgres <<-EOSQL
        ALTER USER postgres PASSWORD '$POSTGRES_PASSWORD';
        CREATE DATABASE "$POSTGRES_DB" WITH OWNER = postgres ENCODING = 'UTF8' LC_COLLATE = 'hu_HU.UTF-8' LC_CTYPE = 'hu_HU.UTF-8';
        
        -- Create custom user if different from postgres
        DO \$\$
        BEGIN
            IF '$POSTGRES_USER' != 'postgres' THEN
                CREATE USER "$POSTGRES_USER" WITH PASSWORD '$POSTGRES_PASSWORD';
                GRANT ALL PRIVILEGES ON DATABASE "$POSTGRES_DB" TO "$POSTGRES_USER";
                ALTER DATABASE "$POSTGRES_DB" OWNER TO "$POSTGRES_USER";
            END IF;
        END
        \$\$;
EOSQL

    # Stop temporary instance
    pg_ctl -D "$PGDATA" -m fast -w stop
fi

# Start PostgreSQL
if [ -n "${POSTGRES_PASSWORD:-}" ]; then
    cat > /var/lib/postgresql/.pgpass <<EOF
localhost:5432:*:${POSTGRES_USER:-postgres}:${POSTGRES_PASSWORD}
127.0.0.1:5432:*:${POSTGRES_USER:-postgres}:${POSTGRES_PASSWORD}
::1:5432:*:${POSTGRES_USER:-postgres}:${POSTGRES_PASSWORD}
EOF
    chmod 600 /var/lib/postgresql/.pgpass
fi

exec postgres -D "$PGDATA"
