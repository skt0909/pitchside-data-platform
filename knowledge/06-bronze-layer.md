# 06 Bronze layer

Bronze is a **faithful copy** of the source. Nothing more.

## What bronze_loader.py does
1. Load the Parquet files into a `_stg_` table.
2. Compare its row count with the manifest.
3. If they match, replace the published bronze table.
4. Add three columns: `_batch_id`, `_loaded_at`, `_source_table`.

## What Bronze does NOT do
- No renaming
- No casting
- No filtering
- No deduplication

Cleaning belongs to dbt silver.

## Snapshots
Each run is a full snapshot of the table. History stays in the bucket, not in BigQuery.
