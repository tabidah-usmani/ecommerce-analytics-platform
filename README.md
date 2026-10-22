# E-commerce Analytics Platform

An end-to-end data engineering and analytics project: a MySQL source system feeds an incremental pipeline into BigQuery, dbt models the data into a star schema, Airflow orchestrates it, and Power BI / Tableau present the insights.

> Status: 🚧 in progress. Phase 1 (foundation) is underway.

## Architecture

```
Olist CSVs -> MySQL (source) -> Python extract (incremental) -> GCS (Parquet)
           -> BigQuery (raw -> staging -> marts) -> dbt -> Power BI / Tableau

Simulated events -> Redpanda -> micro-batch files -> GCS -> BigQuery
Airflow orchestrates everything.
```

*(An architecture diagram will be added in `docs/`.)*

## Tech stack

| Layer | Tool |
|---|---|
| Source database | MySQL |
| Extract / load | Python (SQLAlchemy, pymysql, pandas, pyarrow) |
| Storage | Google Cloud Storage |
| Warehouse | BigQuery (sandbox) |
| Transformation and tests | dbt Core (`dbt-bigquery`) |
| Orchestration | Apache Airflow (Docker) |
| Streaming | Redpanda (Docker) |
| BI | Power BI Desktop, Tableau Public |
| CI/CD | GitHub Actions |

## Dataset

[Olist Brazilian E-commerce dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) (public, on Kaggle). Download the CSVs into `data/raw/`. They are git-ignored.

## Repository structure

```
.
├── mysql/          # schema, load scripts, users
├── ingestion/      # extract, load, API and event scripts
├── airflow/dags/   # orchestration DAGs
├── dbt/            # staging + marts models, tests, docs
├── notebooks/      # RFM, cohorts, delivery, forecasting
├── dashboards/     # Power BI file, Tableau link, screenshots
├── docs/           # architecture diagram, data dictionary
├── data/raw/       # downloaded CSVs (git-ignored)
└── .github/workflows/
```

## Getting started

1. Clone the repo and copy `.env.example` to `.env`, then fill in your values.
2. Set up MySQL and load the Olist data (see `mysql/`, coming in Step 2).
3. Set up GCP (project, BigQuery sandbox, GCS bucket, service account).
4. Run the pipeline (instructions will be added as each phase lands).

## Roadmap

- [x] Phase 0: repo skeleton
- [ ] Phase 1: MySQL source and incremental ingestion
- [ ] Phase 2: dbt modeling and tests
- [ ] Phase 3: Airflow orchestration and streaming
- [ ] Phase 4: analysis, dashboards, write-up

## Design decisions

*(To be filled in as the project progresses: why dbt, why incremental extracts, why batch over true streaming, how this would scale 100x.)*