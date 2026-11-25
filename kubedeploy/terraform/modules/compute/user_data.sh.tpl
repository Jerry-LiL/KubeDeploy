#!/bin/bash
set -euo pipefail

dnf install -y docker
systemctl enable --now docker

IMAGE="${image}"
REGION="${region}"

if [ -z "$IMAGE" ]; then
  echo "No application image configured"
  exit 0
fi

REGISTRY="$(echo "$IMAGE" | cut -d/ -f1)"
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$REGISTRY" || true

if docker pull "$IMAGE"; then
  docker rm -f orders-api >/dev/null 2>&1 || true
  docker run -d --restart unless-stopped --name orders-api -p 8080:8080 "$IMAGE"
else
  echo "Image is not in the registry yet; docker is installed for a later deploy"
fi
