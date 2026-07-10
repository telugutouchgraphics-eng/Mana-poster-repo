from __future__ import annotations

import csv
from pathlib import Path
from typing import Dict, Iterable, Optional, Tuple

from fontTools.ttLib import TTFont


OUT_PATH = Path("test/data/telugu_legacy_font_compatibility_report.csv")
RAKARAM_CODES = (0xF081, 0xF0E7)


def read_legacy_fonts() -> list[tuple[str, str]]:
    fonts: list[tuple[str, str]] = []
    family: Optional[str] = None
    for raw_line in Path("pubspec.yaml").read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if line.startswith("- family: "):
            family = line[len("- family: ") :]
        elif family and line.startswith("- asset: assets/fonts/telugu_legacy/"):
            fonts.append((family, line[len("- asset: ") :]))
            family = None
    return sorted(fonts)


def cmap_for(font: TTFont) -> Dict[int, str]:
    cmap: Dict[int, str] = {}
    for table in font["cmap"].tables:
        cmap.update(table.cmap)
    return cmap


def glyph_box(font: TTFont, glyph_name: str) -> Tuple[int, int, int, int]:
    glyf = font.get("glyf")
    if glyf is None or glyph_name not in glyf:
        return (0, 0, 0, 0)
    glyph = glyf[glyph_name]
    try:
        if glyph.isComposite():
            glyph.recalcBounds(glyf)
    except Exception:
        pass
    values = tuple(getattr(glyph, key, 0) or 0 for key in ("xMin", "yMin", "xMax", "yMax"))
    return values  # type: ignore[return-value]


def metric_for(font: TTFont, cmap: Dict[int, str], code: int) -> dict[str, object]:
    glyph = cmap.get(code, "")
    advance, lsb = font["hmtx"].metrics.get(glyph, (0, 0))
    box = glyph_box(font, glyph) if glyph else (0, 0, 0, 0)
    return {
        "glyph": glyph,
        "advance": advance or 0,
        "lsb": lsb or 0,
        "x_min": box[0],
        "x_max": box[2],
    }


def required_rakaram_order(metrics: Iterable[dict[str, object]]) -> str:
    max_x = max(int(metric["x_max"]) for metric in metrics)
    return "leading_rakaram" if max_x >= 360 else "trailing_rakaram"


def rakaram_behavior(order: str) -> str:
    if order == "trailing_rakaram":
        return "negative-left overlay glyph; emit rakaram after conjunct"
    return "wide pre-base overlay glyph; emit rakaram before conjunct"


def main() -> None:
    rows: list[dict[str, object]] = []
    for family, asset in read_legacy_fonts():
        font = TTFont(asset)
        cmap = cmap_for(font)
        metrics = [metric_for(font, cmap, code) for code in RAKARAM_CODES]
        order = required_rakaram_order(metrics)
        has_gsub = "GSUB" in font
        has_gpos = "GPOS" in font
        missing = [hex(code) for code, metric in zip(RAKARAM_CODES, metrics) if not metric["glyph"]]
        status = "FAIL" if missing else "PASS"
        rows.append(
            {
                "font": family,
                "status": status,
                "required_glyph_order": order,
                "rakaram_behavior": rakaram_behavior(order),
                "required_converter_profile": f"{order}+separated_kst_vattu_order",
                "gsub": str(has_gsub).lower(),
                "gpos": str(has_gpos).lower(),
                "f081_xmax": metrics[0]["x_max"],
                "f0e7_xmax": metrics[1]["x_max"],
                "reason": "missing rakaram glyphs: " + " ".join(missing)
                if missing
                else "classified from actual glyph bounds; font has no GSUB/GPOS positioning",
            }
        )

    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    with OUT_PATH.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)
    print(f"Wrote {OUT_PATH}")
    print(f"Fonts audited: {len(rows)}")
    print(f"PASS: {sum(1 for row in rows if row['status'] == 'PASS')}")
    print(f"FAIL: {sum(1 for row in rows if row['status'] == 'FAIL')}")


if __name__ == "__main__":
    main()
