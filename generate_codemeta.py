"""
T3.2 – Generate codemeta.json programmatically from requirements.txt
Run from repo root: python generate_codemeta.py
"""
import json
from datetime import date

# ── 1. Read ALL pinned dependencies from requirements.txt ─────────────
with open("requirements.txt", encoding="utf-8") as f:
    dependencies = [
        line.strip()
        for line in f
        if line.strip() and not line.startswith("#")
    ]

print(f"Found {len(dependencies)} dependencies in requirements.txt")

# ── 2. Define codemeta ────────────────────────────────────────────────
codemeta = {
    "@context": "https://w3id.org/codemeta/3.0",
    "@type": "SoftwareSourceCode",

    "name": "STATS19 Road Traffic Accident Severity Prediction - North Yorkshire 2009-2013",
    "version": "0.3.0",
    "description": "A FAIR-compliant machine learning experiment predicting road traffic accident severity (1=fatal, 2=serious, 3=slight) using the STATS19 North Yorkshire dataset (2009-2013, 8358 records). Data is loaded exclusively from DBRepo via REST API. A Random Forest classifier is trained and evaluated, producing predictions, metrics, and confusion matrix figures. Metadata follows RO-Crate, CodeMeta, FAIR4ML, and Croissant standards.",

    "license": "https://spdx.org/licenses/MIT.html",

    "codeRepository": "https://github.com/Chrisvenator/DaSt-2026",
    "readme":         "https://github.com/Chrisvenator/DaSt-2026#readme",
    "issueTracker":   "https://github.com/Chrisvenator/DaSt-2026/issues",

    "identifier":  "https://doi.org/10.5281/zenodo.20182653",
    "relatedLink": "https://doi.org/10.5281/zenodo.20182653",

    "dateCreated":  "2026-04-01",
    "dateModified": str(date.today()),

    "programmingLanguage": {
        "@type": "ComputerLanguage",
        "name": "Python",
        "version": "3.13"
    },
    "runtimePlatform": "Python 3.13",
    "operatingSystem": "cross-platform",

    "author": [
        {
            "@type":      "Person",
            "givenName":  "Muhamad",
            "familyName": "Moghrabi",
            "@id": "https://orcid.org/0009-0006-3778-025X"
        },
        {
            "@type":      "Person",
            "givenName":  "Mehedy",
            "familyName": "Hasan",
            "@id": "https://orcid.org/0009-0002-4800-8178"
        },
        {
            "@type":      "Person",
            "givenName":  "Sravanthi",
            "familyName": "Muthineni",
            "@id": "https://orcid.org/0009-0009-8778-4701"
        },
        {
            "@type":      "Person",
            "givenName":  "Christopher",
            "familyName": "Scherling",
            "@id": "https://orcid.org/0009-0007-4090-3107"
        }
    ],

    "softwareRequirements": dependencies,
}

# ── 3. Write codemeta.json ────────────────────────────────────────────
with open("codemeta.json", "w", encoding="utf-8") as f:
    json.dump(codemeta, f, indent=2)

print("codemeta.json written successfully!")
print(f"  Authors:      {len(codemeta['author'])}")
print(f"  Dependencies: {len(dependencies)}")
print("")