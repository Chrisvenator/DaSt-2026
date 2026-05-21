"""Train the final accident-severity classifier.

Experiment:
    Predict accident severity from the DBRepo `ml_accident_features` view.

Input:
    DBRepo REST API view `ml_accident_features`.

Target:
    severity_id
        1 = fatal
        2 = serious
        3 = slight

Outputs:
    - trained model artefact
    - metrics JSON
    - test-set predictions CSV
    - confusion matrix figure
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

import joblib
import matplotlib.pyplot as plt
import pandas as pd
import yaml
from sklearn.compose import ColumnTransformer
from sklearn.ensemble import RandomForestClassifier
from sklearn.impute import SimpleImputer
from sklearn.metrics import (
    ConfusionMatrixDisplay,
    accuracy_score,
    classification_report,
    confusion_matrix,
    roc_auc_score,
)
from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder

try:
    from .dbrepo_loader import load_accident_features
except ImportError:
    from dbrepo_loader import load_accident_features


def load_yaml(path: str | Path) -> dict[str, Any]:
    with open(path, "r", encoding="utf-8") as file:
        return yaml.safe_load(file)


def validate_columns(df: pd.DataFrame, required_columns: list[str]) -> None:
    missing = sorted(set(required_columns) - set(df.columns))
    if missing:
        raise ValueError(f"Missing required columns in DBRepo view: {missing}")


def build_pipeline(data_cfg: dict[str, Any], model_cfg: dict[str, Any]) -> Pipeline:
    categorical_columns = data_cfg["features"]["categorical_columns"]
    numeric_columns = data_cfg["features"]["numeric_columns"]

    categorical_pipeline = Pipeline(
        steps=[
            ("imputer", SimpleImputer(strategy="most_frequent")),
            ("encoder", OneHotEncoder(handle_unknown="ignore")),
        ]
    )

    numeric_pipeline = Pipeline(
        steps=[
            ("imputer", SimpleImputer(strategy="median")),
        ]
    )

    preprocessor = ColumnTransformer(
        transformers=[
            ("categorical", categorical_pipeline, categorical_columns),
            ("numeric", numeric_pipeline, numeric_columns),
        ]
    )

    hp = model_cfg["hyperparameters"]

    classifier = RandomForestClassifier(
        n_estimators=int(hp["n_estimators"]),
        max_depth=hp["max_depth"],
        min_samples_split=int(hp["min_samples_split"]),
        min_samples_leaf=int(hp["min_samples_leaf"]),
        class_weight=hp["class_weight"],
        random_state=int(hp["random_state"]),
        n_jobs=-1,
    )

    return Pipeline(
        steps=[
            ("preprocessor", preprocessor),
            ("classifier", classifier),
        ]
    )


def compute_metrics(
    *,
    y_test: pd.Series,
    y_pred: pd.Series,
    y_proba,
    labels: list[int],
    model_cfg: dict[str, Any],
    data_cfg: dict[str, Any],
    n_rows_total: int,
    n_train: int,
    n_test: int,
) -> dict[str, Any]:
    report = classification_report(
        y_test,
        y_pred,
        labels=labels,
        output_dict=True,
        zero_division=0,
    )

    cm = confusion_matrix(y_test, y_pred, labels=labels)

    metrics: dict[str, Any] = {
        "experiment_id": model_cfg["experiment"]["id"],
        "dataset_name": data_cfg["dataset"]["name"],
        "data_source": "DBRepo REST API",
        "database_id": data_cfg["dataset"]["database_id"],
        "view_name": data_cfg["dataset"]["view_name"],
        "view_id": data_cfg["dataset"]["view_id"],
        "target_column": data_cfg["task"]["target_column"],
        "target_labels": data_cfg["task"]["target_labels"],
        "n_rows_total": n_rows_total,
        "n_train": n_train,
        "n_test": n_test,
        "model_type": model_cfg["model"]["type"],
        "hyperparameters": model_cfg["hyperparameters"],
        "accuracy": float(accuracy_score(y_test, y_pred)),
        "precision_macro": float(report["macro avg"]["precision"]),
        "recall_macro": float(report["macro avg"]["recall"]),
        "f1_macro": float(report["macro avg"]["f1-score"]),
        "precision_weighted": float(report["weighted avg"]["precision"]),
        "recall_weighted": float(report["weighted avg"]["recall"]),
        "f1_weighted": float(report["weighted avg"]["f1-score"]),
        "classification_report": report,
        "confusion_matrix": cm.tolist(),
        "confusion_matrix_labels": labels,
    }

    try:
        metrics["roc_auc_ovr_weighted"] = float(
            roc_auc_score(
                y_test,
                y_proba,
                labels=labels,
                multi_class="ovr",
                average="weighted",
            )
        )
    except ValueError as exc:
        metrics["roc_auc_ovr_weighted"] = None
        metrics["roc_auc_note"] = f"ROC-AUC could not be computed: {exc}"

    return metrics


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--data-config", default="configs/data.yaml")
    parser.add_argument("--model-config", default="configs/model.yaml")
    parser.add_argument("--eval-config", default="configs/eval.yaml")
    args = parser.parse_args()

    data_cfg = load_yaml(args.data_config)
    model_cfg = load_yaml(args.model_config)
    eval_cfg = load_yaml(args.eval_config)

    categorical_columns = data_cfg["features"]["categorical_columns"]
    numeric_columns = data_cfg["features"]["numeric_columns"]
    feature_columns = categorical_columns + numeric_columns
    target_column = data_cfg["task"]["target_column"]

    print("Loading data from DBRepo REST API...")
    df = load_accident_features(data_cfg)
    print(f"Loaded {len(df)} rows and {len(df.columns)} columns.")

    expected_rows = data_cfg["dataset"].get("expected_rows")
    if expected_rows is not None and len(df) != int(expected_rows):
        raise ValueError(f"Expected {expected_rows} rows, but DBRepo returned {len(df)} rows.")

    validate_columns(df, feature_columns + [target_column])

    X = df[feature_columns].copy()
    y = df[target_column].astype(int)

    split_cfg = data_cfg["split"]
    stratify = y if split_cfg.get("stratify", True) else None

    X_train, X_test, y_train, y_test = train_test_split(
        X,
        y,
        test_size=float(split_cfg["test_size"]),
        random_state=int(split_cfg["random_seed"]),
        stratify=stratify,
    )

    pipeline = build_pipeline(data_cfg, model_cfg)

    print("Training model...")
    pipeline.fit(X_train, y_train)

    print("Evaluating model...")
    y_pred = pipeline.predict(X_test)
    y_proba = pipeline.predict_proba(X_test)

    labels = sorted(y.unique().tolist())

    metrics = compute_metrics(
        y_test=y_test,
        y_pred=y_pred,
        y_proba=y_proba,
        labels=labels,
        model_cfg=model_cfg,
        data_cfg=data_cfg,
        n_rows_total=len(df),
        n_train=len(X_train),
        n_test=len(X_test),
    )

    model_path = Path(model_cfg["model"]["artifact_path"])
    metrics_path = Path(eval_cfg["outputs"]["metrics_path"])
    predictions_path = Path(eval_cfg["outputs"]["predictions_path"])
    confusion_matrix_path = Path(eval_cfg["outputs"]["confusion_matrix_path"])

    for path in (model_path, metrics_path, predictions_path, confusion_matrix_path):
        path.parent.mkdir(parents=True, exist_ok=True)

    print("Saving outputs...")
    joblib.dump(pipeline, model_path)

    with open(metrics_path, "w", encoding="utf-8") as file:
        json.dump(metrics, file, indent=2)

    predictions = pd.DataFrame(
        {
            "true_severity_id": y_test.to_numpy(),
            "predicted_severity_id": y_pred,
        },
        index=y_test.index,
    )

    if "police_ref" in df.columns:
        predictions.insert(0, "police_ref", df.loc[y_test.index, "police_ref"].to_numpy())

    for class_index, class_label in enumerate(pipeline.named_steps["classifier"].classes_):
        predictions[f"probability_severity_{class_label}"] = y_proba[:, class_index]

    predictions.to_csv(predictions_path, index=False)

    cm = confusion_matrix(y_test, y_pred, labels=labels)
    display = ConfusionMatrixDisplay(confusion_matrix=cm, display_labels=labels)
    display.plot()
    plt.title("Accident severity classification confusion matrix")
    plt.tight_layout()
    plt.savefig(confusion_matrix_path, dpi=300)
    plt.close()

    print("Experiment completed successfully.")
    print(f"Model: {model_path}")
    print(f"Metrics: {metrics_path}")
    print(f"Predictions: {predictions_path}")
    print(f"Confusion matrix: {confusion_matrix_path}")
    print(f"Weighted F1: {metrics['f1_weighted']:.4f}")
    print(f"Macro F1: {metrics['f1_macro']:.4f}")


if __name__ == "__main__":
    main()
