from __future__ import annotations

import argparse
import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any


PROJECT_ROOT = Path(__file__).resolve().parent.parent
ASSET_ROOT = PROJECT_ROOT / "assets" / "templates" / "premium"
MANIFEST_ROOT = PROJECT_ROOT / "tool" / "premium_template_manifests"


@dataclass(frozen=True)
class TemplatePublishBundle:
    category: str
    template_id: str
    preview_path: Path
    document_path: Path
    layer_dir: Path

    @property
    def layer_files(self) -> list[Path]:
        return sorted(
            [
                path
                for path in self.layer_dir.glob("*.png")
                if path.is_file()
            ]
        )


def _discover_template_bundle(category: str, template_id: str) -> TemplatePublishBundle:
    category_root = ASSET_ROOT / category
    preview_path = category_root / "previews" / f"{template_id}.png"
    document_path = category_root / "documents" / f"{template_id}.json"
    layer_dir = category_root / "layers" / template_id

    missing = [
        str(path)
        for path in (preview_path, document_path, layer_dir)
        if not path.exists()
    ]
    if missing:
        raise FileNotFoundError(
            f"Missing template files for {template_id}: {', '.join(missing)}"
        )

    return TemplatePublishBundle(
        category=category,
        template_id=template_id,
        preview_path=preview_path,
        document_path=document_path,
        layer_dir=layer_dir,
    )


def _build_firestore_payload(
    *,
    bundle: TemplatePublishBundle,
    title_en: str,
    title_te: str,
    title_hi: str,
    product_id: str,
    price_inr: int,
    sort_order: int,
) -> dict[str, Any]:
    document = json.loads(bundle.document_path.read_text(encoding="utf-8"))
    width = int(document.get("sourceWidth", 1080))
    height = int(document.get("sourceHeight", 1080))

    storage_base = f"premium_templates/{bundle.category}/{bundle.template_id}"
    return {
        "category": bundle.category,
        "isActive": True,
        "sortOrder": sort_order,
        "titleEn": title_en,
        "titleTe": title_te,
        "titleHi": title_hi,
        "priceInr": price_inr,
        "productId": product_id,
        "widthPx": width,
        "heightPx": height,
        "previewStoragePath": f"{storage_base}/preview.png",
        "templateDocumentStoragePath": f"{storage_base}/document.json",
        "layerStoragePrefix": f"{storage_base}/layers",
        "layerCount": len(bundle.layer_files),
    }


def _build_manifest(
    *,
    bundle: TemplatePublishBundle,
    firestore_payload: dict[str, Any],
) -> dict[str, Any]:
    storage_base = f"premium_templates/{bundle.category}/{bundle.template_id}"
    return {
        "templateId": bundle.template_id,
        "category": bundle.category,
        "storageUploads": {
            "preview": {
                "localPath": bundle.preview_path.relative_to(PROJECT_ROOT).as_posix(),
                "storagePath": f"{storage_base}/preview.png",
            },
            "document": {
                "localPath": bundle.document_path.relative_to(PROJECT_ROOT).as_posix(),
                "storagePath": f"{storage_base}/document.json",
            },
            "layers": [
                {
                    "localPath": path.relative_to(PROJECT_ROOT).as_posix(),
                    "storagePath": f"{storage_base}/layers/{path.name}",
                }
                for path in bundle.layer_files
            ],
        },
        "firestore": {
            "collection": "premium_templates",
            "documentId": bundle.template_id,
            "payload": firestore_payload,
        },
    }


def _write_manifest(manifest: dict[str, Any], template_id: str) -> Path:
    MANIFEST_ROOT.mkdir(parents=True, exist_ok=True)
    output_path = MANIFEST_ROOT / f"{template_id}.json"
    output_path.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    return output_path


def _maybe_publish_with_firebase(
    *,
    manifest: dict[str, Any],
    service_account_path: str | None,
    bucket_name: str | None,
) -> bool:
    if not service_account_path or not bucket_name:
        return False

    try:
        import firebase_admin
        from firebase_admin import credentials, firestore, storage
    except Exception as exc:  # pragma: no cover - optional dependency path
        raise RuntimeError(
            "firebase_admin not installed. Run: pip install firebase-admin"
        ) from exc

    app = None
    if not firebase_admin._apps:
        cred = credentials.Certificate(service_account_path)
        app = firebase_admin.initialize_app(
            cred,
            {"storageBucket": bucket_name},
        )
    else:
        app = firebase_admin.get_app()

    bucket = storage.bucket(app=app)
    for item in (
        [manifest["storageUploads"]["preview"], manifest["storageUploads"]["document"]]
        + manifest["storageUploads"]["layers"]
    ):
        blob = bucket.blob(item["storagePath"])
        blob.upload_from_filename(str(PROJECT_ROOT / item["localPath"]))

    db = firestore.client(app=app)
    firestore_info = manifest["firestore"]
    db.collection(firestore_info["collection"]).document(
        firestore_info["documentId"]
    ).set(firestore_info["payload"], merge=True)
    return True


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Generate and optionally publish Firebase manifests for premium templates.",
    )
    parser.add_argument("--category", required=True)
    parser.add_argument("--template-id", required=True)
    parser.add_argument("--title-en", required=True)
    parser.add_argument("--title-te", required=True)
    parser.add_argument("--title-hi", required=True)
    parser.add_argument("--product-id", required=True)
    parser.add_argument("--price-inr", type=int, default=499)
    parser.add_argument("--sort-order", type=int, default=0)
    parser.add_argument("--service-account")
    parser.add_argument("--bucket")
    args = parser.parse_args()

    bundle = _discover_template_bundle(args.category, args.template_id)
    firestore_payload = _build_firestore_payload(
        bundle=bundle,
        title_en=args.title_en,
        title_te=args.title_te,
        title_hi=args.title_hi,
        product_id=args.product_id,
        price_inr=args.price_inr,
        sort_order=args.sort_order,
    )
    manifest = _build_manifest(bundle=bundle, firestore_payload=firestore_payload)
    manifest_path = _write_manifest(manifest, args.template_id)
    print(f"Manifest written: {manifest_path}")

    if _maybe_publish_with_firebase(
        manifest=manifest,
        service_account_path=args.service_account,
        bucket_name=args.bucket,
    ):
        print("Firebase upload + Firestore publish completed.")
    else:
        print("Manifest only mode completed. Pass --service-account and --bucket to publish.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
