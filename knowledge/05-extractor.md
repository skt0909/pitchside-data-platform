# 05 Extractor (extractor.py)

Reads Postgres and writes Parquet to the bucket. It never calls the football API.

## Steps
1. **Gate on heartbeats.** Check that `refresh_fixtures` and `refresh_active_gameweeks` succeeded after 05:30 UTC. Retry every 2 min for up to 30 min. If still failing, exit with code 2.
2. **One transaction.** Open a single REPEATABLE READ read-only transaction so all tables see the same moment in time.
3. **Read in chunks.** 2000 rows at a time using a server-side cursor, to keep memory low on the 1 GB VM.
4. **Explicit Arrow schema.** Build the schema from `information_schema`. Numeric columns become strings.
5. **Write Parquet.** One file per table at `raw/<schema>/<table>/dt=<date>/<batch_id>.parquet`.
6. **Write the manifest LAST.** A batch with no manifest is incomplete and must be ignored.

## Lesson learned
Letting pyarrow infer types per chunk caused a schema mismatch: decimal precision changed between chunks, and an all-NULL chunk was inferred as the null type. Fixed by declaring explicit types.
