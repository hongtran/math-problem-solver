"""Firebase Admin initialization (Firestore)."""

from __future__ import annotations

import logging
import os
from typing import Any

import firebase_admin
from firebase_admin import credentials

logger = logging.getLogger(__name__)


def _build_credentials() -> Any | None:
    project_id = os.getenv("FIREBASE_PROJECT_ID")
    private_key = os.getenv("FIREBASE_PRIVATE_KEY")
    client_email = os.getenv("FIREBASE_CLIENT_EMAIL")
    if project_id and private_key and client_email:
        if isinstance(private_key, str) and "\\n" in private_key:
            private_key = private_key.replace("\\n", "\n")
        cred_dict = {
            "type": "service_account",
            "project_id": project_id,
            "private_key_id": os.getenv("FIREBASE_PRIVATE_KEY_ID", ""),
            "private_key": private_key,
            "client_email": client_email,
            "client_id": os.getenv("FIREBASE_CLIENT_ID", ""),
            "auth_uri": "https://accounts.google.com/o/oauth2/auth",
            "token_uri": "https://oauth2.googleapis.com/token",
            "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
            "client_x509_cert_url": "",
        }
        return credentials.Certificate(cred_dict)

    key_file = os.getenv("FIREBASE_KEY_FILE", "serviceAccountKey.json")
    if os.path.isfile(key_file):
        return credentials.Certificate(key_file)

    if os.getenv("GOOGLE_APPLICATION_CREDENTIALS"):
        return credentials.ApplicationDefault()

    return None


def get_firestore_client() -> Any:
    """
    Initialize Firebase if possible and return Firestore client, or None.

    Safe to call multiple times; reuses the default app if already initialized.
    """
    try:
        cred = _build_credentials()
        if cred is None:
            logger.warning(
                "Firebase not configured: set FIREBASE_PROJECT_ID, FIREBASE_PRIVATE_KEY, "
                "FIREBASE_CLIENT_EMAIL, or place a service account JSON at FIREBASE_KEY_FILE "
                "(default serviceAccountKey.json), or set GOOGLE_APPLICATION_CREDENTIALS."
            )
            return None
        try:
            firebase_admin.get_app()
        except ValueError:
            firebase_admin.initialize_app(cred)
        from firebase_admin import firestore

        return firestore.client()
    except Exception:
        logger.exception("Firebase initialization failed")
        return None
