import csv
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "lib" / "app" / "localization" / "regional_translations.g.dart"
LANGUAGES = [
    "assamese",
    "konkani",
    "gujarati",
    "marathi",
    "meitei",
    "mizo",
    "odia",
    "punjabi",
    "nepali",
    "bengali",
    "kashmiri",
    "ladakhi",
]


def quote(value):
    return json.dumps(value, ensure_ascii=False).replace("$", r"\$")


def main():
    if len(sys.argv) != 2:
        raise SystemExit("Usage: import_localization_sheet.py <translated.csv>")
    source = Path(sys.argv[1])
    with source.open("r", encoding="utf-8-sig", newline="") as file:
        rows = list(csv.DictReader(file))
    if not rows:
        raise SystemExit("Translated CSV is empty")
    required = {"english", *LANGUAGES}
    missing_columns = required.difference(rows[0])
    if missing_columns:
        raise SystemExit(f"Missing columns: {sorted(missing_columns)}")

    lines = [
        "// GENERATED FILE. DO NOT EDIT.",
        "const Map<String, Map<String, String>> generatedRegionalTranslations =",
        "    <String, Map<String, String>>{",
    ]
    for language in LANGUAGES:
        lines.append(f"  {quote(language)}: <String, String>{{")
        for row in rows:
            english = row["english"].strip()
            translated = row[language].strip()
            if not english or not translated or translated.startswith("="):
                raise SystemExit(
                    f"Unresolved translation for {language}: {english[:80]}"
                )
            lines.append(f"    {quote(english)}: {quote(translated)},")
        lines.append("  },")
    lines.extend(["};", ""])
    OUTPUT.write_text("\n".join(lines), encoding="utf-8")
    print(f"Imported {len(rows)} strings into {OUTPUT}")


if __name__ == "__main__":
    main()
