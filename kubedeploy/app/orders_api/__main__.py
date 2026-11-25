"""Start orders-api."""

from __future__ import annotations

import logging

from orders_api.config import load_settings
from orders_api.server import serve


def main() -> None:
    settings = load_settings()
    logging.basicConfig(
        level=getattr(logging, settings.log_level, logging.INFO),
        format="%(asctime)s %(levelname)s %(message)s",
    )
    serve(settings)


if __name__ == "__main__":
    main()
