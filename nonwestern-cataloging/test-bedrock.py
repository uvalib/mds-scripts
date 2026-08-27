import sys
import os
import json
import boto3

"""Ensure your AWS credentials (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, and AWS_DEFAULT_REGION) are configured locally via environment variables or the standard AWS CLI configuration."""

PRINTOUT_SYSTEM_PROMPT = """
You are an expert MARC 21 cataloging assistant. You will be shown a photograph of a printed MARC bibliographic record. Transcribe it via OCR and return it as strict, valid JSON representing the MARC record structure. Output ONLY the JSON object -- no markdown code fences, no commentary, no preamble.

JSON schema:
{
  "leader": "<24-character leader string exactly as printed, or your best reconstruction if partially cut off>",
  "fields": [
    {
      "tag": "245",
      "indicators": ["1", "4"],
      "subfields": [
        {"code": "a", "value": "Title text /"},
        {"code": "c", "value": "Statement of responsibility."}
      ],
      "data": null
    }
  ]
}

Critical rules:
1. Preserve field order exactly as printed.
2. Control fields (tags less than "010", e.g. 001, 003, 005, 006, 007, 008) use a plain string in "data" and have no indicators or subfields.
3. All other fields use "indicators" (array of 2 single characters) and "subfields" (array of {code, value} in printed order). A field can repeat the same subfield code multiple times (e.g. two $a's) -- preserve that.
4. If the printout uses a backslash "\\" or similar placeholder to denote a blank/undefined indicator, encode that position as a single space " " in the JSON, not a literal backslash.
5. Preserve non-Latin script text (Arabic, Hebrew, CJK, Cyrillic, etc.) exactly as printed, in logical reading order (not visual/reversed order), as its own field -- typically an 880 field linked via a $6 subfield back to the romanized field (e.g. $6 880-01, with the corresponding 880 field carrying $6 100-01/(3/r). Do not transliterate, translate, or merge non-Latin text into the romanized field.
6. Preserve diacritics and special characters used in ALA-LC romanization (macrons, dots below, ayn/hamza marks, etc.) as precisely as you can read them.
7. If any part of the printout is illegible or ambiguous, make your best reading but do not fabricate data that is not visible on the page.
8. Do not include the leading "=" or the tag itself inside "data" or subfield values -- those are printout formatting, not part of the field content.
9. Return ONLY the JSON object described above.
"""

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


def extract_marc_json(image_path: str, model_id: str = "mistral.ministral-3-14b-instruct") -> str:
    
    # Initialize the Bedrock Runtime client
    client = boto3.client("bedrock-runtime", region_name='us-east-1')
    
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

        return output_text.strip()

    except Exception as e:
        print(f"Error invoking Amazon Bedrock: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python transcribe_marc.py <path_to_image>")
        sys.exit(1)

    image_file = sys.argv[1]
    
    if not os.path.exists(image_file):
        print(f"Error: File '{image_file}' not found.")
        sys.exit(1)

    json_result = extract_marc_json(image_file)
    
    # Print output string directly
    print(json_result)