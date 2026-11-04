# 09 Runbook

Commands are examples. Adjust paths to match the VM. Never print the password file.

## Check heartbeats (on the VM)
```
psql -U pitchside_extract -d <db> -c "SELECT task_name, last_success_at, last_failure_at FROM public.task_heartbeats ORDER BY task_name;"
```
`refresh_fixtures` and `refresh_active_gameweeks` must have `last_success_at` after 05:30 UTC today.

## Run the extractor
```
python extractor.py
```
For testing, skip the heartbeat gate:
```
SKIP_GATE=1 python extractor.py
```

## List the bucket
```
gcloud storage ls gs://pitchside-lake-project-22f7491c/raw/ --recursive
```
A batch folder with Parquet files but no manifest is incomplete. Ignore it.

## If the gate fails (exit code 2)
1. Check the Celery services: `systemctl status fpl-worker fpl-beat`.
2. Check heartbeats as above.
3. Fix the app, wait for the tasks to succeed, then re-run the extractor.

## If one table fails
1. Read the error. Schema mismatch usually means a type is not set explicitly.
2. Fix, then re-run. A new batch gets a new `batch_id`; the old incomplete batch has no manifest and is ignored.
3. Do not load Bronze from a batch without a manifest.

## Running `mf` (MetricFlow) on Windows
`mf` needs the `DBT_PROFILES_DIR` environment variable set to the folder that holds `profiles.yml` (for example `C:\Users\<you>\.dbt`). Without it, `mf` fails with "Could not find profile".
```
$env:DBT_PROFILES_DIR = "$HOME\.dbt"     # PowerShell, for the current window
mf list metrics
```
Run `dbt parse` first after changing metrics, so `target/semantic_manifest.json` is up to date.
