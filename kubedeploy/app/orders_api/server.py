"""HTTP API for the orders service.

Routes stay on a fixed label set so the Prometheus path label cannot grow
with every order id.
"""

from __future__ import annotations

import json
import logging
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse

from prometheus_client import CONTENT_TYPE_LATEST

from orders_api.config import Settings
from orders_api.metrics import Metrics

log = logging.getLogger(__name__)

ORDERS = (
    {
        "id": "1001",
        "customer": "C1",
        "sku": "SKU-MUG",
        "status": "shipped",
        "total": 39.0,
    },
    {
        "id": "1002",
        "customer": "C2",
        "sku": "SKU-TEA",
        "status": "placed",
        "total": 8.0,
    },
)


def _normalize(path: str) -> str:
    if path != "/" and path.endswith("/"):
        return path.rstrip("/")
    return path


class App:
    def __init__(self, settings: Settings, metrics: Metrics | None = None) -> None:
        self.settings = settings
        self.metrics = metrics or Metrics()

    def handle(self, method: str, path: str) -> tuple[int, dict[str, str], bytes]:
        path = _normalize(path)
        if method != "GET":
            return self._respond(method, "other", 405, {"error": "method not allowed"})
        if path == "/healthz":
            return self._respond(method, path, 200, {"status": "ok"})
        if path == "/readyz":
            if not self.settings.ready:
                return self._respond(method, path, 503, {"status": "not-ready"})
            return self._respond(method, path, 200, {"status": "ready"})
        if path == "/metrics":
            # Count the scrape, then render so this request is in the payload.
            self.metrics.observe(method, path, 200)
            return 200, {"Content-Type": CONTENT_TYPE_LATEST}, self.metrics.render()
        if path == "/api/orders":
            return self._respond(method, path, 200, {"orders": list(ORDERS)})
        if path.startswith("/api/orders/"):
            order_id = path.removeprefix("/api/orders/")
            if not order_id or "/" in order_id:
                return self._respond(method, "other", 404, {"error": "not found"})
            for order in ORDERS:
                if order["id"] == order_id:
                    return self._respond(method, "/api/orders/:id", 200, order)
            return self._respond(method, "/api/orders/:id", 404, {"error": "order not found"})
        if path == "/api/diag/error":
            return self._respond(method, path, 500, {"error": "injected failure"})
        return self._respond(method, "other", 404, {"error": "not found"})

    def _respond(
        self,
        method: str,
        route: str,
        status: int,
        payload: dict,
    ) -> tuple[int, dict[str, str], bytes]:
        self.metrics.observe(method, route, status)
        body = json.dumps(payload).encode()
        return status, {"Content-Type": "application/json"}, body


def handler_for(app: App):
    class Handler(BaseHTTPRequestHandler):
        protocol_version = "HTTP/1.1"

        def do_GET(self) -> None:
            self._respond("GET")

        def do_POST(self) -> None:
            self._respond("POST")

        def _respond(self, method: str) -> None:
            path = urlparse(self.path).path
            status, headers, body = app.handle(method, path)
            self.send_response(status)
            for key, value in headers.items():
                self.send_header(key, value)
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

        def log_message(self, fmt: str, *args) -> None:
            log.info("%s %s", self.address_string(), fmt % args)

    return Handler


def serve(settings: Settings) -> None:
    server = ThreadingHTTPServer((settings.host, settings.port), handler_for(App(settings)))
    log.info("listening on %s:%s", settings.host, settings.port)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        log.info("shutting down")
    finally:
        server.server_close()
