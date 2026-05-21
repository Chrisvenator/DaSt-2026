"""Reusable DBRepo REST API loader for the road-safety experiment.

This module intentionally reads credentials from environment variables.
Do not hardcode DBRepo passwords in notebooks or scripts.
"""

from __future__ import annotations

import os
from typing import Any

import pandas as pd
import requests
from requests.auth import HTTPBasicAuth


def _get_auth() -> HTTPBasicAuth | None:
    """Return HTTP Basic Auth if DBRepo credentials are available."""
    username = os.getenv("DBREPO_USERNAME")
    password = os.getenv("DBREPO_PASSWORD")

    if username and password:
        return HTTPBasicAuth(username, password)

    return None


def _extract_rows(payload: Any) -> list[dict[str, Any]]:
    """Extract rows from common DBRepo/API JSON response shapes."""
    if isinstance(payload, list):
        return payload

    if isinstance(payload, dict):
        for key in ("content", "data", "items", "results", "records", "rows"):
            if key in payload:
                value = payload[key]
                if isinstance(value, list):
                    return value
                return _extract_rows(value)

    raise RuntimeError(
        "Unexpected DBRepo response format. "
        f"Type={type(payload).__name__}, keys={list(payload.keys()) if isinstance(payload, dict) else 'n/a'}"
    )


def fetch_view_df(
    *,
    base_url: str,
    database_id: str,
    view_id: str,
    page_size: int = 1000,
    timeout: int = 60,
) -> pd.DataFrame:
    """Fetch all rows of a DBRepo view into a pandas DataFrame.

    Parameters
    ----------
    base_url:
        DBRepo base URL, for example https://test.dbrepo.tuwien.ac.at
    database_id:
        DBRepo database UUID.
    view_id:
        DBRepo view UUID.
    page_size:
        Number of rows per page.
    timeout:
        HTTP request timeout in seconds.

    Returns
    -------
    pandas.DataFrame
        All rows returned by the DBRepo view endpoint.

    Raises
    ------
    RuntimeError
        If the API cannot be reached or returns an unexpected response.
    """
    endpoint = base_url.rstrip("/")
    url = f"{endpoint}/api/v1/database/{database_id}/view/{view_id}/data"

    auth = _get_auth()
    headers = {"Accept": "application/json"}

    pages: list[pd.DataFrame] = []
    page = 0

    while True:
        try:
            response = requests.get(
                url,
                params={"page": page, "size": page_size},
                auth=auth,
                headers=headers,
                timeout=timeout,
            )
        except requests.exceptions.ConnectionError as exc:
            raise RuntimeError(f"Connection error fetching DBRepo view page {page}: {exc}") from exc
        except requests.exceptions.Timeout as exc:
            raise RuntimeError(f"Timeout fetching DBRepo view page {page}") from exc

        if response.status_code != 200:
            raise RuntimeError(
                f"HTTP {response.status_code} fetching DBRepo view page {page}: "
                f"{response.text[:500]}"
            )

        rows = _extract_rows(response.json())

        if not rows:
            break

        pages.append(pd.DataFrame(rows))

        if len(rows) < page_size:
            break

        page += 1

    if not pages:
        return pd.DataFrame()

    return pd.concat(pages, ignore_index=True)


def load_accident_features(data_config: dict[str, Any]) -> pd.DataFrame:
    """Load the configured ml_accident_features DBRepo view."""
    dataset = data_config["dataset"]

    return fetch_view_df(
        base_url=dataset["dbrepo_base_url"],
        database_id=dataset["database_id"],
        view_id=dataset["view_id"],
        page_size=int(dataset.get("page_size", 1000)),
    )
