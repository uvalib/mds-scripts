#!/usr/bin/env python3
"""
marc_to_csv.py

Extract bibliographic metadata from a MARC (.mrc) file and write it to a CSV file.

Fields extracted per record:
    - Author              (MARC 100/110/111 - main entry)
    - Title               (MARC 245 $a + $b)
    - Date of Publication (MARC 264 $c, falling back to 260 $c)
    - Abstract            (MARC 520 $a, summary/abstract note)
    - Control Number      (MARC 001)
    - LCCN                (MARC 010 $a)
    - ISBN                (MARC 020 $a)

Requires: pymarc  (pip install pymarc --break-system-packages)

Usage:
    python3 marc_to_csv.py input.mrc output.csv
"""

import csv
import sys

from pymarc import MARCReader


def get_subfield(field, code):
    """Return the first value of a subfield code, or '' if missing."""
    if field is None:
        return ""
    value = field.get(code) if hasattr(field, "get") else None
    if value:
        return value.strip()
    # Fallback for older pymarc field APIs
    try:
        values = field.get_subfields(code)
        return values[0].strip() if values else ""
    except AttributeError:
        return ""


def get_author(record):
    """Try personal name (100), then corporate (110), then meeting (111) main entries."""
    for tag in ("100", "110", "111"):
        field = record.get_fields(tag)
        if field:
            f = field[0]
            name = get_subfield(f, "a")
            if name:
                return name
    return ""


def get_title(record):
    field = record.get_fields("245")
    if not field:
        return ""
    f = field[0]
    # Strip trailing ISBD punctuation (e.g. "Title /" -> "Title") from each
    # subfield before joining, since $a normally ends with " /" or ":" before $b.
    title = get_subfield(f, "a").rstrip(" /:;,")
    subtitle = get_subfield(f, "b").rstrip(" /:;,")
    full_title = f"{title} {subtitle}".strip()
    return full_title


def get_pub_date(record):
    # Prefer newer 264 field (with 2nd indicator '1' = publication), fall back to legacy 260
    for tag in ("264", "260"):
        for f in record.get_fields(tag):
            date = get_subfield(f, "c")
            if date:
                return date.rstrip(" .")
    return ""


def get_abstract(record):
    abstracts = []
    for f in record.get_fields("520"):
        text = get_subfield(f, "a")
        if text:
            abstracts.append(text)
    return " | ".join(abstracts)


def get_control_number(record):
    field = record.get_fields("001")
    return field[0].data.strip() if field and field[0].data else ""


def get_lccn(record):
    field = record.get_fields("010")
    return get_subfield(field[0], "a") if field else ""


def get_isbn(record):
    isbns = []
    for f in record.get_fields("020"):
        val = get_subfield(f, "a")
        if val:
            isbns.append(val)
    return " | ".join(isbns)


def extract_records(marc_path):
    """Yield a dict of extracted metadata for each record in the MARC file."""
    with open(marc_path, "rb") as fh:
        reader = MARCReader(fh, to_unicode=True, force_utf8=True)
        for i, record in enumerate(reader, start=1):
            if record is None:
                print(f"Warning: could not parse record #{i} (skipped)", file=sys.stderr)
                continue
            yield {
                "Author": get_author(record),
                "Title": get_title(record),
                "Date of Publication": get_pub_date(record),
                "Abstract": get_abstract(record),
                "Control Number (001)": get_control_number(record),
                "LCCN (010)": get_lccn(record),
                "ISBN (020)": get_isbn(record),
            }


def main():
    if len(sys.argv) != 3:
        print("Usage: python3 marc_to_csv.py <input.mrc> <output.csv>", file=sys.stderr)
        sys.exit(1)

    marc_path, csv_path = sys.argv[1], sys.argv[2]
    fieldnames = [
        "Author",
        "Title",
        "Date of Publication",
        "Abstract",
        "Control Number (001)",
        "LCCN (010)",
        "ISBN (020)",
    ]

    count = 0
    with open(csv_path, "w", newline="", encoding="utf-8") as out_fh:
        writer = csv.DictWriter(out_fh, fieldnames=fieldnames)
        writer.writeheader()
        for row in extract_records(marc_path):
            writer.writerow(row)
            count += 1

    print(f"Done. Wrote {count} record(s) to {csv_path}")


if __name__ == "__main__":
    main()