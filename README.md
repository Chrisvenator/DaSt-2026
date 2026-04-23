# DaSt-2026

Data Science project 2026.

---

## File organisation

All paths are relative to the repository root. Every file follows `snake_case` with no spaces. Version suffixes use `_vN` (integer N). Dates use `YYYYMMDD`.

### Directory layout

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

### Convention rules

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

### Field definitions

**`{dataset}`** — short, stable name for the source dataset (e.g. `census`, `titanic`).

**`{split}`** — data partition: `train`, `val`, `test`, or `full`.

**`{stage}`** — processing step applied: `cleaned`, `encoded`, `scaled`, `merged`.

**`{experiment}`** — short label for the experimental run or model variant (e.g. `baseline`, `tuned_lr`).

**`{descriptor}`** — human-readable detail distinguishing the file within its category (e.g. `confusion_matrix`, `feature_importance`).

**`{model}`** — algorithm short-name: `lr` (logistic regression), `rf` (random forest), `xgb`, `nn`, etc.

**`{NN}`** — two-digit zero-padded stage index enforcing execution order (`01`, `02`, …). Utility / helper scripts with no fixed order use the prefix `util_`.

---

### Configuration format — YAML

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

### Extension conventions

| Format | Preferred extension | Use for |
|---|---|---|
| Tabular data | `.csv`, `.parquet` | datasets |
| Model artefact | `.pkl`, `.joblib`, `.pt` | serialised models |
| Config | `.yaml` | all configuration — **YAML chosen over TOML/JSON because it supports inline comments, is the standard format in ML tooling (DVC, MLflow, Hydra, scikit-learn pipelines), and loads with no extra dependency (`PyYAML` ships with most ML stacks)** |
| Plot | `.png` (raster), `.pdf` (vector) | figures |
| Notebook | `.ipynb` | exploratory analysis only — not pipeline steps |
| Documentation | `.md` | notes, reports |

---

### Examples

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

### Update policy

Update this section whenever:
- a new category of file is introduced,
- the directory structure changes,
- a new experiment or dataset is added that requires a new `{experiment}` or `{dataset}` label.

Keep the examples table current — stale examples are worse than none.
