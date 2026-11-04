# 03 GCP setup

## What exists
- **Project** `project-22f7491c-9bfd-4735-81c`, under an organisation.
- **Bucket** `gs://pitchside-lake-project-22f7491c`: us-central1, private, uniform access, public access prevention on. Holds the raw Parquet files.
- **BigQuery datasets** `bronze`, `silver`, `gold`, location US.
- **Service account** `pitchside-extractor`:
  - objectAdmin on the bucket only
  - WRITER on the `bronze` dataset only
  - `bigquery.jobUser` on the project
- **Budget alert** is set.

## Why no key file
An organisation policy blocks service account keys. So the VM *impersonates* the extractor account:
- The VM's default compute service account has `serviceAccountTokenCreator` on `pitchside-extractor`.
- The VM access scope was widened to `cloud-platform`.
  Original scopes were: devstorage.read_only, logging.write, monitoring.write, service.management.readonly, servicecontrol, trace.append.

## Why these locations
us-central1 bucket and US datasets keep us in the free tier and avoid egress charges.
