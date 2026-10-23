"""Checks BigQuery access and probes sandbox limits (DML support)."""
import os
from pathlib import Path

import pandas as pd
from dotenv import load_dotenv
from google.cloud import bigquery

ROOT = Path(__file__).resolve().parents[1]
load_dotenv(ROOT / ".env")

# Resolve the key path against the repo root so it works from any folder
key = Path(os.environ["GOOGLE_APPLICATION_CREDENTIALS"])
if not key.is_absolute():
    key = ROOT / key
os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = str(key)

project = os.environ["GCP_PROJECT_ID"]
client = bigquery.Client(project=project, location="US")
table_id = f"{project}.{os.environ['BQ_RAW_DATASET']}.connection_test"

# 1. Load job (this is how the pipeline will load data)
df = pd.DataFrame({"id": [1, 2, 3], "name": ["a", "b", "c"]})
client.load_table_from_dataframe(
    df, table_id, job_config=bigquery.LoadJobConfig(write_disposition="WRITE_TRUNCATE")
).result()
print("load job OK")

# 2. Query
rows = list(client.query(f"SELECT COUNT(*) AS n FROM `{table_id}`").result())
print("query OK, rows =", rows[0].n)

# 3. DML probe (matters for MERGE-based incremental loads)
try:
    client.query(f"DELETE FROM `{table_id}` WHERE id = 3").result()
    print("DML OK (DELETE/MERGE allowed)")
except Exception as e:
    print("DML NOT allowed in this project:", str(e)[:200])

client.delete_table(table_id, not_found_ok=True)
print("cleanup OK")