"""A small Prometheus registry owned by one process."""

from __future__ import annotations

from prometheus_client import CollectorRegistry, Counter, generate_latest


class Metrics:
    def __init__(self) -> None:
        self.registry = CollectorRegistry()
        self.requests = Counter(
            "http_requests_total",
            "HTTP requests served by orders-api.",
            ("method", "path", "status"),
            registry=self.registry,
        )

    def observe(self, method: str, path: str, status: int) -> None:
        self.requests.labels(method=method, path=path, status=str(status)).inc()

    def render(self) -> bytes:
        return generate_latest(self.registry)
