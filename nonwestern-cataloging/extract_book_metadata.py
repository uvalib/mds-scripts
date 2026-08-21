#!/usr/bin/env python3
"""
extract_book_metadata.py

Extract bibliographic metadata from photographs of a book's title page,
imprint/copyright page, table of contents, and other relevant pages, using
the Claude API (vision), and write the results to a CSV file.

The extraction and output logic mirrors the process established in
conversation:

  - Extracts (when present): title, subtitle, part/volume, author (including
    any descriptive epithet and the inverted/catalog form of the name),
    place of publication, publisher (including co-publishers/distributors),
    publication date, edition, ISBN or other identifying/deposit numbers,
    pagination, and subject headings.
  - If a field has conflicting values on different pages (e.g. a title page
    date vs. an imprint-page date), both are output as separate rows rather
    than silently picked between.
  - Text believed to be Arabic (or other non-Western script) is preserved
    verbatim in the "Original" column.
  - A transliteration column renders that text in the Latin alphabet using
    ALA-LC romanization conventions.
  - An "English Translation" column gives a real English translation only
    where translation is meaningful (e.g. titles, place names, publisher
    names). Personal/proper names are NOT translated; that cell instead
    reads "[personal name - not translated]". Purely numeric fields (ISBN,
    dates, deposit numbers, page counts) are repeated as-is.
  - The CSV is written with every cell double-quoted (csv.QUOTE_ALL) so
    that embedded commas, quotation marks, or slashes never break the
    table when opened in Excel/Sheets.

Usage:
    python3 extract_book_metadata.py IMAGE [IMAGE ...] [-o OUTPUT.csv]
                                      [--model MODEL] [--api-key KEY]
                                      [--append]

Requirements:
    pip install anthropic --break-system-packages

    An Anthropic API key must be available either via the AWS_BEARER_TOKEN_BEDROCK
    environment variable or the --api-key flag.

Examples:
    python3 extract_book_metadata.py title_page.jpg imprint_page.jpg
    python3 extract_book_metadata.py *.jpg -o my_book.csv
    python3 extract_book_metadata.py book2_p1.jpg book2_p2.jpg --append -o library.csv
"""

import argparse
import base64
import csv
import json
import mimetypes
import os
import sys

try:
    from anthropic import AnthropicBedrockMantle
except ImportError:
    sys.exit(
        "The 'anthropic' package is required. Install it with:\n"
        "    pip install -U \"anthropic[bedrock]\""
    )

DEFAULT_MODEL = "anthropic.claude-sonnet-5"

CSV_COLUMNS = ["Field", "Original (Arabic)", "Transliteration (ALA-LC)", "English Translation"]

PAGE_SYSTEM_PROMPT = """\
You are a bibliographic cataloging assistant. You will be shown photographs \
of pages from a single physical book: typically a title page, an imprint/\
copyright/CIP (cataloging-in-publication) page, and possibly a table of \
contents or other relevant pages. The text is likely to be in Arabic, but \
may include other non-Western (or Western) scripts and languages.

Your job is to extract bibliographic metadata and return it as a JSON array \
of row objects, following these exact rules:

FIELDS TO EXTRACT (only include a row for a field if it is actually present \
somewhere in the images -- never invent or guess a value):
  - Title
  - Part/Volume (e.g. "Part One"), if the book is part of a multi-part work
  - Subtitle
  - Author (the name itself, in its plain/direct form as printed, e.g. on \
the title page)
  - Author descriptor (any honorific/epithet printed with the author's name \
on the title page, e.g. "the Islamic thinker" -- only if present, kept as \
its own row, separate from the name)
  - Author (CIP catalog form, inverted) -- if the imprint/CIP page gives the \
author's name in inverted "Surname, Given name" catalog form, include this \
as its own separate row in addition to the plain form
  - Place of Publication
  - Publisher (primary)
  - Co-publisher / distributor -- if a second publisher, distributor, or \
printing house is listed (e.g. with separate contact info or a different \
city), include as its own row, labeled with the city if helpful
  - Publication Date -- if different pages show different dates (e.g. the \
title page says one year and the imprint/CIP page says another), output \
BOTH as separate rows, clearly labeled by source, e.g. "Publication Date \
(title page)" and "Publication Date (imprint/CIP page)". Do not pick one \
or reconcile them yourself.
  - Edition (e.g. "First Edition")
  - ISBN
  - Other identifying/deposit numbers (e.g. a national library deposit \
number), labeled with what it is and which country/institution issued it
  - Pagination (total page count as printed)
  - Subject headings / classification terms, if listed on a CIP page

Only include fields that actually appear in the images. Do not fabricate, \
guess, or fill in placeholder values for missing fields.

For EACH row, produce:
  - "field": a short English label for what the row is (see the field list \
above; you may add a parenthetical to disambiguate, as shown above)
  - "original": the text exactly as printed, in its original script \
(Arabic or other non-Western/Western script). Preserve original punctuation \
such as quotation marks. For purely numeric/Latin-script fields (ISBN, \
deposit numbers, page counts, dates already in Arabic numerals), just repeat \
the value as printed.
  - "transliteration": the ALA-LC romanization of the "original" text, \
using standard ALA-LC diacritics (e.g. macrons for long vowels, ʻayn as \
ʻ (U+02BB or similar), hamza as ʼ, ḥ/ṣ/ḍ/ṭ/ẓ/ū/ā/ī with proper diacritics). \
For numeric/Latin fields (ISBN, dates, deposit numbers, page counts), repeat \
the value unchanged.
  - "translation": a genuine English translation of the meaning, but ONLY \
where translation is meaningful and appropriate:
      * Titles, subtitles, part labels, author descriptors/epithets, place \
names (use the standard English exonym, e.g. "Amman"), publisher names \
(literal translation of their meaning), edition labels, and subject \
headings SHOULD be translated into natural English.
      * Personal names (author names, whether in plain or inverted catalog \
form) must NOT be translated. For those rows, set "translation" to exactly: \
"[personal name - not translated]"
      * Purely numeric or identifier fields (ISBN, deposit numbers, dates, \
page counts) have no real translation -- just repeat the value as printed \
in the "translation" field too.
  - If you are not confident in a reading (blurry, cut off, ambiguous), \
still provide your best-effort transcription/transliteration/translation, \
but keep it as close to literal as possible.

Respond with ONLY a raw JSON array of objects with exactly the keys \
"field", "original", "transliteration", "translation" -- no markdown code \
fences, no commentary, no preamble, no explanation. If a photograph does \
not appear to show a book page with bibliographic information at all, \
still do your best to extract whatever is legible.
"""

PAGE_USER_PROMPT = (
    "Here are photographs of pages from a book (title page, imprint/CIP "
    "page, and/or other relevant pages). Extract the bibliographic metadata "
    "according to the rules you were given, and return only the JSON array."
)


def encode_image(path):
    """Read an image file and return (media_type, base64_data)."""
    media_type, _ = mimetypes.guess_type(path)
    if media_type not in ("image/jpeg", "image/png", "image/gif", "image/webp"):
        # Fall back to jpeg if we can't detect a supported type; Claude will
        # reject truly unsupported formats.
        media_type = media_type or "image/jpeg"
    with open(path, "rb") as f:
        data = base64.standard_b64encode(f.read()).decode("utf-8")
    return media_type, data


def build_message_content(image_paths):
    content = []
    for path in image_paths:
        if not os.path.isfile(path):
            sys.exit(f"Error: image file not found: {path}")
        media_type, data = encode_image(path)
        content.append(
            {
                "type": "image",
                "source": {
                    "type": "base64",
                    "media_type": media_type,
                    "data": data,
                },
            }
        )
    content.append({"type": "text", "text": PAGE_USER_PROMPT})
    return content


def call_claude(image_paths, model, api_key):
    #client = anthropic.Anthropic(api_key=api_key) if api_key else anthropic.Anthropic()

    client = AnthropicBedrockMantle(aws_region="us-east-1")

    response = client.messages.create(
        model=model,
        max_tokens=4000,
        system=PAGE_SYSTEM_PROMPT,
        messages=[{"role": "user", "content": build_message_content(image_paths)}],
    )

    text_parts = [block.text for block in response.content if getattr(block, "type", None) == "text"]
    return "".join(text_parts).strip()


def parse_rows(raw_text):
    """Parse the model's JSON response into a list of row dicts, tolerating
    stray markdown code fences if the model adds them despite instructions."""
    cleaned = raw_text.strip()
    if cleaned.startswith("```"):
        cleaned = cleaned.split("```")[1]
        if cleaned.startswith("json"):
            cleaned = cleaned[4:]
        cleaned = cleaned.strip()

    try:
        rows = json.loads(cleaned)
    except json.JSONDecodeError as e:
        sys.exit(
            "Error: could not parse JSON from Claude's response.\n"
            f"Parse error: {e}\n\n"
            "Raw response was:\n" + raw_text
        )

    if not isinstance(rows, list):
        sys.exit("Error: expected a JSON array of row objects from Claude.")

    normalized = []
    for row in rows:
        normalized.append(
            [
                row.get("field", ""),
                row.get("original", ""),
                row.get("transliteration", ""),
                row.get("translation", ""),
            ]
        )
    return normalized


def write_csv(rows, output_path, append=False):
    file_exists = os.path.isfile(output_path)
    mode = "a" if append and file_exists else "w"
    write_header = not (append and file_exists)

    with open(output_path, mode, newline="", encoding="utf-8-sig") as f:
        writer = csv.writer(f, quoting=csv.QUOTE_ALL)
        if write_header:
            writer.writerow(CSV_COLUMNS)
        writer.writerows(rows)


def main():
    parser = argparse.ArgumentParser(
        description="Extract bibliographic metadata from book page photographs via the Claude API."
    )
    parser.add_argument(
        "images",
        nargs="+",
        help="One or more image files (title page, imprint page, table of contents, etc.)",
    )
    parser.add_argument(
        "-o", "--output",
        default="book_metadata.csv",
        help="Output CSV file path (default: book_metadata.csv)",
    )
    parser.add_argument(
        "--model",
        default=DEFAULT_MODEL,
        help=f"Claude model to use (default: {DEFAULT_MODEL})",
    )
    parser.add_argument(
        "--api-key",
        default=None,
        help="Anthropic API key (defaults to the ANTHROPIC_API_KEY environment variable)",
    )
    parser.add_argument(
        "--append",
        action="store_true",
        help="Append rows to an existing CSV instead of overwriting it (e.g. to add another book)",
    )

    args = parser.parse_args()

    api_key = args.api_key or os.environ.get("AWS_BEARER_TOKEN_BEDROCK")
    if not api_key:
        sys.exit(
            "Error: no API key found. Set the AWS_BEARER_TOKEN_BEDROCK environment "
            "variable or pass --api-key."
        )

    print(f"Sending {len(args.images)} image(s) to {args.model}...", file=sys.stderr)
    raw_response = call_claude(args.images, args.model, api_key)
    rows = parse_rows(raw_response)

    if not rows:
        sys.exit("Error: no metadata rows were extracted from the images.")

    write_csv(rows, args.output, append=args.append)
    print(f"Wrote {len(rows)} row(s) to {args.output}", file=sys.stderr)


if __name__ == "__main__":
    main()
