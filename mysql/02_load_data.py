"""Load the Olist CSVs from data/raw into the MySQL source database.

Safe to re-run: it empties the tables first, then reloads them in
dependency order (parents before children).
"""
import os
import sys
from pathlib import Path

import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL

ROOT = Path(__file__).resolve().parents[1]
load_dotenv(ROOT / ".env")
RAW = ROOT / "data" / "raw"

# (table, csv file), parents first
TABLES = [
    ("product_category_name_translation", "product_category_name_translation.csv"),
    ("customers", "olist_customers_dataset.csv"),
    ("sellers", "olist_sellers_dataset.csv"),
    ("products", "olist_products_dataset.csv"),
    ("geolocation", "olist_geolocation_dataset.csv"),
    ("orders", "olist_orders_dataset.csv"),
    ("order_items", "olist_order_items_dataset.csv"),
    ("order_payments", "olist_order_payments_dataset.csv"),
    ("order_reviews", "olist_order_reviews_dataset.csv"),
]

# The source CSV misspells these two column names ("lenght")
RENAME = {
    "products": {
        "product_name_lenght": "product_name_length",
        "product_description_lenght": "product_description_length",
    }
}


def get_engine():
    url = URL.create(
        "mysql+pymysql",
        username=os.environ["MYSQL_ADMIN_USER"],
        password=os.environ["MYSQL_ADMIN_PASSWORD"],
        host=os.getenv("MYSQL_HOST", "localhost"),
        port=int(os.getenv("MYSQL_PORT", "3306")),
        database=os.environ["MYSQL_DATABASE"],
        query={"charset": "utf8mb4"},
    )
    return create_engine(url)


def main():
    missing = [f for _, f in TABLES if not (RAW / f).exists()]
    if missing:
        sys.exit(f"Missing CSV files in {RAW}:\n  " + "\n  ".join(missing))

    engine = get_engine()

    # Empty all tables so the script can be re-run
    with engine.begin() as conn:
        conn.execute(text("SET FOREIGN_KEY_CHECKS=0"))
        for table, _ in TABLES:
            conn.execute(text(f"TRUNCATE TABLE {table}"))
        conn.execute(text("SET FOREIGN_KEY_CHECKS=1"))

    for table, filename in TABLES:
        # Read everything as text so zip codes keep leading zeros (e.g. "01046").
        df = pd.read_csv(RAW / filename, dtype=str, keep_default_na=False, encoding="utf-8")
        df = df.rename(columns=RENAME.get(table, {}))
        df = df.where(df != "", None)  # empty string -> NULL

        df.to_sql(table, engine, if_exists="append", index=False,
                  chunksize=2000, method="multi")
        print(f"loaded {table:<36} {len(df):>9,} rows")

    print("\nRow counts in MySQL:")
    with engine.connect() as conn:
        for table, _ in TABLES:
            n = conn.execute(text(f"SELECT COUNT(*) FROM {table}")).scalar()
            print(f"  {table:<36} {n:>9,}")


if __name__ == "__main__":
    main()