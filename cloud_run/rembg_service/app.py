import io
import os
import uuid
from datetime import datetime, timezone
from urllib.parse import quote

from flask import Flask, jsonify, request
from firebase_admin import auth, initialize_app
from google.cloud import storage
from rembg import new_session, remove

app = Flask(__name__)

initialize_app()
storage_client = storage.Client()
rembg_session = new_session(model_name=os.getenv("REMBG_MODEL", "u2net"))

bucket_name = os.getenv("FIREBASE_STORAGE_BUCKET", "").strip()
max_input_bytes = int(os.getenv("MAX_INPUT_BYTES", str(20 * 1024 * 1024)))
allow_origin = os.getenv("ALLOW_ORIGIN", "*")
alpha_matting_enabled = os.getenv("REMBG_ALPHA_MATTING", "true").lower() == "true"
alpha_fg_threshold = int(os.getenv("REMBG_ALPHA_FG_THRESHOLD", "240"))
alpha_bg_threshold = int(os.getenv("REMBG_ALPHA_BG_THRESHOLD", "12"))
alpha_erode_size = int(os.getenv("REMBG_ALPHA_ERODE_SIZE", "8"))


def _cors_headers(response):
    response.headers["Access-Control-Allow-Origin"] = allow_origin
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


@app.post("/remove-bg")
def remove_bg():
    if not bucket_name:
        return _error("FIREBASE_STORAGE_BUCKET environment variable is required.", 500)

    user = _verify_user()
    if user is None:
        return _error("Unauthorized", 401)

    payload = request.get_json(silent=True) or {}
    uid = user.get("uid")
    input_path = _validate_path_for_user(payload.get("inputPath"), uid)
    output_path = _validate_path_for_user(payload.get("outputPath"), uid)

    if not input_path:
        return _error("Invalid inputPath. Must be in users/<uid>/rembg_jobs/*")
    if not output_path:
        return _error("Invalid outputPath. Must be in users/<uid>/rembg_jobs/*")

    delete_input = bool(payload.get("deleteInput", True))
    try:
        bucket = storage_client.bucket(bucket_name)
        input_blob = bucket.blob(input_path)
        if not input_blob.exists():
            return _error("Input image not found in Firebase Storage.", 404)

        image_bytes = input_blob.download_as_bytes()
        if len(image_bytes) > max_input_bytes:
            return _error(
                f"Input image too large. Max {max_input_bytes} bytes supported.", 413
            )

        output_png = remove(
            image_bytes,
            session=rembg_session,
            alpha_matting=alpha_matting_enabled,
            alpha_matting_foreground_threshold=alpha_fg_threshold,
            alpha_matting_background_threshold=alpha_bg_threshold,
            alpha_matting_erode_size=alpha_erode_size,
            force_return_bytes=True,
        )

        output_blob = bucket.blob(output_path)
        output_blob.metadata = {
            "uid": uid,
            "engine": "rembg",
            "model": os.getenv("REMBG_MODEL", "u2net"),
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
                "engine": "rembg",
                "model": os.getenv("REMBG_MODEL", "u2net"),
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
