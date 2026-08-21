import io
import os
import uuid
from datetime import datetime, timezone
from urllib.parse import quote

import requests
from flask import Flask, jsonify, request
from firebase_admin import auth, firestore, initialize_app
from google.cloud import storage

app = Flask(__name__)

initialize_app()
storage_client = storage.Client()
firestore_client = firestore.Client()
rembg_session = None

bucket_name = os.getenv("FIREBASE_STORAGE_BUCKET", "").strip()
max_input_bytes = int(os.getenv("MAX_INPUT_BYTES", str(20 * 1024 * 1024)))
allow_origin = os.getenv("ALLOW_ORIGIN", "*")
allowed_origins = {
    item.strip()
    for item in os.getenv("MANA_POSTER_ALLOWED_ORIGINS", allow_origin).split(",")
    if item.strip()
}
alpha_matting_enabled = os.getenv("REMBG_ALPHA_MATTING", "true").lower() == "true"
alpha_fg_threshold = int(os.getenv("REMBG_ALPHA_FG_THRESHOLD", "240"))
alpha_bg_threshold = int(os.getenv("REMBG_ALPHA_BG_THRESHOLD", "12"))
alpha_erode_size = int(os.getenv("REMBG_ALPHA_ERODE_SIZE", "8"))
pixelcut_api_key = os.getenv("PIXELCUT_API_KEY", "").strip()
pixelcut_remove_bg_url = os.getenv(
    "PIXELCUT_REMOVE_BG_URL",
    "https://api.developer.pixelcut.ai/v1/remove-background",
).strip()
pixelcut_timeout_seconds = int(os.getenv("PIXELCUT_TIMEOUT_SECONDS", "45"))
clearbackdrop_remove_bg_url = os.getenv(
    "CLEARBACKDROP_REMOVE_BG_URL",
    "https://clearbackdrop.com/api/v1/remove-background",
).strip()
clearbackdrop_timeout_seconds = int(os.getenv("CLEARBACKDROP_TIMEOUT_SECONDS", "45"))


def _rembg_session():
    global rembg_session
    if rembg_session is None:
        from rembg import new_session

        rembg_session = new_session(model_name=os.getenv("REMBG_MODEL", "u2net"))
    return rembg_session


def _cors_headers(response):
    request_origin = (request.headers.get("Origin") or "").strip()
    if "*" in allowed_origins:
        response.headers["Access-Control-Allow-Origin"] = "*"
    elif request_origin and request_origin in allowed_origins:
        response.headers["Access-Control-Allow-Origin"] = request_origin
        response.headers["Vary"] = "Origin"
    response.headers["Access-Control-Allow-Headers"] = "Authorization, Content-Type"
    response.headers["Access-Control-Allow-Methods"] = "POST, OPTIONS"
    return response


def _error(message, status=400):
    return _cors_headers(jsonify({"success": False, "message": message})), status


def _extract_bearer_token():
    auth_header = request.headers.get("Authorization", "")
    if not auth_header.startswith("Bearer "):
        return None
    token = auth_header[len("Bearer ") :].strip()
    return token or None


def _verify_user():
    token = _extract_bearer_token()
    if not token:
        return None
    try:
        return auth.verify_id_token(token)
    except Exception:
        return None


def _as_datetime(value):
    if value is None:
        return None
    if isinstance(value, datetime):
        return value if value.tzinfo else value.replace(tzinfo=timezone.utc)
    try:
        parsed = datetime.fromisoformat(str(value).replace("Z", "+00:00"))
        return parsed if parsed.tzinfo else parsed.replace(tzinfo=timezone.utc)
    except Exception:
        return None


def _has_active_editor_entitlement(uid):
    if not uid:
        return False
    try:
        snapshot = (
            firestore_client.collection("users")
            .document(uid)
            .collection("entitlements")
            .document("pro")
            .get()
        )
        if not snapshot.exists:
            return False
        data = snapshot.to_dict() or {}
        if data.get("isPro") is not True:
            return False
        if data.get("editorAccess") is not True:
            return False
        status = str(data.get("status") or "").strip().lower()
        if status == "active":
            return True
        expiry_time = _as_datetime(data.get("expiryTime"))
        return expiry_time is not None and expiry_time > datetime.now(timezone.utc)
    except Exception:
        return False


def _validate_path_for_user(path, uid):
    path = (path or "").strip().replace("\\", "/")
    if not path:
        return None
    prefix = f"users/{uid}/rembg_jobs/"
    if not path.startswith(prefix):
        return None
    return path


def _firebase_download_url(bucket, output_path):
    blob = bucket.blob(output_path)
    metadata = blob.metadata or {}
    token = metadata.get("firebaseStorageDownloadTokens")
    if not token:
        token = str(uuid.uuid4())
        metadata["firebaseStorageDownloadTokens"] = token
        blob.metadata = metadata
        blob.patch()
    encoded_path = quote(output_path, safe="")
    return (
        f"https://firebasestorage.googleapis.com/v0/b/{bucket.name}/o/"
        f"{encoded_path}?alt=media&token={token}"
    )


def _remove_with_pixelcut(image_bytes):
    response = requests.post(
        pixelcut_remove_bg_url,
        headers={
            "X-API-KEY": pixelcut_api_key,
            "Accept": "application/json",
        },
        files={"image": ("input.png", image_bytes, "image/png")},
        data={"format": "png"},
        timeout=pixelcut_timeout_seconds,
    )
    if 200 <= response.status_code < 300 and response.content:
        content_type = response.headers.get("Content-Type", "")
        if content_type.startswith("image/"):
            return response.content

    response.raise_for_status()
    data = response.json()
    result_url = str(data.get("result_url") or "").strip()
    if not result_url:
        raise RuntimeError("Pixelcut response did not include result_url.")
    download = requests.get(result_url, timeout=pixelcut_timeout_seconds)
    download.raise_for_status()
    if not download.content:
        raise RuntimeError("Pixelcut returned an empty result image.")
    return download.content


def _remove_with_clearbackdrop(image_bytes):
    response = requests.post(
        clearbackdrop_remove_bg_url,
        headers={"Accept": "image/png"},
        files={"image": ("input.png", image_bytes, "image/png")},
        timeout=clearbackdrop_timeout_seconds,
    )
    response.raise_for_status()
    if not response.content:
        raise RuntimeError("ClearBackdrop returned an empty result image.")
    return response.content


@app.post("/remove-bg")
def remove_bg():
    if not bucket_name:
        return _error("FIREBASE_STORAGE_BUCKET environment variable is required.", 500)

    user = _verify_user()
    if user is None:
        return _error("Unauthorized", 401)

    direct_file = request.files.get("image")
    payload = request.form if direct_file is not None else (request.get_json(silent=True) or {})
    uid = user.get("uid")
    purpose = str(payload.get("purpose") or "editor_remove_bg").strip()

    delete_input = bool(payload.get("deleteInput", True))
    try:
        bucket = storage_client.bucket(bucket_name)
        input_path = None
        output_path = None
        if direct_file is not None:
            image_bytes = direct_file.read()
        else:
            input_path = _validate_path_for_user(payload.get("inputPath"), uid)
            output_path = _validate_path_for_user(payload.get("outputPath"), uid)
            if not input_path:
                return _error("Invalid inputPath. Must be in users/<uid>/rembg_jobs/*")
            if not output_path:
                return _error("Invalid outputPath. Must be in users/<uid>/rembg_jobs/*")
            input_blob = bucket.blob(input_path)
            if not input_blob.exists():
                return _error("Input image not found in Firebase Storage.", 404)
            image_bytes = input_blob.download_as_bytes()

        if len(image_bytes) > max_input_bytes:
            return _error(
                f"Input image too large. Max {max_input_bytes} bytes supported.", 413
            )

        use_pixelcut_first = False
        if purpose == "profile_photo":
            use_pixelcut_first = bool(pixelcut_api_key)
        elif purpose == "editor_pro_remove_bg":
            use_pixelcut_first = bool(pixelcut_api_key) and _has_active_editor_entitlement(
                uid
            )

        if use_pixelcut_first:
            try:
                output_png = _remove_with_pixelcut(image_bytes)
                engine = "pixelcut"
                model = "pixelcut_remove_background"
            except Exception:
                output_png = _remove_with_clearbackdrop(image_bytes)
                engine = "clearbackdrop"
                model = "clearbackdrop_standard"
        else:
            output_png = _remove_with_clearbackdrop(image_bytes)
            engine = "clearbackdrop"
            model = "clearbackdrop_standard"

        if direct_file is not None:
            response = app.response_class(output_png, mimetype="image/png")
            response.headers["X-Remove-BG-Engine"] = engine
            response.headers["X-Remove-BG-Model"] = model
            return _cors_headers(response)

        output_blob = bucket.blob(output_path)
        output_blob.metadata = {
            "uid": uid,
            "engine": engine,
            "model": model,
            "purpose": purpose,
            "processedAt": datetime.now(timezone.utc).isoformat(),
        }
        output_blob.upload_from_file(
            io.BytesIO(output_png),
            content_type="image/png",
        )

        if delete_input:
            input_blob.delete()

        download_url = _firebase_download_url(bucket, output_path)
        response = jsonify(
            {
                "success": True,
                "uid": uid,
                "engine": engine,
                "model": model,
                "inputPath": input_path,
                "outputPath": output_path,
                "downloadUrl": download_url,
            }
        )
        return _cors_headers(response)
    except Exception as error:
        return _error(f"Background removal failed: {error}", 500)


@app.route("/remove-bg", methods=["OPTIONS"])
def remove_bg_options():
    return _cors_headers(jsonify({"ok": True}))


@app.get("/health")
def health():
    return jsonify({"ok": True, "service": "rembg-cloud-run"})


if __name__ == "__main__":
    port = int(os.environ.get("PORT", "8080"))
    app.run(host="0.0.0.0", port=port)
