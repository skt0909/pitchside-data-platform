import os
import sys

from dotenv import load_dotenv
from sqlalchemy import create_engine, text

load_dotenv()

url = os.environ.get("SRC_DB_URL")

engine = create_engine(url)
with engine.connect() as conn:
    host, db = conn.execute(text("select inet_server_addr()::text, current_database()")).fetchone()
    print(f"connected to database '{db}' at {host}")
    rows = conn.execute(text("""
        select table_name,
               (xpath('/row/c/text()',
                      query_to_xml(format('select count(*) as c from %I.%I',
                                          table_schema, table_name), false, true, '')))[1]::text::int as n
        from information_schema.tables
        where table_schema = 'ml' and table_type = 'BASE TABLE'
        order by table_name
    """))
    for name, n in rows:
        print(f"ml.{name}: {n} rows")