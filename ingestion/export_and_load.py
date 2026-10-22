"""Copy the public football tables from local Postgres to Parquet files and BigQuery."""
import os
import sys
from pathlib import Path

import pandas as pd
from dotenv import load_dotenv
from google.cloud import bigquery
from sqlalchemy import create_engine

load_dotenv()

TABLES = ["teams", "players", "fixtures", "player_gw_stats", "ml_predictions"]
SCHEMA = "ml"
OUT_DIR = Path("exports")

src_url = os.environ.get("SRC_DB_URL")
project = os.environ.get("GCP_PROJECT")
if not src_url or not project:
    sys.exit("Set SRC_DB_URL and GCP_PROJECT in .env")

engine = create_engine(src_url)
client = bigquery.Client(project=project)
OUT_DIR.mkdir(exist_ok=True)

for table in TABLES:
    df = pd.read_sql(f"select * from {SCHEMA}.{table}", engine)
    df.to_parquet(OUT_DIR / f"{table}.parquet", index=False)

    table_id = f"{project}.raw.{table}"
    job = client.load_table_from_dataframe(
        df,
        table_id,
        job_config=bigquery.LoadJobConfig(write_disposition="WRITE_TRUNCATE"),
    )
    job.result()
    loaded = client.get_table(table_id)
    print(f"{table}: {len(df)} rows read, {loaded.num_rows} rows in {table_id}")