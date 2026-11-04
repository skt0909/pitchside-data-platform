import sys, json, datetime as dt
import google.auth
from google.auth import impersonated_credentials
from google.cloud import bigquery, storage

PROJECT = "project-22f7491c-9bfd-4735-81c"
BUCKET = "pitchside-lake-project-22f7491c"
TARGET = f"pitchside-extractor@{PROJECT}.iam.gserviceaccount.com"
DATASET = "bronze"

src, _ = google.auth.default(scopes=["https://www.googleapis.com/auth/cloud-platform"])
creds = impersonated_credentials.Credentials(
    source_credentials=src, target_principal=TARGET,
    target_scopes=["https://www.googleapis.com/auth/cloud-platform"], lifetime=1800)
gcs = storage.Client(project=PROJECT, credentials=creds)
bq = bigquery.Client(project=PROJECT, credentials=creds, location="US")

# pick manifest: explicit batch arg, else newest
manifests = sorted(b.name for b in gcs.list_blobs(BUCKET, prefix="raw/_manifests/") if b.name.endswith(".json"))
if not manifests:
    print("no manifests found", file=sys.stderr); sys.exit(2)
mpath = next((m for m in manifests if len(sys.argv) > 1 and sys.argv[1] in m), manifests[-1])
manifest = json.loads(gcs.bucket(BUCKET).blob(mpath).download_as_text())
batch_id = manifest["batch_id"]
print("loading batch", batch_id, "from", mpath)

loaded_at = dt.datetime.now(dt.timezone.utc).isoformat()
failures = []
for table, info in manifest["tables"].items():
    schema, name = table.split(".")
    target = f"{PROJECT}.{DATASET}.{schema}_{name}"
    stg = f"{PROJECT}.{DATASET}._stg_{schema}_{name}"
    job = bq.load_table_from_uri(
        info["path"], stg,
        job_config=bigquery.LoadJobConfig(source_format=bigquery.SourceFormat.PARQUET,
                                          write_disposition="WRITE_TRUNCATE"))
    job.result()
    got = bq.get_table(stg).num_rows
    if got != info["rows"]:
        failures.append(f"{table}: manifest {info['rows']} vs loaded {got}")
        print("MISMATCH", failures[-1]); continue
    q = (f"CREATE OR REPLACE TABLE `{target}` AS SELECT *, '{batch_id}' AS _batch_id, "
         f"TIMESTAMP('{loaded_at}') AS _loaded_at, '{table}' AS _source_table FROM `{stg}`")
    bq.query(q).result()
    bq.delete_table(stg, not_found_ok=True)
    print(f"{table}: {got} rows -> {schema}_{name}", flush=True)

if failures:
    print("LOAD INCOMPLETE:", failures, file=sys.stderr); sys.exit(3)
print("BRONZE LOAD OK", batch_id)