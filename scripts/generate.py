"""Build data/employer-costs.json from an EOR Scope dataset export.

Source: https://github.com/eorscope/employer-costs (CC BY 4.0), the export
published at https://eorscope.com/data/. Values are copied, never computed:
every number is the CSV string parsed as a float, every flag the CSV boolean.

Usage: python scripts/generate.py <dataset export dir>
"""
import csv
import hashlib
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
FILES = ("country_summary.csv", "country_contributions.csv", "country_assumptions.csv")
# Assumptions read by the cost engine (same ones as the eorscope CLI and Go module).
ENGINE_ASSUMPTIONS = ("basic_share_of_gross", "employee_is_citizen_or_pr")


def rows(path):
    with open(path, encoding="utf-8-sig", newline="") as f:
        return list(csv.DictReader(f))


def num(v):
    return None if v == "" else float(v)


def flag(v):
    if v not in ("true", "false"):
        raise ValueError(f"not a boolean: {v!r}")
    return v == "true"


def main(src):
    src = Path(src)
    summary = rows(src / FILES[0])
    contributions = rows(src / FILES[1])
    assumptions = rows(src / FILES[2])

    countries = {}
    for r in sorted(summary, key=lambda r: r["iso"]):
        countries[r["iso"]] = {
            "iso": r["iso"],
            "country": r["country"],
            "region": r["region"],
            "currency": r["currency"],
            "example_salary_usd": num(r["example_salary_usd"]),
            "employer_cost_pct": num(r["employer_cost_pct"]),
            "employer_cost_pct_printed": r["employer_cost_pct_printed"],
            "employer_cost_usd_month": num(r["employer_cost_usd_month"]),
            "total_declared_floor": flag(r["total_declared_floor"]),
            "total_declared_ceiling": flag(r["total_declared_ceiling"]),
            "fx_local_per_usd": num(r["fx_local_per_usd"]),
            "fx_date": r["fx_date"],
            "last_reviewed": r["last_reviewed"],
            # salary-dependent bound (export of 2026-11-14 on): at_least_above | at_most_below, empty when none
            "total_bound_salary_threshold_local": num(r["total_bound_salary_threshold_local"]),
            "total_bound_salary_rule": r["total_bound_salary_rule"] or None,
            "assumptions": {},
            "lines": [],
        }
    for r in assumptions:
        if r["id"] in ENGINE_ASSUMPTIONS:
            countries[r["iso"]]["assumptions"][r["id"]] = num(r["value"])
    for r in contributions:
        countries[r["iso"]]["lines"].append({
            "type": r["line_type"],
            "id": r["line_id"],
            "name": r["line_name"],
            "rate": num(r["rate"]),
            "base": r["base"],
            "base_factor": num(r["base_factor"]),
            "floor": num(r["base_floor_annual_local"]),
            "cap": num(r["base_cap_annual_local"]),
            "flat": num(r["flat_annual_local"]),
            "min_gross": num(r["min_gross_annual_local"]),
            "max_gross": num(r["max_gross_annual_local"]),
            "extra_kind": r["extra_kind"],
            "extra_value": num(r["extra_value"]),
            "in_total": flag(r["in_total"]),
            "applies": r["applies"],
            "source_name": r["source_name"],
            "source_url": r["source_url"],
            "source_checked_at": r["source_checked_at"],
        })

    out = {
        "source": "EOR Scope employer-cost dataset, https://eorscope.com/data/",
        "licence": "CC BY 4.0, https://creativecommons.org/licenses/by/4.0/",
        "attribution": "EOR Scope, published by Trésor Kaya EI (Les Créavores), France, https://eorscope.com/methodology/",
        "sha256": {f: hashlib.sha256((src / f).read_bytes()).hexdigest() for f in FILES},
        "countries": countries,
    }
    data = ROOT / "data"
    data.mkdir(exist_ok=True)
    with open(data / "employer-costs.json", "w", encoding="utf-8", newline="\n") as f:
        json.dump(out, f, ensure_ascii=False, separators=(",", ":"))
        f.write("\n")
    # LF line endings whatever the checkout (core.autocrlf on Windows)
    licence = (src / "LICENSE").read_bytes().replace(b"\r\n", b"\n")
    (data / "LICENSE").write_bytes(licence)
    print(f"{len(countries)} countries, {len(contributions)} lines -> data/employer-costs.json")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    main(sys.argv[1])
