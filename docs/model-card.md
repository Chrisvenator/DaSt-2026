# Model Card: `severity_rf_baseline_v1`

| | |
|---|---|
| **Model name** | `severity_rf_baseline_v1` |
| **Version** | 1.0 |
| **Date** | 2026-05-22 |
| **Group** | DaSt 2026, TU Wien — Group A |
| **Authors** | A — Moghrabi Muhamad, https://orcid.org/0009-0006-3778-025X, B — Hasan Mehedy, https://orcid.org/0009-0002-4800-8178, C — Muthineni Sravanthi, https://orcid.org/0009-0009-8778-4701, D — Scherling Christopher, https://orcid.org/0009-0007-4090-3107 |
| **Repository** | https://github.com/Chrisvenator/DaSt-2026 |
| **Software release (Zenodo)** | https://doi.org/10.5281/zenodo.20182653 |
| **Model deposit (TUWRD)** | https://handle.test.datacite.org/10.70124/3ykwc-3sg80 |
| **FAIR4ML metadata** | docs/fair4ml_severity_rf_baseline_v1.json |

## Model description

`severity_rf_baseline_v1` is a multiclass random-forest classifier that predicts road-accident severity (`fatal`, `serious`, `slight`) from accident context, road condition, weather, lighting, location, speed limit, and basic vehicle/casualty counts. It is the baseline model for the DaSt 2026 FAIR data-science exercise and was trained on 6,686 accidents from the North Yorkshire STATS19 records (2009–2013), evaluated on a held-out 1,672-row stratified split. The implementation is a single scikit-learn `Pipeline` that bundles imputation, one-hot encoding for categorical features, and a `RandomForestClassifier` with class balancing; the whole pipeline is fitted jointly and serialised as one `.joblib` artefact (`severity_rf_baseline_v1.joblib`).

**Algorithm**: `sklearn.ensemble.RandomForestClassifier` (scikit-learn)

**Hyperparameters**

| Hyperparameter | Value |
|---|---|
| `n_estimators` | 100 |
| `max_depth` | `None` (unrestricted) |
| `min_samples_split` | 2 |
| `min_samples_leaf` | 1 |
| `class_weight` | `balanced` |
| `random_state` | 42 |
| `n_jobs` | -1 |

## Intended use

The model is intended as an educational baseline within the DaSt 2026 FAIR data-science exercise: it demonstrates an end-to-end FAIR-compliant ML workflow (DBRepo-backed input, RO-Crate / CodeMeta / FAIR4ML / Croissant metadata, TUWRD deposits) rather than serving as a production tool. Within that scope it can be used to (a) reproduce the published evaluation results from the DBRepo view `ml_accident_features`, and (b) act as a reference baseline against which more careful modelling strategies — for example resampling, cost-sensitive loss, or gradient boosting — can be benchmarked. Any downstream user should treat the model as a teaching artefact and read the limitations section in full before drawing any substantive conclusion from its predictions.

## Out-of-scope uses

The model **must not** be used to make operational, policy, or insurance decisions about individuals, locations, or incidents. It must not be used to infer fault, predict outcomes for new accidents in real time, allocate emergency resources, prioritise enforcement, or set insurance premiums. It is also out of scope for any geographic area other than North Yorkshire and for any temporal period outside 2009–2013 — the distribution of road infrastructure, vehicle fleet, and reporting practice has shifted materially since then, and the model has no mechanism to account for that drift. Using the model on accident data from other countries or jurisdictions is similarly out of scope, because STATS19 coding and "severity" definitions differ from those used elsewhere.

## Training data

The model is trained on the *Road Safety Data – North Yorkshire Highways Authority (2009–2013)* dataset, originally published by the UK Department for Transport under the UK Open Government Licence v3.0, derived from STATS19 returns submitted by North Yorkshire Police. The data has been re-published in 3NF form on the TU Wien DBRepo test instance (database UUID `f36ef3e2-1aee-4526-b3ea-82f661a9261a`) and is loaded into the experiment exclusively through the DBRepo REST API view `ml_accident_features` (view UUID `45b21a9f-1b85-4035-8f1f-4fb699b70f5e`). The dataset contains 8,358 accidents in total, of which 6,686 are used for training and 1,672 for held-out evaluation, split with `sklearn.model_selection.train_test_split` using stratification on `severity_id` and a fixed random seed (42).

- **Source portal**: https://data.europa.eu/data/datasets/road-safety-data
- **Upstream**: https://data.gov.uk/dataset/cb7ae6f0-4be6-4935-9277-47e5ce24a11f/road-safety-data
- **Stable identifier (no DataCite DOI)**: DBRepo database UUID `f36ef3e2-1aee-4526-b3ea-82f661a9261a` at https://test.dbrepo.tuwien.ac.at/database/f36ef3e2-1aee-4526-b3ea-82f661a9261a. DataCite minting via `POST /api/v1/identifier` returned HTTP 500 on the test instance on 2026-05-07; the attempt is recorded in `README.md` under *Status of citable identifier* and in `src/notebooks/t2_1_dbrepo_schema.ipynb` (Section 8). The DBRepo UUID + URL is used as the stable identifier in lieu of a DOI.
- **Citation**:
  > UK Department for Transport. *Road Safety Data – North Yorkshire Highways Authority (2009–2013)*. Originally published on data.gov.uk, accessed via the European Data Portal. Re-published in 3NF schema by Group A (DaSt 2026, TU Wien), TU Wien DBRepo test instance, database UUID `f36ef3e2-1aee-4526-b3ea-82f661a9261a`, under the UK Open Government Licence v3.0.
- **Licence**: UK Open Government Licence v3.0 — https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/

## Evaluation results

Evaluation is on a stratified 20 % held-out test set (1,672 rows). All metrics are computed with `sklearn.metrics` on integer-encoded severity classes (1 = fatal, 2 = serious, 3 = slight). The headline accuracy is misleading without the per-class breakdown: weighted F1 of 0.673 reflects the model's ability to predict the dominant *slight* class, while macro F1 of 0.322 and the per-class scores below show that the model effectively never identifies fatal accidents and almost never identifies serious ones.

**Overall metrics**

| Metric | Value |
|---|---|
| Accuracy | 0.7512 |
| Precision (macro) | 0.3810 |
| Recall (macro) | 0.3453 |
| F1 (macro) | 0.3216 |
| Precision (weighted) | 0.6629 |
| Recall (weighted) | 0.7512 |
| F1 (weighted) | 0.6731 |
| ROC-AUC (OvR, weighted) | 0.6054 |

**Per-class metrics**

| Class | Label | Precision | Recall | F1 | Support |
|---|---|---|---|---|---|
| 1 | fatal | 0.000 | 0.000 | 0.000 | 39 |
| 2 | serious | 0.377 | 0.063 | 0.108 | 366 |
| 3 | slight | 0.766 | 0.973 | 0.857 | 1,267 |

**Confusion matrix** (rows = true class, columns = predicted class)

| | Pred 1 (fatal) | Pred 2 (serious) | Pred 3 (slight) |
|---|---|---|---|
| **True 1 (fatal)** | 0 | 5 | 34 |
| **True 2 (serious)** | 0 | 23 | 343 |
| **True 3 (slight)** | 1 | 33 | 1,233 |

The model classifies zero of the 39 fatal accidents in the test set correctly and only 23 of 366 serious accidents. Almost all error mass shifts toward the majority `slight` class. The rendered confusion-matrix figure is available at `outputs/figures/severity_rf_baseline_v1_confusion_matrix.png` and in the generated-data deposit (T3.10).

## Limitations

The dominant limitation is severe class imbalance combined with a model that — despite `class_weight='balanced'` — still collapses onto the majority class for any uncertain case. Per-class recall for fatal accidents is exactly 0; per-class recall for serious accidents is 6 %. The model therefore has no useful predictive value for exactly the cases that would matter most in any real road-safety application, and the headline accuracy of 0.75 is essentially the prior probability of `slight` in the test set.

A second limitation is feature scope: the model uses only the curated `ml_accident_features` view and ignores potentially informative vehicle-level and casualty-level joins available in the wider DBRepo schema. Temporal features (year, month, weekday) are not engineered, which prevents the model from picking up seasonal or trend effects, and no geographic features beyond `rural_urban` and the parent local-authority district are used. The model is also a single deterministic baseline with no hyperparameter search and no cross-validation — the reported metrics rest on one train/test split, so confidence intervals on the per-class metrics, especially for the fatal class with 39 test instances, are very wide.

Finally, the underlying STATS19 records have known limitations of their own: severity is recorded by attending officers and can be reclassified post-hoc, "slight" is known to be over-reported relative to hospital-admission data, and the dataset only contains accidents that were reported to police, which biases coverage toward more visible incidents.

## Ethical considerations

Because the model misses every fatal accident in the test set and almost every serious one, it must not be deployed in any context where a missed prediction could affect resource allocation, intervention, or emergency response. Doing so would systematically deprioritise the most harmful events — the exact inverse of what a road-safety system should do. The model's failure on the minority classes also illustrates a broader risk in safety analytics: aggregate accuracy can mask catastrophic per-class failure, and any user who reports only the weighted score is, in effect, hiding that failure.

The training data describes real injury and fatality events. Although the DBRepo re-publication does not contain personal identifiers, the original STATS19 data is geographic and temporal at a fine grain, so onward use should respect the original publisher's terms and avoid attempting re-identification of individuals or vehicles. The schema retains a `police_ref` field as a stable accident identifier; this is the existing public reference and is not a personal identifier, but downstream users should not attempt to join it with non-public datasets.

Finally, the model reflects North Yorkshire reporting practice between 2009 and 2013. Treating its predictions as representative of any other population, period, or jurisdiction would be inappropriate and could lead to misallocation of safety attention away from groups under-represented in those reports.

## Licence

The model artefact (`severity_rf_baseline_v1.joblib`) and its derived outputs are released under the **Creative Commons Attribution 4.0 International (CC BY 4.0)** licence — https://creativecommons.org/licenses/by/4.0/. The training data inherits the **UK Open Government Licence v3.0** from the source dataset; OGL v3.0 requires attribution but imposes no ShareAlike or copyleft conditions, so derived works (this model and its outputs) can be released under CC BY 4.0 without conflict. The training code in this repository is released under the **MIT License** (`LICENSE` file at the repository root); MIT is permissive and compatible with both OGL v3.0 (input data) and CC BY 4.0 (output data) — no licence imposes obligations on the others.

See `README.md → Licences` for the full compatibility argument and per-file mapping.

## References

This Model Card is referenced from:

- the FAIR4ML metadata for this model (T3.3, Owner C), and
- the RO-Crate root manifest at `ro-crate-metadata.json` (T3.1, Owner A).

Related identifiers:

- **DBRepo entry**: https://test.dbrepo.tuwien.ac.at/database/f36ef3e2-1aee-4526-b3ea-82f661a9261a
- **Source data portal**: https://data.europa.eu/data/datasets/road-safety-data
- **Software release (Zenodo)**: https://doi.org/10.5281/zenodo.20182653
- **GitHub repository**: https://github.com/Chrisvenator/DaSt-2026
