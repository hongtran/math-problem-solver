"""Normalize images to PNG base64 for vision APIs."""

from __future__ import annotations

import base64
import io
import logging

from PIL import Image

logger = logging.getLogger(__name__)


def normalize_image_bytes_to_png_base64(image_data: bytes) -> str:
    """Load image bytes, convert to PNG, return base64-encoded string."""
    image = Image.open(io.BytesIO(image_data))
    buffered = io.BytesIO()
    image.save(buffered, format="PNG")
    return base64.b64encode(buffered.getvalue()).decode()


def normalize_base64_image_to_png_base64(image_base64: str | None) -> str | None:
    """Decode base64 image, re-encode as PNG base64; return None if input empty or invalid."""
    if not (image_base64 or "").strip():
        return None
    try:
        image_data = base64.b64decode(image_base64)
        return normalize_image_bytes_to_png_base64(image_data)
    except Exception:
        logger.exception("Failed to normalize base64 image")
        return None
