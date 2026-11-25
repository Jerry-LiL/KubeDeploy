"""Process settings. Everything comes from the environment."""

from __future__ import annotations

import os
from dataclasses import dataclass


@dataclass(frozen=True)
class Settings:
    host: str
    port: int
    log_level: str
    ready: bool


def load_settings() -> Settings:
    return Settings(
        host=os.environ.get("ORDERS_API_HOST", "0.0.0.0"),
        port=int(os.environ.get("ORDERS_API_PORT", "8080")),
        log_level=os.environ.get("ORDERS_API_LOG_LEVEL", "INFO").upper(),
        ready=os.environ.get("ORDERS_API_READY", "true").lower() == "true",
    )
