#!/usr/bin/env python3
"""
marc-from-image.py

Take a photograph/scan of a printed MARC record, send it to the Claude API
for OCR + structured parsing, and write out the record as:
  - <prefix>.mrc  (binary MARC-21, UTF-8 encoded)
  - <prefix>.mrk  (plain-text MARC, human readable)
  - <prefix>.xml  (MARCXML)

Setup
-----
    pip install anthropic pymarc
    export ANTHROPIC_API_KEY=sk-ant-...

Usage
-----
    python marc_from_image.py page.jpg
    python marc_from_image.py page.jpg --output-prefix my_record
    python marc_from_image.py page.jpg --model claude-sonnet-5

Notes
-----
- Designed for printouts that list one MARC record per page, with tags,
  indicators, and $-coded subfields, similar to an ILS "view record" export.
- Non-Latin script (Arabic, CJK, Cyrillic, etc.) is expected to appear either
  inline or as linked 880 fields (with $6 back-links, e.g. "880-01/(3/r").
  The prompt instructs Claude to preserve that structure rather than merge
  fields or transliterate.
- OCR of non-Latin, especially cursive scripts like Arabic, is inherently
  more error-prone than Latin text. ALWAYS proofread the output .mrk file
  against the original image before treating the record as final.
"""

import argparse, base64, json, mimetypes, re, sys, os, boto3
from pathlib import Path

try:
    from anthropic import AnthropicBedrockMantle
except ImportError:
    sys.exit(
        "The 'anthropic' package is required. Install it with:\n"
        "    pip install -U \"anthropic[bedrock]\""
    )

try:
    from pymarc import Field, Leader, Record, Subfield
except ImportError:
    sys.exit("Missing dependency. Run: pip install pymarc")


DEFAULT_MODEL = "anthropic.claude-sonnet-5"

PRINTOUT_SYSTEM_PROMPT = """You are an expert MARC 21 cataloging assistant. You will be \
shown a photograph of a printed MARC bibliographic record (e.g. an ILS staff \
view printout). Transcribe it via OCR and return it as strict, valid JSON \
representing the MARC record structure. Output ONLY the JSON object -- no \
markdown code fences, no commentary, no preamble.

JSON schema:
{
  "leader": "<24-character leader string exactly as printed, or your best \
reconstruction if partially cut off>",
  "fields": [
    {
      "tag": "245",
      "indicators": ["1", "4"],          // two single characters; use " " \
for a blank indicator; omit or use [" ", " "] for control fields
      "subfields": [
        {"code": "a", "value": "Title text /"},
        {"code": "c", "value": "Statement of responsibility."}
      ],
      "data": null                        // for control fields 001-009 use \
"data" (a plain string) instead of "subfields"/"indicators"
    }
  ]
}

Critical rules:
1. Preserve field order exactly as printed.
2. Control fields (tags less than "010", e.g. 001, 003, 005, 006, 007, 008) \
use a plain string in "data" and have no indicators or subfields.
3. All other fields use "indicators" (array of 2 single characters) and \
"subfields" (array of {code, value} in printed order). A field can repeat \
the same subfield code multiple times (e.g. two $a's) -- preserve that.
4. If the printout uses a backslash "\\" or similar placeholder to denote a \
blank/undefined indicator, encode that position as a single space " " in \
the JSON, not a literal backslash.
5. Preserve non-Latin script text (Arabic, Hebrew, CJK, Cyrillic, etc.) \
exactly as printed, in logical reading order (not visual/reversed order), \
as its own field -- typically an 880 field linked via a $6 subfield back to \
the romanized field (e.g. $6 880-01, with the corresponding 880 field \
carrying $6 100-01/(3/r). Do not transliterate, translate, or merge \
non-Latin text into the romanized field.
6. Preserve diacritics and special characters used in ALA-LC romanization \
(macrons, dots below, ayn/hamza marks, etc.) as precisely as you can read \
them.
7. If any part of the printout is illegible or ambiguous, make your best \
reading but do not fabricate data that is not visible on the page.
8. Do not include the leading "=" or the tag itself inside "data" or \
subfield values -- those are printout formatting, not part of the field \
content.
9. Return ONLY the JSON object described above.
"""

PRINTOUT_USER_PROMPT = (
    "Here is a photograph of a printed MARC record. Transcribe it into the "
    "JSON structure described in your instructions. Return only the JSON."
)

#base64 encode an image for Claude
def encode_image(file_path: str):
    path = Path(file_path)
    media_type, _ = mimetypes.guess_type(str(path))
    if media_type not in {"image/jpeg", "image/png", "image/gif", "image/webp"}:
        media_type = "image/jpeg"
    data = base64.standard_b64encode(path.read_bytes()).decode("ascii")
    return data, media_type

#read image bytes for Gemini
def get_image_bytes_and_format(file_path: str):
    """Read local image file into bytes and determine format."""
    ext = os.path.splitext(file_path)[1].lower()
    format_map = {
        ".jpg": "jpeg",
        ".jpeg": "jpeg",
        ".png": "png",
        ".webp": "webp",
        ".gif": "gif"
    }
    
    if ext not in format_map:
        raise ValueError(f"Unsupported image extension '{ext}'. Use PNG, JPEG, WEBP, or GIF.")
    
    with open(file_path, "rb") as image_file:
        return image_file.read(), format_map[ext]
    


#pass images to Claude API and receive JSON response with MARC fields and subfields
def call_claude(image_path: Path, model: str, api_key: str) -> dict:
    #client = anthropic.Anthropic()
    client = AnthropicBedrockMantle(aws_region="us-east-1")
    image_data, media_type = encode_image(image_path)

    message = client.messages.create(
        model=model,
        max_tokens=4096,
        system=PRINTOUT_SYSTEM_PROMPT,
        messages=[
            {
                "role": "user",
                "content": [
                    {
                        "type": "image",
                        "source": {
                            "type": "base64",
                            "media_type": media_type,
                            "data": image_data,
                        },
                    },
                    {"type": "text", "text": PRINTOUT_USER_PROMPT},
                ],
            }
        ],
    )

    text_blocks = [b.text for b in message.content if b.type == "text"]
    raw_text = "\n".join(text_blocks).strip()

    # Defensive cleanup in case the model wraps the JSON in a code fence
    # despite instructions not to.
    raw_text = re.sub(r"^```(?:json)?\s*", "", raw_text)
    raw_text = re.sub(r"\s*```$", "", raw_text)

    try:
        return json.loads(raw_text)
    except json.JSONDecodeError as exc:
        sys.exit(
            "Could not parse Claude's response as JSON.\n"
            f"Error: {exc}\n\n--- Raw response ---\n{raw_text}"
        )


#pass images to Boto3 Bedrock runtime for given LLM model to receive JSON
def extract_marc_json(image_path: str, model_id: str = "mistral.ministral-3-14b-instruct") -> str:
    
    # Initialize the Bedrock Runtime client
    client = boto3.client("bedrock-runtime", region_name='us-east-1')
    
    with Image(filename=image_path) as img:
        if img.height > 1600 or img.width > 1600:
            print("Resizing", image_path)
            resize_image(image_path, img)
    
    # Read image
    image_bytes, image_format = get_image_bytes_and_format(image_path)
    

    # Structure payload using Amazon Bedrock Converse API format
    messages = [
        {
            "role": "user",
            "content": [
                {
                    "image": {
                        "format": image_format,
                        "source": {
                            "bytes": image_bytes
                        }
                    }
                },
                {
                    "text": PRINTOUT_SYSTEM_PROMPT
                }
            ]
        }
    ]

    
    try:
        response = client.converse(
            modelId=model_id,
            messages=messages,
            inferenceConfig={
                "temperature": 0.0,
                "maxTokens": 4096
            }
        )

        # Extract output text content
        output_text = response["output"]["message"]["content"][0]["text"].strip()
        
        # Clean up any potential markdown code blocks if present
        if output_text.startswith("```json"):
            output_text = output_text[7:]
        if output_text.startswith("```"):
            output_text = output_text[3:]
        if output_text.endswith("```"):
            output_text = output_text[:-3]
            
        try:
            return json.loads(output_text)
        except json.JSONDecodeError as exc:
            sys.exit(
                "Could not parse response as JSON.\n"
                f"Error: {exc}\n\n--- Raw response ---\n{output_text}"
            )

    except Exception as e:
        print(f"Error invoking Amazon Bedrock: {e}", file=sys.stderr)
        sys.exit(1)
        
#--------------------
# WRITING JSON TO MARC
#--------------------
def normalize_leader(leader_str: str) -> str:
    leader_str = (leader_str or "").rstrip("\n")
    if len(leader_str) < 24:
        leader_str = leader_str.ljust(24)
    return leader_str[:24]


def build_record(parsed: dict) -> Record:
    record = Record(force_utf8=True)
    record.leader = Leader(normalize_leader(parsed.get("leader", " " * 24)))

    for field_def in parsed.get("fields", []):
        tag = str(field_def.get("tag", "")).zfill(3)

        if tag < "010":
            data = field_def.get("data", "") or ""
            record.add_field(Field(tag=tag, data=data))
            continue

        raw_indicators = field_def.get("indicators") or [" ", " "]
        indicators = [(c if c not in ("", None) else " ") for c in raw_indicators]
        while len(indicators) < 2:
            indicators.append(" ")
        indicators = indicators[:2]

        subfields = [
            Subfield(sf.get("code", "a"), sf.get("value", ""))
            for sf in field_def.get("subfields", [])
        ]

        record.add_field(
            Field(tag=tag, indicators=indicators, subfields=subfields)
        )

    return record


def write_outputs(record: Record, prefix: Path) -> None:
    mrc_path = prefix.with_suffix(".mrc")
    mrk_path = prefix.with_suffix(".mrk")
    #xml_path = prefix.with_suffix(".xml")

    with open(mrc_path, "wb") as f:
        f.write(record.as_marc())

    with open(mrk_path, "w", encoding="utf-8") as f:
        f.write(str(record))

    """from pymarc import marcxml
    xml_bytes = marcxml.record_to_xml(record, namespace=True)
    with open(xml_path, "wb") as f:
        f.write(b'<?xml version="1.0" encoding="UTF-8"?>\n')
        f.write(b'<collection xmlns="http://www.loc.gov/MARC21/slim">\n')
        f.write(xml_bytes)
        f.write(b"\n</collection>\n")"""

    print(f"Wrote {mrc_path}")
    print(f"Wrote {mrk_path}")


def main():
    parser = argparse.ArgumentParser(
        description="OCR a printed MARC record image via the Claude API and "
        "emit .mrc, .mrk, and MARCXML files."
    )
    parser.add_argument("image", type=Path, help="Path to the image file")
    parser.add_argument(
        "--output-prefix",
        type=Path,
        default=None,
        help="Output file prefix (default: same name as the image, no extension)",
    )
    parser.add_argument(
        "--model",
        default=DEFAULT_MODEL,
        help=f"Claude model to use (default: {DEFAULT_MODEL})",
    )
    parser.add_argument(
        "--print-json",
        action="store_true",
        help="Print the intermediate parsed JSON (useful for debugging OCR errors)",
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

    if not args.image.exists():
        sys.exit(f"Image not found: {args.image}")

    prefix = args.output_prefix or args.image.with_suffix("")

    print(f"Sending {args.image} to {args.model} for OCR + parsing...")
    parsed = call_claude(args.image, args.model, api_key)

    if args.print_json:
        print(json.dumps(parsed, ensure_ascii=False, indent=2))

    record = build_record(parsed)
    print("\n--- Parsed record preview ---")
    print(record)

    write_outputs(record, prefix)

    print(
        "\nDone. Non-Latin script fields (e.g. 880 fields) were OCR'd "
        "directly -- please proofread them against the original image "
        "before treating this record as final."
    )


if __name__ == "__main__":
    main()
