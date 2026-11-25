#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
terraform fmt -check -recursive "$root/kubedeploy/terraform"

for dir in bootstrap envs/dev envs/local; do
  echo "validating $dir"
  terraform -chdir="$root/kubedeploy/terraform/$dir" init -backend=false -input=false
  terraform -chdir="$root/kubedeploy/terraform/$dir" validate
done
