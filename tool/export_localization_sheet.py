import ast
import csv
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "docs" / "localization_translation_sheet.csv"
LANGUAGES = {
    "assamese": "as",
    "konkani": "gom",
    "gujarati": "gu",
    "marathi": "mr",
    "meitei": "mni-Mtei",
    "mizo": "lus",
    "odia": "or",
    "punjabi": "pa",
    "nepali": "ne",
    "bengali": "bn",
    "kashmiri": "ks",
}


def collect_strings():
    literal = r'''("(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*')'''
    patterns = [
        re.compile(r"\benglish\s*:\s*" + literal, re.S),
        re.compile(r"SupportedUiLanguage\.english\s*=>\s*" + literal, re.S),
        re.compile(r"_regionalFallback\(\s*" + literal, re.S),
    ]
    values = set()
    for path in (ROOT / "lib").rglob("*.dart"):
        source = path.read_text(encoding="utf-8")
        for pattern in patterns:
            for match in pattern.finditer(source):
                try:
                    value = ast.literal_eval(match.group(1)).strip()
                except (SyntaxError, ValueError):
                    continue
                if value and "$" not in value:
                    values.add(value)
    return sorted(values, key=str.casefold)


def main():
    strings = collect_strings()
    headers = ["key", "english", *LANGUAGES, "ladakhi"]
    with OUTPUT.open("w", encoding="utf-8-sig", newline="") as file:
        writer = csv.writer(file)
        writer.writerow(headers)
        for index, english in enumerate(strings, start=2):
            row = [f"ui_{index - 1:04d}", english]
            for code in LANGUAGES.values():
                row.append(
                    f'=IFERROR(GOOGLETRANSLATE($B{index},"en","{code}"),$B{index})'
                )
            row.append(f"=$B{index}")
            writer.writerow(row)
    print(f"Exported {len(strings)} strings to {OUTPUT}")


if __name__ == "__main__":
    main()
