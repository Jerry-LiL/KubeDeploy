"""Behaviour of the orders-api routes and the 5xx counter."""

from __future__ import annotations

import json
import threading
from http.client import HTTPConnection
from http.server import ThreadingHTTPServer

from orders_api.config import Settings
from orders_api.metrics import Metrics
from orders_api.server import App, handler_for


def _settings(**overrides) -> Settings:
    base = dict(host="127.0.0.1", port=0, log_level="INFO", ready=True)
    base.update(overrides)
    return Settings(**base)


def test_health_ready_and_orders():
    app = App(_settings())
    status, _, body = app.handle("GET", "/healthz")
    assert status == 200
    assert json.loads(body)["status"] == "ok"

    status, _, body = app.handle("GET", "/readyz")
    assert status == 200

    status, _, body = app.handle("GET", "/api/orders")
    orders = json.loads(body)["orders"]
    assert [order["id"] for order in orders] == ["1001", "1002"]

    status, _, body = app.handle("GET", "/api/orders/1002")
    assert status == 200
    assert json.loads(body)["sku"] == "SKU-TEA"

    status, _, _ = app.handle("GET", "/api/orders/9999")
    assert status == 404


def test_readiness_can_fail_closed():
    app = App(_settings(ready=False))
    status, _, body = app.handle("GET", "/readyz")
    assert status == 503
    assert json.loads(body)["status"] == "not-ready"


def test_diag_error_increments_5xx_series():
    metrics = Metrics()
    app = App(_settings(), metrics=metrics)
    status, _, _ = app.handle("GET", "/api/diag/error")
    assert status == 500

    status, headers, body = app.handle("GET", "/metrics")
    assert status == 200
    assert headers["Content-Type"].startswith("text/plain")
    text = body.decode()
    assert 'path="/api/diag/error",status="500"' in text.replace(" ", "")


def test_unknown_paths_share_one_label():
    metrics = Metrics()
    app = App(_settings(), metrics=metrics)
    assert app.handle("GET", "/nope")[0] == 404
    assert app.handle("GET", "/also-missing")[0] == 404
    assert app.handle("POST", "/api/orders")[0] == 405
    rendered = metrics.render().decode()
    assert 'path="other"' in rendered
    assert "/nope" not in rendered


def test_server_accepts_a_connection():
    app = App(_settings())
    server = ThreadingHTTPServer(("127.0.0.1", 0), handler_for(app))
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    port = server.server_address[1]
    try:
        conn = HTTPConnection("127.0.0.1", port, timeout=5)
        conn.request("GET", "/healthz")
        response = conn.getresponse()
        payload = json.loads(response.read())
        assert response.status == 200
        assert payload["status"] == "ok"
    finally:
        server.shutdown()
        server.server_close()


def test_settings_read_environment(monkeypatch):
    monkeypatch.setenv("ORDERS_API_PORT", "9099")
    monkeypatch.setenv("ORDERS_API_READY", "false")
    monkeypatch.setenv("ORDERS_API_LOG_LEVEL", "warning")
    from orders_api.config import load_settings

    settings = load_settings()
    assert settings.port == 9099
    assert settings.ready is False
    assert settings.log_level == "WARNING"
