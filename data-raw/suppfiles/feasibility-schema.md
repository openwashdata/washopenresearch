# feasibility.csv

One row per candidate dataset of the supplement republishing test (#58). The gates are the ones defined in #58: Stage A (A1 licence, A2 article type, A3 existing deposit) and Stage B (B1 licence on the article page, B2 own data, B3 primary data, B4 personal data, B5 extraction, B6 documentation, B7 fidelity).

| Column | Meaning |
|---|---|
| `doi` | Article DOI |
| `file_name` | Supplement file as in `manifest.csv` |
| `a1_licence` to `b7_fidelity` | One gate per column: `pass`, `fail`, `partial`, `likely pass`, `likely fail`, `to check` or `not checked`, followed by a colon and the evidence in a few words |
| `outcome` | `go`, `go with conditions`, `no go` or `not run (preview YYYY-MM-DD)` |
| `failed_gate` | The first failed gate, empty otherwise |
| `notes` | Package name, discrepancies, conditions |
| `checked_on` | Date of the check, ISO 8601 |
| `checked_by` | `agent`, `Lars` or both |

A `likely` value comes from a table preview (captions and headers) without the article; a `pass` or `fail` from the full Stage B. Failed candidates stay in the file with their gate (decision 2 of the plan of 2026-10-01).
