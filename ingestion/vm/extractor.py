import io, os, sys, json, time, uuid, decimal, datetime as dt
import psycopg, pyarrow as pa, pyarrow.parquet as pq
import google.auth
from google.auth import impersonated_credentials
from google.cloud import storage

PROJECT = "project-22f7491c-9bfd-4735-81c"
BUCKET = "pitchside-lake-project-22f7491c"
TARGET = f"pitchside-extractor@{PROJECT}.iam.gserviceaccount.com"
TABLES = ["ml.players", "ml.teams", "ml.fixtures", "ml.player_gw_stats", "ml.season_stats",
          "ml.player_gw_features", "ml.ml_predictions", "ml.fixture_poll_schedule",
          "public.gameweeks", "public.ruleset_epochs"]
GATE_TASKS = ["refresh_fixtures", "refresh_active_gameweeks"]
CHUNK = 2000

now = dt.datetime.now(dt.timezone.utc)
day = now.date()
batch_id = now.strftime("%Y%m%dT%H%M%SZ") + "-" + uuid.uuid4().hex[:8]
cutoff = dt.datetime.combine(day, dt.time(5, 30), tzinfo=dt.timezone.utc)
SKIP_GATE = os.getenv("SKIP_GATE") == "1"
pw = open(os.path.expanduser("~/.pitchside/pg_extract_pw")).read().strip()

PG2ARROW = {
    "integer": pa.int64(), "smallint": pa.int64(), "bigint": pa.int64(),
    "boolean": pa.bool_(), "double precision": pa.float64(), "real": pa.float64(),
    "numeric": pa.string(),
    "timestamp with time zone": pa.timestamp("us", tz="UTC"),
    "timestamp without time zone": pa.timestamp("us"),
    "date": pa.date32(),
}

def arrow_schema(conn, schema, name):
    rows = conn.execute(
        "SELECT column_name, data_type FROM information_schema.columns "
        "WHERE table_schema=%s AND table_name=%s ORDER BY ordinal_position", (schema, name)).fetchall()
    conn.rollback() if False else None
    return pa.schema([(c, PG2ARROW.get(t, pa.string())) for c, t in rows])

def norm(v):
    if isinstance(v, decimal.Decimal):
        return str(v)
    if isinstance(v, (dict, list)):
        return json.dumps(v)
    if v is not None and not isinstance(v, (int, float, bool, str, dt.date, dt.datetime)):
        return str(v)
    return v

def gate(conn):
    deadline = time.time() + 30 * 60
    while True:
        rows = dict(conn.execute(
            "SELECT task_name, last_success_at FROM public.task_heartbeats WHERE task_name = ANY(%s)",
            (GATE_TASKS,)).fetchall())
        conn.rollback()
        if all(t in rows and rows[t] and rows[t] > cutoff for t in GATE_TASKS):
            return {t: rows[t].isoformat() for t in GATE_TASKS}
        if time.time() > deadline:
            print("GATE FAILED: heartbeats not fresh since", cutoff.isoformat(), rows, file=sys.stderr)
            sys.exit(2)
        print("gate waiting...", rows, flush=True)
        time.sleep(120)

src, _ = google.auth.default(scopes=["https://www.googleapis.com/auth/cloud-platform"])
creds = impersonated_credentials.Credentials(
    source_credentials=src, target_principal=TARGET,
    target_scopes=["https://www.googleapis.com/auth/cloud-platform"], lifetime=1800)
bucket = storage.Client(project=PROJECT, credentials=creds).bucket(BUCKET)

manifest = {"batch_id": batch_id, "extract_date": str(day), "started_at": now.isoformat(), "tables": {}}
with psycopg.connect(host="127.0.0.1", dbname="pitchside_db", user="pitchside_extract", password=pw) as conn:
    manifest["heartbeats"] = "SKIPPED" if SKIP_GATE else gate(conn)
    conn.isolation_level = psycopg.IsolationLevel.REPEATABLE_READ
    conn.read_only = True
    manifest["snapshot_at"] = dt.datetime.now(dt.timezone.utc).isoformat()
    for t in TABLES:
        schema, name = t.split(".")
        sch = arrow_schema(conn, schema, name)
        cols = sch.names
        path = f"raw/{schema}/{name}/dt={day}/{batch_id}.parquet"
        buf = io.BytesIO()
        writer = pq.ParquetWriter(buf, sch)
        n = 0
        with conn.cursor(name=f"c_{name}") as cur:
            cur.execute(f"SELECT {', '.join(cols)} FROM {schema}.{name}")
            while True:
                rows = cur.fetchmany(CHUNK)
                if not rows:
                    break
                arrays = [pa.array([norm(r[i]) for r in rows], type=sch.field(i).type) for i in range(len(cols))]
                writer.write_table(pa.Table.from_arrays(arrays, schema=sch))
                n += len(rows)
        writer.close()
        size = buf.tell()
        bucket.blob(path).upload_from_string(buf.getvalue(), content_type="application/octet-stream")
        manifest["tables"][t] = {"path": f"gs://{BUCKET}/{path}", "rows": n, "bytes": size}
        print(f"{t}: {n} rows, {size} bytes", flush=True)
    last_pred = conn.execute("SELECT max(created_at) FROM ml.ml_predictions").fetchone()[0]
    manifest["frozen_tables"] = {"ml.ml_predictions": {"frozen": True, "latest_created_at": str(last_pred)}}

manifest["finished_at"] = dt.datetime.now(dt.timezone.utc).isoformat()
bucket.blob(f"raw/_manifests/dt={day}/{batch_id}.json").upload_from_string(json.dumps(manifest, indent=2), content_type="application/json")
print("MANIFEST WRITTEN", batch_id)