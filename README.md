# Road Traffic Accident Severity Classification Using Government Data

[![DOI](https://zenodo.org/badge/doi/10.5281/zenodo.20182653.svg)](https://doi.org/10.5281/zenodo.20182653)

Data Science project 2026.


## Abstract

This project applies supervised machine learning to predict the severity of road traffic accidents (fatal, serious, or slight) using the UK STATS19 accident records for the North Yorkshire Police force area (2009–2013). The dataset contains 8,358 accidents described by road conditions, weather, lighting, junction details, speed limits, and geographic coordinates. The full pipeline from raw data ingestion to model training and evaluation is implemented according to FAIR data principles: the dataset is stored in a normalised relational schema (3NF, 19 tables) in the TU Wien DBRepo test instance, all data access is performed exclusively via the DBRepo REST API, and all artefacts (code, data, models, outputs) are described with structured metadata (RO-Crate, CodeMeta, FAIR4ML, Croissant, Model Card).

---

# File organisation

All paths are relative to the repository root. Every file follows `snake_case` with no spaces. Version suffixes use `_vN` (integer N). Dates use `YYYYMMDD`.

---

## Requirements and Installation

### Prerequisites

- Python ≥ 3.10
- pip or conda

### Install dependencies

​```bash
# Clone the repository
git clone https://github.com/Chrisvenator/DaSt-2026.git
cd DaSt-2026

# Create and activate a virtual environment (recommended)
python -m venv .venv
source .venv/bin/activate        # Linux/macOS
.venv\Scripts\activate           # Windows

# Install dependencies
pip install -r requirements.txt
​```

### DBRepo credentials

Data is loaded exclusively from the TU Wien DBRepo REST API. Provide credentials via environment variables — do **not** commit them:

​```bash
export DBREPO_USERNAME=your_username
export DBREPO_PASSWORD=your_password
​```

Alternatively place them in a `.env` file (listed in `.gitignore`):

​```
DBREPO_USERNAME=your_username
DBREPO_PASSWORD=your_password
​```

---

## Step-by-Step Reproduction Instructions

### 1 – Set up the environment

Follow the installation steps above.

### 2 – (One-time) Initialise the DBRepo database and schema

This step was completed by the project team and the database is already live. To inspect or recreate it:

​```bash
jupyter notebook src/t2_1_dbrepo_schema.ipynb
​```

This notebook creates the 3NF schema in DBRepo via the REST API and adds citable metadata (publisher: UK Department for Transport; licence: OGL v3.0). The ER diagram is at `docs/ER_diagram.png` and the SQL DDL at `docs/schema.sql`.

### 3 – (One-time) Create DBRepo views

​```bash
jupyter notebook src/t2_4_views.ipynb
​```

Creates the five ML-ready SQL views documented in the DBRepo Views section.

### 4 – Run the ML experiment

​```bash
python src/train_experiment.py \
  --data-config config/data.yaml \
  --model-config config/model.yaml \
  --eval-config config/eval.yaml
​```

This will:
- Fetch all 8,358 rows from the DBRepo `ml_accident_features` view via the REST API
- Train a `RandomForestClassifier` on an 80/20 stratified split (seed 42)
- Write all outputs to `outputs/`

### 5 – Inspect outputs

| Output | Path |
|--------|------|
| Trained model | `outputs/models/severity_rf_baseline_v1.joblib` |
| Evaluation metrics | `outputs/metrics/severity_rf_baseline_v1_metrics.json` |
| Test-set predictions | `outputs/predictions/severity_rf_baseline_v1_predictions.csv` |
| Confusion matrix | `outputs/figures/severity_rf_baseline_v1_confusion_matrix.png` |

---

## Description of All Inputs and Outputs

### Inputs

| Item | Description | Location |
|------|-------------|----------|
| Raw accident data | UK STATS19 road accident records, North Yorkshire, 2009–2013. 8,358 records. Publisher: UK Department for Transport. Licence: OGL v3.0. | `data/raw/` (archive); live via DBRepo REST API |
| Attribute code reference | Lookup codes for road conditions, weather, lighting, junction types | `data/raw/2-attributecodesforroadsafety...` |
| DBRepo view | `ml_accident_features` — 25-column de-normalised feature table | DBRepo view UUID `45b21a9f-1b85-4035-8f1f-4fb699b70f5e` |
| Data config | Dataset paths, feature lists, split parameters | `config/data.yaml` |
| Model config | Algorithm type, hyperparameters | `config/model.yaml` |
| Eval config | Metrics list, output file paths | `config/eval.yaml` |

**Feature columns used for training:**

| Type | Columns |
|------|---------|
| Categorical (12) | `day_of_week`, `road_cond_id`, `light_condition_id`, `weather_condition_id`, `special_condition_id`, `carriageway_hazard_id`, `road_type_id`, `junction_detail_id`, `junction_control_id`, `crossing_control_id`, `crossing_facility_id`, `rural_urban` |
| Numeric (8) | `easting`, `northing`, `longitude`, `latitude`, `speed_limit_mph`, `casualties`, `vehicles`, `area_hectares` |
| Target | `severity_id` (1 = fatal, 2 = serious, 3 = slight) |
| Dropped | `police_ref`, `accident_date`, `accident_time`, `lad_name` |

### Outputs

| Item | Description | Location |
|------|-------------|----------|
| Trained model | Serialised `sklearn.Pipeline` (preprocessor + `RandomForestClassifier`) | `outputs/models/severity_rf_baseline_v1.joblib` |
| Metrics JSON | Accuracy, precision, recall, F1 (macro & weighted), ROC-AUC, per-class report, confusion matrix | `outputs/metrics/severity_rf_baseline_v1_metrics.json` |
| Predictions CSV | Test-set true vs predicted severity IDs with per-class probabilities | `outputs/predictions/severity_rf_baseline_v1_predictions.csv` |
| Confusion matrix | PNG figure (300 dpi) | `outputs/figures/severity_rf_baseline_v1_confusion_matrix.png` |

---

## Metadata Files

| File | Standard | Description |
|------|----------|-------------|
| `ro-crate-metadata.json` | RO-Crate 1.1 | Entire experiment package with all entity relationships and provenance |
| `codemeta.json` | CodeMeta 2.0 | Software metadata: authors, dependencies, runtime, licence |
| `docs/fair4ml_severity_rf_baseline_v1.json` | FAIR4ML | ML model metadata: algorithm, hyperparameters, training data, evaluation metrics |
| `docs/20260521_croissant.json` | Croissant (JSON-LD) | Input dataset field definitions with data types and QUDT/SI unit URIs |
| `docs/model-card.md` | Model Card | Human-readable model documentation: intended use, evaluation, limitations, ethics |
| `CITATION.cff` | CFF 1.2 | Citation metadata referencing Zenodo DOI `10.5281/zenodo.20182653` |

---

## Contributors

| Name | Role | ORCID |
|------|------|-------|
| Muhamad Moghrabi | T2.1 DBRepo schema, T3.1 RO-Crate, T3.5 Model Card, T3.9 Model deposit | [0009-0006-3778-025X](https://orcid.org/0009-0006-3778-025X) |
| Mehedy Hasan | T2.2 Semantic mapping, T2.7 Release, T3.2 CodeMeta, T3.6 Licences, T3.10 Generated data deposit | [0009-0002-4800-8178](https://orcid.org/0009-0002-4800-8178) |
| Sravanthi Muthineni | T2.3 Unit mapping, T2.5 DBRepo load, T3.3 FAIR4ML, T3.7 README, T3.11 Standards overlap | [0009-0009-8778-4701](https://orcid.org/0009-0009-8778-4701) |
| Christopher Scherling | T2.4 View definitions, T2.6 API reimplementation, T3.4 Croissant, T3.8 Zenodo DOI | [0009-0007-4090-3107](https://orcid.org/0009-0007-4090-3107) |


## Directory layout

```
DaSt-2026/
├── config/                  # configuration files (data.yaml, model.yaml, eval.yaml)
├── data/
│   ├── raw/                 # input datasets — never modified after deposit
│   └── processed/           # derived / cleaned datasets (convention; created on demand)
├── docs/                    # metadata, schema, model card, references
│   └── validation/          # RO-Crate / metadata validation output
├── outputs/
│   ├── figures/             # plots and visualisations
│   ├── metrics/             # evaluation metrics (JSON)
│   ├── models/              # serialised model artefacts
│   └── predictions/         # test-set predictions (CSV)
├── report/                  # final DMP report and peer review
└── src/                     # scripts, notebooks, and source code
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
