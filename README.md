# DaSt-2026: Road Safety Analysis

[![DOI](https://zenodo.org/badge/doi/10.5281/zenodo.20182653.svg)](https://doi.org/10.5281/zenodo.20182653)

Data Science project 2026.


TODO - topic
TODO - use case

---

# File organisation

All paths are relative to the repository root. Every file follows `snake_case` with no spaces. Version suffixes use `_vN` (integer N). Dates use `YYYYMMDD`.

## Directory layout

```
DaSt-2026/
├── config/                  # configuration files
├── data/
│   ├── raw/                 # input datasets — never modified after deposit
│   └── processed/           # derived / cleaned datasets
├── docs/                    # reports, notes, references
├── outputs/
│   ├── figures/             # plots and visualisations
│   └── models/              # serialised model artefacts
└── src/                     # scripts and source code
```

---

## Convention rules

| Category | Location | Pattern | Example |
|---|---|---|---|
| Raw input dataset | `data/raw/` | `{dataset}_{split}_{vN}.{ext}` | `census_train_v1.csv` |
| Processed dataset | `data/processed/` | `{dataset}_{stage}_{vN}.{ext}` | `census_encoded_v2.parquet` |
| Figure / plot | `outputs/figures/` | `{experiment}_{descriptor}.{ext}` | `baseline_confusion_matrix.png` |
| Model artefact | `outputs/models/` | `{model}_{experiment}_{vN}.{ext}` | `random_forest_baseline_v1.pkl` |
| Script | `src/` | `{NN}_{verb}_{descriptor}.py` | `01_preprocess_census.py` |
| Config file | `config/` | `{component}.yaml` | `model.yaml`, `data.yaml` |
| Report / doc | `docs/` | `{YYYYMMDD}_{descriptor}.{ext}` | `20260423_experiment_notes.md` |

---

## Field definitions

**`{dataset}`** — short, stable name for the source dataset (e.g. `census`, `titanic`).

**`{split}`** — data partition: `train`, `val`, `test`, or `full`.

**`{stage}`** — processing step applied: `cleaned`, `encoded`, `scaled`, `merged`.

**`{experiment}`** — short label for the experimental run or model variant (e.g. `baseline`, `tuned_lr`).

**`{descriptor}`** — human-readable detail distinguishing the file within its category (e.g. `confusion_matrix`, `feature_importance`).

**`{model}`** — algorithm short-name: `lr` (logistic regression), `rf` (random forest), `xgb`, `nn`, etc.

**`{NN}`** — two-digit zero-padded stage index enforcing execution order (`01`, `02`, …). Utility / helper scripts with no fixed order use the prefix `util_`.

---

## Configuration format — YAML

All config files live in `config/` and use `.yaml`. One file per concern:

| File | Purpose |
|---|---|
| `config/data.yaml` | dataset paths, split ratios, preprocessing flags |
| `config/model.yaml` | algorithm choice, hyperparameters, random seed |
| `config/eval.yaml` | metrics to compute, threshold values, output paths |

**Loading in Python:**

```python
import yaml

with open("config/model.yaml") as f:
    cfg = yaml.safe_load(f)
```

**Rules:**
- All keys `snake_case`.
- Secrets (API keys, passwords) go in `.env`, never in YAML — reference them via environment variables.
- Bump the comment `# version:` field when changing values that affect reproducibility.

**`{vN}`** — monotonically increasing integer version starting at `1`. Bump when inputs or parameters change in a non-trivial way.

**`{YYYYMMDD}`** — ISO 8601 date (e.g. `20260423`).

---

## Extension conventions

| Format | Preferred extension | Use for |
|---|---|---|
| Tabular data | `.csv`, `.parquet` | datasets |
| Model artefact | `.pkl`, `.joblib`, `.pt` | serialised models |
| Config | `.yaml` | all configuration — **YAML chosen over TOML/JSON because it supports inline comments, is the standard format in ML tooling (DVC, MLflow, Hydra, scikit-learn pipelines), and loads with no extra dependency (`PyYAML` ships with most ML stacks)** |
| Plot | `.png` (raster), `.pdf` (vector) | figures |
| Notebook | `.ipynb` | exploratory analysis only — not pipeline steps |
| Documentation | `.md` | notes, reports |

---

## Examples

```
data/raw/census_train_v1.csv
data/raw/census_test_v1.csv
data/processed/census_encoded_v1.parquet
data/processed/census_scaled_v2.parquet

outputs/figures/baseline_confusion_matrix.png
outputs/figures/baseline_roc_curve.pdf
outputs/models/rf_baseline_v1.pkl
outputs/models/xgb_tuned_v3.pkl

src/01_preprocess_census.py
src/02_train_baseline.py
src/03_evaluate_models.py
src/util_metrics.py

config/data.yaml
config/model.yaml
```

---

## Database schema

The relational schema (3NF) is defined in `docs/schema.sql` with descriptive
seed data for all coded attributes. The ER diagram (`docs/ER_diagram.png`)
is rendered from `docs/schema.dbml`; paste that file at https://dbdiagram.io
to regenerate.

The schema is instantiated in DBRepo via `src/notebooks/t2_1_dbrepo_schema.ipynb`,
which uses the DBRepo REST API to create the database, tables and seed lookup
rows with full citable metadata (publisher: UK Department for Transport;
license: Open Government Licence v3.0).

## Source Data and Citation

### Underlying Dataset

| Field | Value |
|---|---|
| Title | Road Safety Data – North Yorkshire Highways Authority (2009–2013) |
| Original publisher | UK Department for Transport |
| Original collector | North Yorkshire Police, via the UK STATS19 reporting system |
| Republisher | North Yorkshire County Council (Open Data Hub) |
| Access portal | European Data Portal (data.europa.eu) |
| Source URL | https://data.europa.eu/data/datasets/road-safety-data?locale=en |
| Upstream URL | https://data.gov.uk/dataset/cb7ae6f0-4be6-4935-9277-47e5ce24a11f/road-safety-data |
| License | UK Open Government Licence v3.0 |
| License URL | https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/ |
| Records | 8,358 accidents |
| Temporal coverage | 2009–01–01 to 2013–12–31 |
| Geographic coverage | North Yorkshire Police force area, England |

### Re-publication in DBRepo

This project re-publishes the dataset in a relational schema normalised to Third
Normal Form (19 tables) on the TU Wien DBRepo test instance.

| Field | Value |
|---|---|
| Repository | TU Wien DBRepo (test instance) |
| Endpoint | https://test.dbrepo.tuwien.ac.at |
| Database UUID | f36ef3e2-1aee-4526-b3ea-82f661a9261a |
| Database name | rta_stats19_north_yorkshire |
| Container UUID | 6cfb3b8e-1792-4e46-871a-f3d103527203 (MariaDB Galera 11.3.2) |
| Tables | 19 (see docs/schema.sql) |
| Schema | 3NF; ER diagram at docs/er-diagram.png |

### Citation

When citing this re-published database, please attribute both the original
publisher and this project:

> UK Department for Transport. *Road Safety Data – North Yorkshire Highways
> Authority (2009–2013)*. Originally published on data.gov.uk, accessed via
> the European Data Portal. Re-published in 3NF schema by Group A
> (DaSt 2026, TU Wien), TU Wien DBRepo test instance, database UUID
> `f36ef3e2-1aee-4526-b3ea-82f661a9261a`, under the UK Open Government
> Licence v3.0.

### Status of citable identifier

A DataCite identifier for the DBRepo deposit was attempted via
`POST /api/v1/identifier` but encountered an HTTP 500 on the test instance
on 2026-05-07; the issue has been reported to the DBRepo maintainer and will
be added once resolved. See `src/notebooks/t2_1_dbrepo_schema.ipynb`
(Section 8) for the prepared payload.

## DBRepo REST API (T2.6)

All experiment data is loaded exclusively from the DBRepo REST API.
No local CSV reads are used in the final pipeline code.

**Base URL**: `https://test.dbrepo.tuwien.ac.at`

**Authentication**: HTTP Basic Auth — `Authorization: Basic base64(username:password)`.
Credentials are read from `src/dbrepo_ids.json` (username/password stored separately;
never commit secrets to the repository).

**Endpoints used**:

| Method | Path | Parameters | Purpose |
|--------|------|------------|---------|
| `GET` | `/api/v1/database/{database_id}/view/{view_id}/data` | `page` (0-based), `size` | Fetch one page of view rows |

**Accept header required**: `Accept: application/json`  
**Response**: JSON array of row objects; empty array signals end of results.  
**Pagination**: increment `page` until the response array is shorter than `size`.

**Views available**:

| View name | View UUID | Filter | Rows |
|-----------|-----------|--------|------|
| `ml_accident_features` | `45b21a9f-1b85-4035-8f1f-4fb699b70f5e` | — | 8 358 |
| `ml_fatal_accidents` | `2aa96a2e-7712-4dd6-b8a6-5e22f9f65ff8` | severity_id = 1 | 197 |
| `ml_serious_accidents` | `c227209b-b343-4be1-8dce-cc5b80713249` | severity_id = 2 | 1 828 |
| `ml_rural_accidents` | `cd39a570-eaee-4264-ac05-2c7a7fdc8e6b` | rural_urban = 'Rural' | 5 973 |
| `ml_high_speed_accidents` | `3f339d05-9cf6-4aa8-b7f7-bcf2a1693860` | speed_limit_mph ≥ 60 | 4 970 |

See `src/t2_6_api_reimplementation.ipynb` for the full loader implementation and
verification that results are identical to the original local-file version.

---

## DBRepo Views (T2.4)

Five named SQL views expose query-ready projections of the accident data.
All share the same 25-column projection joined across three tables
(`accident → output_area → lower_super_output_area → local_authority_district`).

| View | Purpose |
|------|---------|
| `ml_accident_features` | Full de-normalised feature table — primary training dataset |
| `ml_fatal_accidents` | Fatal accidents only (severity = 1) — minority-class subset for oversampling |
| `ml_serious_accidents` | Serious accidents only (severity = 2) — minority-class subset |
| `ml_rural_accidents` | Rural-area accidents — geographic stratification slice |
| `ml_high_speed_accidents` | Roads with speed limit ≥ 60 mph — speed-conditioned analysis slice |

View SQL is in `docs/views.sql`. Views are created via `src/t2_4_views.ipynb`.

---

## ML experiment

The final experiment predicts accident severity (`severity_id`: 1 = fatal, 2 = serious, 3 = slight) from the DBRepo view `ml_accident_features`.

| Item | Description |
|---|---|
| Experiment ID | `severity_rf_baseline_v1` |
| Task | Multiclass accident severity classification |
| Input data | DBRepo REST API view `ml_accident_features` |
| Target column | `severity_id` |
| Classes | `1 = fatal`, `2 = serious`, `3 = slight` |
| Model | `RandomForestClassifier` |
| Test split | 20% |
| Random seed | 42 |
| Stratification | By `severity_id` |

The model uses accident context, road condition, weather condition, lighting condition, location, speed limit, vehicle count, casualty count, and rural/urban features. Identifier and descriptive columns such as `police_ref`, `accident_date`, `accident_time`, and `lad_name` are not used as model features.

The experiment is implemented in `src/train_experiment.py` and configured through:

- `config/data.yaml`
- `config/model.yaml`
- `config/eval.yaml`

The data is loaded exclusively from the DBRepo REST API. No local CSV files are used in the final experiment code. The main DBRepo view endpoint is:

`/api/v1/database/f36ef3e2-1aee-4526-b3ea-82f661a9261a/view/45b21a9f-1b85-4035-8f1f-4fb699b70f5e/data`

Authentication uses HTTP Basic Auth via the environment variables `DBREPO_USERNAME` and `DBREPO_PASSWORD`.

The final model is a Random Forest classifier with class balancing enabled. The model artefact, predictions, metrics, and confusion matrix are written to the `outputs/` directory.


## RO-Crate (T3.1)

The full experiment package — input data, code, trained model, outputs, authors, and licences — is described in [`ro-crate-metadata.json`](./ro-crate-metadata.json) following the RO-Crate 1.1 specification. Validation output is in `docs/validation/`.

## Update policy

Update this section whenever:
- a new category of file is introduced,
- the directory structure changes,
- a new experiment or dataset is added that requires a new `{experiment}` or `{dataset}` label.

Keep the examples table current — stale examples are worse than none.

## Licences

### 1. Input Data
The source dataset (STATS19 Road Traffic Accidents, North Yorkshire, 2009–2013)
is published by the **UK Department for Transport** under the
**Open Government Licence v3.0 (OGL v3.0)**.
Full licence: https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/

Our use — training a machine learning classifier and publishing results — is
fully permitted under OGL v3.0. The licence requires source acknowledgement
but does **not** impose ShareAlike conditions, so output data may be released
under a separate licence (CC BY 4.0) without conflict.

### 2. Software / Code
All code in this repository is licensed under the **MIT License**.
See the `LICENSE` file in the repository root.

MIT was chosen because it is permissive and fully compatible with OGL v3.0 —
neither licence imposes copyleft or ShareAlike obligations that would conflict
with the other. MIT is also compatible with CC BY 4.0 on the output data side.

### 3. Output Data (Models, Predictions, Figures)
All generated outputs are released under
**Creative Commons Attribution 4.0 International (CC BY 4.0)**.
Full licence: https://creativecommons.org/licenses/by/4.0/

This covers:
- `outputs/models/severity_rf_baseline_v1.joblib`
- `outputs/predictions/severity_rf_baseline_v1_predictions.csv`
- `outputs/metrics/severity_rf_baseline_v1_metrics.json`
- `outputs/figures/severity_rf_baseline_v1_confusion_matrix.png`

CC BY 4.0 is compatible with OGL v3.0 and requires only attribution when
reusing derived outputs.