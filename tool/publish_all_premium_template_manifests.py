from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


PROJECT_ROOT = Path(__file__).resolve().parent.parent
MANIFEST_ROOT = PROJECT_ROOT / "tool" / "premium_template_manifests"


def _load_manifests() -> list[tuple[Path, dict[str, Any]]]:
    manifests: list[tuple[Path, dict[str, Any]]] = []
    for path in sorted(MANIFEST_ROOT.glob("*.json")):
        manifests.append((path, json.loads(path.read_text(encoding="utf-8"))))
    return manifests


def _publish_manifest(
    *,
    manifest: dict[str, Any],
    storage_bucket: Any,
    firestore_db: Any,
) -> None:
    uploads = manifest["storageUploads"]
    all_uploads = [
        uploads["preview"],
        uploads["document"],
        *uploads["layers"],
    ]

    for item in all_uploads:
        blob = storage_bucket.blob(item["storagePath"])
        blob.upload_from_filename(str(PROJECT_ROOT / item["localPath"]))

    firestore_info = manifest["firestore"]
    firestore_db.collection(firestore_info["collection"]).document(
        firestore_info["documentId"]
    ).set(firestore_info["payload"], merge=True)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Batch publish all premium template manifests to Firebase.",
    )
    parser.add_argument("--service-account", required=True)
    parser.add_argument("--bucket", required=True)
    args = parser.parse_args()

    try:
        import firebase_admin
        from firebase_admin import credentials, firestore, storage
    except Exception as exc:  # pragma: no cover - optional dependency path
        raise RuntimeError(
            "firebase_admin not installed. Run: pip install firebase-admin"
        ) from exc

    if not MANIFEST_ROOT.exists():
        raise FileNotFoundError(f"Manifest directory not found: {MANIFEST_ROOT}")

    manifests = _load_manifests()
    if not manifests:
        print("No manifest files found.")
        return 0

    app = None
    if not firebase_admin._apps:
        cred = credentials.Certificate(args.service_account)
        app = firebase_admin.initialize_app(
            cred,
            {"storageBucket": args.bucket},
        )
    else:
        app = firebase_admin.get_app()

    bucket = storage.bucket(app=app)
    db = firestore.client(app=app)

    for path, manifest in manifests:
        _publish_manifest(
            manifest=manifest,
            storage_bucket=bucket,
            firestore_db=db,
        )
        print(f"Published: {path.name}")

    print(f"Published {len(manifests)} manifest(s) successfully.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
