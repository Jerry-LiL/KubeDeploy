PYTHON ?= .venv/bin/python
PIP ?= .venv/bin/pip

.PHONY: install test lint tf-validate docker-build scan

install:
	python3 -m venv .venv
	$(PIP) install -U pip
	$(PIP) install -r requirements-dev.txt

test:
	$(PYTHON) -m pytest

lint:
	$(PYTHON) -m ruff check .

tf-validate:
	./scripts/tf-validate.sh

docker-build:
	docker build -t orders-api:local kubedeploy/app

scan: docker-build
	trivy image --severity HIGH,CRITICAL --ignore-unfixed --exit-code 1 orders-api:local
