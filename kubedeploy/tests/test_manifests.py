"""The manifests really carry the probes, limits, and 5xx alerts."""

from __future__ import annotations

import json
import subprocess
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[2]


def _docs() -> list[dict]:
    rendered = subprocess.check_output(
        ["kubectl", "kustomize", str(ROOT / "kubedeploy")],
        text=True,
    )
    return [doc for doc in yaml.safe_load_all(rendered) if doc]


def _by_kind(docs: list[dict], kind: str, name: str) -> dict:
    matches = [
        doc
        for doc in docs
        if doc.get("kind") == kind and doc.get("metadata", {}).get("name") == name
    ]
    assert len(matches) == 1, f"{kind}/{name} not found"
    return matches[0]


def test_orders_deployment_contract():
    docs = _docs()
    deploy = _by_kind(docs, "Deployment", "orders-api")
    spec = deploy["spec"]
    assert spec["strategy"]["type"] == "RollingUpdate"
    rolling = spec["strategy"]["rollingUpdate"]
    assert rolling["maxUnavailable"] == 0
    assert rolling["maxSurge"] == 1

    container = spec["template"]["spec"]["containers"][0]
    assert container["livenessProbe"]["httpGet"]["path"] == "/healthz"
    assert container["readinessProbe"]["httpGet"]["path"] == "/readyz"
    assert container["resources"]["requests"]["cpu"] == "100m"
    assert container["resources"]["limits"]["memory"] == "256Mi"
    assert spec["template"]["spec"]["securityContext"]["runAsNonRoot"] is True

    config = _by_kind(docs, "ConfigMap", "orders-api")
    assert config["data"]["ORDERS_API_PORT"] == "8080"

    service = _by_kind(docs, "Service", "orders-api")
    assert service["spec"]["ports"][0]["port"] == 8080

    ingress = _by_kind(docs, "Ingress", "orders-api")
    assert ingress["spec"]["rules"][0]["host"] == "orders.kubedeploy.local"

    hpa = _by_kind(docs, "HorizontalPodAutoscaler", "orders-api")
    assert hpa["spec"]["minReplicas"] == 2
    assert hpa["spec"]["maxReplicas"] == 6
    assert hpa["spec"]["scaleTargetRef"]["name"] == "orders-api"


def test_prometheus_and_grafana_alert_on_5xx():
    docs = _docs()
    prom_config = _by_kind(docs, "ConfigMap", "prometheus-config")
    alerts = yaml.safe_load(prom_config["data"]["alerts.yml"])
    rule = alerts["groups"][0]["rules"][0]
    assert rule["alert"] == "Http5xxSpike"
    assert 'status=~"5.."' in rule["expr"]
    assert rule["for"] == "2m"

    scrape = yaml.safe_load(prom_config["data"]["prometheus.yml"])
    jobs = {item["job_name"]: item for item in scrape["scrape_configs"]}
    assert jobs["orders-api"]["static_configs"][0]["targets"] == ["orders-api:8080"]

    grafana_rules = yaml.safe_load(
        _by_kind(docs, "ConfigMap", "grafana-alerting")["data"]["rules.yml"]
    )
    grafana_rule = grafana_rules["groups"][0]["rules"][0]
    assert grafana_rule["title"] == "orders-api 5xx spike"
    expr = grafana_rule["data"][0]["model"]["expr"]
    assert 'status=~"5.."' in expr

    dashboard = json.loads(
        _by_kind(docs, "ConfigMap", "grafana-dashboard-orders")["data"]["orders-api.json"]
    )
    titles = {panel["title"] for panel in dashboard["panels"]}
    assert "5xx rate" in titles

    datasource = yaml.safe_load(
        _by_kind(docs, "ConfigMap", "grafana-datasources")["data"]["prometheus.yml"]
    )
    assert datasource["datasources"][0]["uid"] == "prometheus"
    assert _by_kind(docs, "Deployment", "grafana")
    assert _by_kind(docs, "Deployment", "prometheus")
