"""Dev helper: create the throwaway test database. Run before pytest if needed."""
import os
import sys

import psycopg

PW = os.environ.get("PGPASSWORD", "postgres")
USER = os.environ.get("PGUSER", "postgres")
HOST = os.environ.get("PGHOST", "localhost")
PORT = os.environ.get("PGPORT", "5432")
DB = "roadside_help_test"

try:
    conn = psycopg.connect(
        f"host={HOST} port={PORT} user={USER} password={PW} dbname=postgres", autocommit=True
    )
except Exception as e:  # noqa: BLE001
    print(f"CONNECT_FAILED: {e}")
    sys.exit(2)

with conn.cursor() as cur:
    cur.execute("SELECT 1 FROM pg_database WHERE datname = %s", (DB,))
    if not cur.fetchone():
        cur.execute(f'CREATE DATABASE "{DB}"')
        print("created")
    else:
        print("exists")
