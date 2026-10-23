"""Checks that CREATE TABLE AS SELECT / CREATE VIEW work (what dbt needs)."""
import os
from pathlib import Path

from dotenv import load_dotenv
from google.cloud import bigquery

ROOT = Path(__file__).resolve().parents[1]
load_dotenv(ROOT / ".env")

key = Path(os.environ["GOOGLE_APPLICATION_CREDENTIALS"])
if not key.is_absolute():
    key = ROOT / key
os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = str(key)

project = os.environ["GCP_PROJECT_ID"]
ds = os.environ["BQ_STAGING_DATASET"]
client = bigquery.Client(project=project, location="US")

steps = {
    "CREATE TABLE AS SELECT": f"CREATE OR REPLACE TABLE `{project}.{ds}.ddl_test` AS SELECT 1 AS x",
    "CREATE VIEW": f"CREATE OR REPLACE VIEW `{project}.{ds}.ddl_view` AS SELECT * FROM `{project}.{ds}.ddl_test`",
    "SELECT from view": f"SELECT COUNT(*) AS n FROM `{project}.{ds}.ddl_view`",
}
for name, sql in steps.items():
    try:
        client.query(sql).result()
        print(f"{name}: OK")
    except Exception as e:
        print(f"{name}: FAILED -> {str(e)[:200]}")

client.delete_table(f"{project}.{ds}.ddl_view", not_found_ok=True)
client.delete_table(f"{project}.{ds}.ddl_test", not_found_ok=True)
print("cleanup OK")