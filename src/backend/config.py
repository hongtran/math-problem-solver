"""
Application settings loaded from environment variables.
"""

from __future__ import annotations

import os
from dataclasses import dataclass
from functools import lru_cache

from dotenv import load_dotenv

load_dotenv()


def _parse_cors_origins() -> tuple[list[str], bool]:
    """
    Return (origins, allow_credentials).

    Browsers reject allow_credentials=True with allow_origins=['*'].
    When using wildcard origins, credentials must be False.
    """
    raw = (os.getenv("CORS_ORIGINS") or "*").strip()
    if raw == "*":
        return ["*"], False
    parts = [p.strip() for p in raw.split(",") if p.strip()]
    if not parts:
        return ["*"], False
    return parts, True


@dataclass(frozen=True)
class Settings:
    openai_api_key: str | None
    cors_origins: list[str]
    cors_allow_credentials: bool
    max_upload_bytes: int
    firebase_key_file: str

    @classmethod
    def from_env(cls) -> Settings:
        origins, creds = _parse_cors_origins()
        max_mb = int(os.getenv("MAX_UPLOAD_MB", "10"))
        return cls(
            openai_api_key=os.getenv("OPENAI_API_KEY"),
            cors_origins=origins,
            cors_allow_credentials=creds,
            max_upload_bytes=max(1, max_mb) * 1024 * 1024,
            firebase_key_file=os.getenv("FIREBASE_KEY_FILE", "serviceAccountKey.json"),
        )


@lru_cache
def get_settings() -> Settings:
    return Settings.from_env()
