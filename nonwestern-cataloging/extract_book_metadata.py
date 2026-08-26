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
  - Convert the JSON metadata produced by Claude into a bilingual MARC21 bibliographic record.

The record follows standard MARC 21 practice for non-Latin-script materials:
  - Romanized (ALA-LC transliteration) data goes in the main descriptive
    fields (1XX, 245, 250, 264, 300, 650, etc.), since MARC's main fields
    are conventionally Latin-script.
  - The original script (e.g. Arabic) is carried in linked 880 "Alternate
    Graphic Representation" fields, tied back to their romanized
    counterpart with reciprocal $6 linking subfields (e.g. 245 $6 880-01
    <-> 880 $6 245-01), which is the standard MARC mechanism for bilingual/
    non-Latin cataloging.
  - English translations (of titles, publisher names, subjects, etc.) are
    NOT given their own MARC field by default, since MARC has no dedicated
    "translation of title" field for this use case; they are instead
    captured in 500 general notes so the information isn't lost. Personal
    names are never translated (per the extraction rules) and are excluded
    from translation notes.

Input:
    A JSON file containing a list of row objects, each with the keys:
        "field"           -- English label, e.g. "Title", "Author",
                              "Place of Publication", "ISBN", etc.
        "original"        -- text in its original (e.g. Arabic) script
        "transliteration" -- ALA-LC romanization of "original"
        "translation"     -- English translation, or
                              "[personal name - not translated]", or a
                              repeated value for purely numeric fields

    This is the same row structure the extraction script
    (extract_book_metadata.py) parses from Claude's API response before
    writing it out as CSV. If you want that script to also save this raw
    JSON so it can be piped into this converter, add a print/json.dump of
    `rows` there, or ask for that feature to be added.

Output:
    A MARC21 binary record (.mrc) and, a human-readable MARC
    "tag view" (.mrk) text dump for review.

Usage:
    python3 extract_book_metadata.py IMAGE [IMAGE ...] [-o OUTPUT]
                                      [--model MODEL] [--api-key KEY]

Requirements:
    pip install anthropic --break-system-packages
    
    pip install pymarc

    An Anthropic API key must be available either via the AWS_BEARER_TOKEN_BEDROCK
    environment variable or the --api-key flag.

Examples:
    python3 extract_book_metadata.py title_page.jpg imprint_page.jpg
    python3 extract_book_metadata.py *.jpg -o filename
"""

import argparse, base64, json, mimetypes, os, sys, re
from datetime import datetime, timezone

try:
    from pymarc import Record, Field, Subfield
except ImportError:
    sys.exit("The 'pymarc' package is required. Install it with:\n    pip install pymarc --break-system-packages")

try:
    from anthropic import AnthropicBedrockMantle
except ImportError:
    sys.exit(
        "The 'anthropic' package is required. Install it with:\n"
        "    pip install -U \"anthropic[bedrock]\""
    )

DEFAULT_MODEL = "anthropic.claude-sonnet-5"

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

# --------------------------------------------------------------------------
# Reference data
# --------------------------------------------------------------------------

# A short lookup of MARC country codes for places commonly seen in Arabic
# imprints. Not exhaustive -- falls back to 'xx ' (no place, unknown) if the
# place isn't recognized. Extend as needed.
MARC_COUNTRY_CODES = {
    "amman": "jo ", "jordan": "jo ",
    "cairo": "ua ", "egypt": "ua ",
    "beirut": "le ", "lebanon": "le ",
    "damascus": "sy ", "syria": "sy ",
    "baghdad": "iq ", "iraq": "iq ",
    "riyadh": "su ", "jeddah": "su ", "saudi arabia": "su ",
    "doha": "qa ", "qatar": "qa ",
    "kuwait": "ku ",
    "abu dhabi": "ts ", "dubai": "ts ", "united arab emirates": "ts ",
    "rabat": "mr ", "casablanca": "mr ", "morocco": "mr ",
    "tunis": "ti ", "tunisia": "ti ",
    "algiers": "ae ", "algeria": "ae ",
    "khartoum": "sj ", "sudan": "sj ",
    "ramallah": "wj ", "gaza": "gz ", "jerusalem": "js ", "palestine": "wj ",
    "tripoli": "ly ", "libya": "ly ",
    "sanaa": "ye ", "yemen": "ye ",
    "muscat": "mu ", "oman": "mu ",
    "manama": "ba ", "bahrain": "ba ",
}

LANGUAGE_NAMES = {
    "ara": "Arabic", "per": "Persian", "fas": "Persian", "urd": "Urdu",
    "tur": "Turkish", "heb": "Hebrew", "eng": "English",
}

# --------------------------------------------------------------------------
# Claude query construction
# --------------------------------------------------------------------------

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


def clean_text(raw_text):
    """Parse the model's JSON response into a list of row dicts, tolerating
    stray markdown code fences if the model adds them despite instructions."""
    cleaned = raw_text.strip()
    if cleaned.startswith("```"):
        cleaned = cleaned.split("```")[1]
        if cleaned.startswith("json"):
            cleaned = cleaned[4:]
        cleaned = cleaned.strip()
        
    return cleaned

def parse_rows(cleaned):
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

    return rows

# --------------------------------------------------------------------------
# Converting JSON to MARC
# --------------------------------------------------------------------------

def load_rows(path):
    with open(path, "r", encoding="utf-8-sig") as f:
        data = json.load(f)
    if not isinstance(data, list):
        sys.exit("Error: expected the input JSON to be a list of row objects.")
    return data


def norm(s):
    return (s or "").strip()


def field_matches(row, *keywords_any, exclude=()):
    """True if the row's 'field' label contains any of keywords_any
    (case-insensitive) and none of the exclude keywords."""
    label = norm(row.get("field")).lower()
    if any(x.lower() in label for x in exclude):
        return False
    return any(k.lower() in label for k in keywords_any)


def is_untranslated_name(translation):
    return norm(translation).lower().startswith("[personal name")


def guess_country_code(place_text):
    place_text = (place_text or "").lower()
    for key, code in MARC_COUNTRY_CODES.items():
        if key in place_text:
            return code
    return "xx "


def split_multi(text):
    """Split a field that packs multiple values with '//' or ';' (as used
    for subject heading strings), trimming whitespace, dropping empties."""
    if not text:
        return []
    parts = re.split(r"//|;", text)
    return [p.strip() for p in parts if p.strip()]


def only_digits_or_punct(s):
    """True if a string is purely numeric/identifier-like (no meaningful
    script content worth linking as an 880 alternate graphic field)."""
    return bool(re.fullmatch(r"[\d\s./,()\-–—:]*", s or ""))


class LinkedFieldBuilder:
    """Collects romanized fields plus their paired 880 (original-script)
    fields, assigning sequential $6 linking numbers as MARC requires.

    Fields are specified as a list of (code, translit_value, original_value)
    tuples, so that a field with several subfields (e.g. 264 $a place / $b
    publisher) keeps the original-script text aligned to the SAME subfield
    code on both sides of the link, rather than dumping all original text
    under one code.
    """

    def __init__(self, record):
        self.record = record
        self.seq = 0
        self.pending_880s = []

    def next_seq(self):
        self.seq += 1
        return f"{self.seq:02d}"

    def add(self, tag, indicators, specs):
        """specs: list of (code, translit_value, original_value) tuples, in
        the desired output order. A tuple is skipped on the romanized side
        if translit_value is falsy, and skipped on the original side if
        original_value is falsy or purely numeric/punctuation (nothing
        meaningful to link)."""
        translit_subs = [Subfield(code, val) for code, val, _orig in specs if norm(val)]
        orig_pairs = [
            (code, orig) for code, _val, orig in specs
            if norm(orig) and not only_digits_or_punct(orig)
        ]

        if not translit_subs:
            return

        if orig_pairs:
            seq = self.next_seq()
            translit_subs.append(Subfield("6", f"880-{seq}"))
            self.record.add_field(Field(tag=tag, indicators=indicators, subfields=translit_subs))

            orig_subs = [Subfield("6", f"{tag}-{seq}")]
            orig_subs.extend(Subfield(code, orig) for code, orig in orig_pairs)
            self.pending_880s.append(Field(tag="880", indicators=indicators, subfields=orig_subs))
        else:
            self.record.add_field(Field(tag=tag, indicators=indicators, subfields=translit_subs))

    def flush(self):
        for f in self.pending_880s:
            self.record.add_field(f)
        self.pending_880s = []


# --------------------------------------------------------------------------
# Field classification (maps the loose "field" labels from extraction into
# roles this script knows how to place in MARC)
# --------------------------------------------------------------------------

def classify(rows):
    roles = {
        "title": None, "subtitle": None, "part": None,
        "author_plain": None, "author_inverted": None, "author_descriptor": None,
        "place": None, "publishers": [], "dates": [], "edition": None,
        "isbn": None, "other_ids": [], "pagination": None, "subjects": None,
        "unclassified": [],
    }
    for row in rows:
        if not norm(row.get("field")):
            continue
        if field_matches(row, "subtitle"):
            roles["subtitle"] = row
        elif field_matches(row, "part", "volume"):
            roles["part"] = row
        elif field_matches(row, "title", exclude=("title page", "descriptor")):
            roles["title"] = row
        elif field_matches(row, "author") and field_matches(row, "descriptor"):
            roles["author_descriptor"] = row
        elif field_matches(row, "author") and field_matches(row, "inverted", "catalog", "cip"):
            roles["author_inverted"] = row
        elif field_matches(row, "author"):
            roles["author_plain"] = row
        elif field_matches(row, "place of publication", "place"):
            roles["place"] = row
        elif field_matches(row, "publisher", "co-publisher", "distributor"):
            roles["publishers"].append(row)
        elif field_matches(row, "publication date", "date"):
            roles["dates"].append(row)
        elif field_matches(row, "edition"):
            roles["edition"] = row
        elif field_matches(row, "isbn"):
            roles["isbn"] = row
        elif field_matches(row, "deposit", "identifying number", "identifier"):
            roles["other_ids"].append(row)
        elif field_matches(row, "pagination", "page"):
            roles["pagination"] = row
        elif field_matches(row, "subject"):
            roles["subjects"] = row
        else:
            roles["unclassified"].append(row)
    return roles


# --------------------------------------------------------------------------
# 008 fixed field
# --------------------------------------------------------------------------

def build_008(pub_year, country_code, lang_code, ambiguous_date):
    today = datetime.now().strftime("%y%m%d")
    date_type = "q" if ambiguous_date else "s"
    year = re.sub(r"\D", "", pub_year or "")[:4].ljust(4, "u") if pub_year else "uuuu"
    date2 = "    "
    country_code = (country_code or "xx ")[:3].ljust(3)
    lang_code = (lang_code or "und")[:3].ljust(3)

    field = (
        today +            # 00-05 date entered on file
        date_type +        # 06 type of date
        year +             # 07-10 date 1
        date2 +            # 11-14 date 2
        country_code +     # 15-17 place of publication
        "        " +       # 18-25 (illustrations x4, target audience... simplified blank)
        " " +               # 26
        "0" +               # 27 (unused/gov't pub placeholder simplified)
        "0" +               # 28 government publication
        "0" +               # 29 conference publication
        "0" +               # 30 festschrift
        "0" +               # 31 index
        " " +               # 32 undefined
        "0" +               # 33 literary form (0 = not fiction)
        " " +               # 34 biography
        lang_code +         # 35-37 language
        " " +               # 38 modified record
        "d"                 # 39 cataloging source
    )
    # Pad/truncate defensively to exactly 40 characters.
    field = (field + " " * 40)[:40]
    return field


# --------------------------------------------------------------------------
# Main conversion
# --------------------------------------------------------------------------

def build_record(rows, orig_lang, country_override, agency):
    roles = classify(rows)
    record = Record()
    record.leader = "00000nam a2200000 a 4500"
    lb = LinkedFieldBuilder(record)
    notes = []  # collected 500 general notes, added near the end

    # ---- 020 ISBN ----
    if roles["isbn"]:
        isbn_val = norm(roles["isbn"].get("original")) or norm(roles["isbn"].get("transliteration"))
        if isbn_val:
            record.add_field(Field(tag="020", indicators=[" ", " "], subfields=[Subfield("a", isbn_val)]))

    # ---- 040 Cataloging source ----
    record.add_field(Field(
        tag="040", indicators=[" ", " "],
        subfields=[Subfield("a", agency), Subfield("b", "eng"), Subfield("e", "rda"), Subfield("c", agency)],
    ))

    # ---- 041 Language code ----
    record.add_field(Field(tag="041", indicators=["0", " "], subfields=[Subfield("a", orig_lang)]))

    # ---- 100 Main entry: author ----
    author_row = roles["author_inverted"] or roles["author_plain"]
    author_added = False
    if author_row:
        translit = norm(author_row.get("transliteration")) or norm(author_row.get("original"))
        original = norm(author_row.get("original"))
        specs = [("a", translit, original)]
        if roles["author_descriptor"]:
            desc_translit = norm(roles["author_descriptor"].get("transliteration"))
            desc_original = norm(roles["author_descriptor"].get("original"))
            if desc_translit:
                specs.append(("c", desc_translit, desc_original))
        # If we only have the plain (non-inverted) name, note that the 100
        # field is not in strict "Surname, Given name" catalog form.
        lb.add("100", ["1", " "], specs)
        author_added = True

        if roles["author_descriptor"]:
            desc_translation = norm(roles["author_descriptor"].get("translation"))
            desc_original = norm(roles["author_descriptor"].get("original"))
            if desc_translation or desc_original:
                notes.append(f"Author described on title page as: {desc_original} "
                             f"({norm(roles['author_descriptor'].get('transliteration'))}"
                             f"{' -- ' + desc_translation if desc_translation else ''}).")

        # If both plain and inverted forms were extracted, keep the one not
        # used for 100 as a 500 note, so no data captured by Claude is lost.
        other = roles["author_plain"] if author_row is roles["author_inverted"] else roles["author_inverted"]
        if other and norm(other.get("transliteration")) and norm(other.get("transliteration")) != translit:
            notes.append(f"Name also appears as: {norm(other.get('transliteration'))} "
                         f"({norm(other.get('original'))}).")

    # ---- 245 Title statement ----
    if roles["title"]:
        title_translit = norm(roles["title"].get("transliteration")) or norm(roles["title"].get("original"))
        title_original = norm(roles["title"].get("original"))
        specs = [("a", title_translit, title_original)]

        if roles["subtitle"]:
            sub_translit = norm(roles["subtitle"].get("transliteration"))
            sub_original = norm(roles["subtitle"].get("original"))
            if sub_translit:
                specs.append(("b", sub_translit, sub_original))

        if roles["part"]:
            part_translit = norm(roles["part"].get("transliteration"))
            part_original = norm(roles["part"].get("original"))
            if part_translit:
                specs.append(("n", part_translit, part_original))

        if author_row:
            resp_translit = norm(author_row.get("transliteration")) or norm(author_row.get("original"))
            resp_original = norm(author_row.get("original"))
            if resp_translit:
                specs.append(("c", resp_translit, resp_original))

        ind1 = "1" if author_added else "0"
        lb.add("245", [ind1, "0"], specs)

        title_translation = norm(roles["title"].get("translation"))
        if title_translation and not is_untranslated_name(title_translation):
            notes.append(f"Title translates as: \"{title_translation}\".")
        if roles["subtitle"]:
            sub_translation = norm(roles["subtitle"].get("translation"))
            if sub_translation and not is_untranslated_name(sub_translation):
                notes.append(f"Subtitle translates as: \"{sub_translation}\".")

    # ---- 250 Edition ----
    if roles["edition"]:
        ed_translit = norm(roles["edition"].get("transliteration"))
        ed_original = norm(roles["edition"].get("original"))
        if ed_translit:
            lb.add("250", [" ", " "], [("a", ed_translit, ed_original)])

    # ---- 264 Publication statement(s) ----
    place_translit = norm(roles["place"].get("transliteration")) if roles["place"] else ""
    place_original = norm(roles["place"].get("original")) if roles["place"] else ""
    country_code = country_override or guess_country_code(place_translit or place_original)

    primary_date = None
    ambiguous_date = False
    if roles["dates"]:
        primary_date = roles["dates"][0]
        if len(roles["dates"]) > 1:
            ambiguous_date = True
            date_texts = []
            for d in roles["dates"]:
                label = norm(d.get("field"))
                val = norm(d.get("transliteration")) or norm(d.get("original"))
                date_texts.append(f"{label}: {val}")
            notes.append("Conflicting publication dates found -- " + "; ".join(date_texts) + ".")

    date_val = norm(primary_date.get("transliteration")) if primary_date else ""

    if roles["publishers"]:
        for i, pub in enumerate(roles["publishers"]):
            pub_translit = norm(pub.get("transliteration"))
            pub_original = norm(pub.get("original"))
            is_distributor = field_matches(pub, "distributor") and not field_matches(pub, "publisher")
            ind2 = "2" if is_distributor else "1"
            specs = []
            if i == 0 and place_translit:
                specs.append(("a", place_translit, place_original))
            if pub_translit:
                specs.append(("b", pub_translit, pub_original))
            if i == 0 and date_val:
                specs.append(("c", date_val, None))
            if specs:
                lb.add("264", [" ", ind2], specs)

            pub_translation = norm(pub.get("translation"))
            if pub_translation and not is_untranslated_name(pub_translation):
                notes.append(f"{'Distributor' if is_distributor else 'Publisher'} name translates as: "
                             f"\"{pub_translation}\" ({pub_original}).")
    elif place_translit or date_val:
        specs = []
        if place_translit:
            specs.append(("a", place_translit, place_original))
        if date_val:
            specs.append(("c", date_val, None))
        lb.add("264", [" ", "1"], specs)

    # ---- 300 Physical description ----
    if roles["pagination"]:
        pag_translit = norm(roles["pagination"].get("transliteration")) or norm(roles["pagination"].get("original"))
        pag_original = norm(roles["pagination"].get("original"))
        if pag_translit:
            lb.add("300", [" ", " "], [("a", pag_translit, pag_original)])

    # ---- 546 Language note ----
    lang_name = LANGUAGE_NAMES.get(orig_lang, orig_lang)
    record.add_field(Field(
        tag="546", indicators=[" ", " "],
        subfields=[Subfield("a", f"Text in {lang_name}; title and access points romanized (ALA-LC).")],
    ))

    #ignore subjects assigned by LLM
    # ---- 650 Subjects ----
    """
    if roles["subjects"]:
        subj_translit_terms = split_multi(norm(roles["subjects"].get("transliteration")))
        subj_original_terms = split_multi(norm(roles["subjects"].get("original")))
        subj_translation_terms = split_multi(norm(roles["subjects"].get("translation")))
        for idx, term in enumerate(subj_translit_terms):
            orig_term = subj_original_terms[idx] if idx < len(subj_original_terms) else None
            lb.add("650", [" ", "4"], [("a", term, orig_term)])
        if subj_translation_terms:
            notes.append("Subject headings translate as: " + "; ".join(subj_translation_terms) + ".")
    """

    # ---- 500 Other identifiers (deposit numbers etc.) ----
    for other in roles["other_ids"]:
        label = norm(other.get("field"))
        val = norm(other.get("transliteration")) or norm(other.get("original"))
        if val:
            notes.append(f"{label}: {val}.")

    # ---- Any unclassified rows -> notes, so nothing extracted is lost ----
    for row in roles["unclassified"]:
        label = norm(row.get("field"))
        val = norm(row.get("transliteration")) or norm(row.get("original"))
        if label and val:
            notes.append(f"{label}: {val}.")

    # Flush all pending 880 fields (after all romanized fields are placed).
    lb.flush()

    # Add all accumulated 500 notes.
    for note in notes:
        record.add_field(Field(tag="500", indicators=[" ", " "], subfields=[Subfield("a", note)]))

    # ---- 008 fixed field ----
    record.add_field(Field(tag="008", data=build_008(date_val, country_code, orig_lang, ambiguous_date)))

    # ---- 001 / 005 control fields ----
    control_id = None
    if roles["isbn"]:
        control_id = re.sub(r"[^0-9Xx]", "", norm(roles["isbn"].get("original")) or "")
    if not control_id:
        control_id = "local" + datetime.now().strftime("%Y%m%d%H%M%S")
    record.add_field(Field(tag="001", data=control_id))
    record.add_field(Field(tag="005", data=datetime.now(timezone.utc).strftime("%Y%m%d%H%M%S.0")))

    return record

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
        "-p", "--prefix",
        default="output",
        help="Output filename for [filename].mrc and [filename].mrk (default: output)",
    )
    parser.add_argument(
        "-l", "--orig-lang",
        default="ara",
        help="MARC language code of the original text (default: ara)",
    )
    parser.add_argument(
        "--country", 
        default=None, 
        help="Override the MARC country code (e.g. 'jo ' for Jordan); auto-guessed from place of publication if omitted"
    )
    parser.add_argument(
        "--agency",
        default="XX-LclLib", 
        help="MARC organization code for the cataloging agency (040 $a/$c); replace with your institution's MARC code"
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

    args = parser.parse_args()

    api_key = args.api_key or os.environ.get("AWS_BEARER_TOKEN_BEDROCK")
    if not api_key:
        sys.exit(
            "Error: no API key found. Set the AWS_BEARER_TOKEN_BEDROCK environment "
            "variable or pass --api-key."
        )

    print(f"Sending {len(args.images)} image(s) to {args.model}...", file=sys.stderr)
    raw_response = call_claude(args.images, args.model, api_key)
    
    cleaned = clean_text(raw_response)
    rows = parse_rows(cleaned)

    if not rows:
        sys.exit("Error: no metadata rows were extracted from the images.")
        
    record = build_record(rows, args.orig_lang, args.country, args.agency)
    
    print("\n--- Parsed record preview ---")
    print(record)
    
    with open(args.prefix + ".mrc", "wb") as f:
        f.write(record.as_marc())
    print(f"Wrote MARC21 record to {args.prefix}", file=sys.stderr)

    with open(args.prefix + ".mrk", "w", encoding="utf-8") as f:
        f.write(str(record))
    print(f"Wrote human-readable MARC tag view to {args.prefix}", file=sys.stderr)


if __name__ == "__main__":
    main()
