from __future__ import annotations

import json
import re
import sys
from pathlib import Path

from psd_tools import PSDImage


OUTPUT_ROOT = Path("assets/templates/premium/political")


def slugify(name: str) -> str:
    normalized = re.sub(r"[^a-zA-Z0-9]+", "_", name.strip().lower())
    return normalized.strip("_") or "template"


def ensure_directories(template_slug: str) -> tuple[Path, Path, Path]:
    preview_dir = OUTPUT_ROOT / "previews"
    document_dir = OUTPUT_ROOT / "documents"
    layer_dir = OUTPUT_ROOT / "layers" / template_slug
    preview_dir.mkdir(parents=True, exist_ok=True)
    document_dir.mkdir(parents=True, exist_ok=True)
    layer_dir.mkdir(parents=True, exist_ok=True)
    return preview_dir, document_dir, layer_dir


def export_psd(path: Path) -> None:
    template_slug = f"political_{slugify(path.stem)}"
    preview_dir, document_dir, layer_dir = ensure_directories(template_slug)

    psd = PSDImage.open(path)
    preview_path = preview_dir / f"{template_slug}.png"
    psd.composite().convert("RGBA").save(preview_path)

    layers: list[dict[str, object]] = []
    layer_index = 0

    for layer in psd.descendants():
        if layer.is_group() or not layer.is_visible():
            continue

        left, top, right, bottom = layer.bbox
        if right <= left or bottom <= top:
          continue

        composite = layer.composite()
        if composite is None:
            continue

        layer_index += 1
        asset_filename = f"layer_{layer_index:03d}.png"
        asset_path = layer_dir / asset_filename
        composite.convert("RGBA").save(asset_path)

        layers.append(
            {
                "id": f"{template_slug}_layer_{layer_index:03d}",
                "assetPath": asset_path.as_posix(),
                "left": left,
                "top": top,
                "width": right - left,
                "height": bottom - top,
                "opacity": float(getattr(layer, "opacity", 255)) / 255.0,
                "visible": True,
                "name": layer.name,
                "kind": getattr(layer, "kind", "pixel"),
            }
        )

    document = {
        "templateId": template_slug,
        "title": path.stem,
        "sourceWidth": psd.width,
        "sourceHeight": psd.height,
        "layers": layers,
    }

    document_path = document_dir / f"{template_slug}.json"
    document_path.write_text(
        json.dumps(document, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    print(f"Exported {path.name} -> {document_path}")


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print("Usage: python tool/import_premium_psd_templates.py <psd> [<psd>...]")
        return 1

    for raw_path in argv[1:]:
        export_psd(Path(raw_path))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
