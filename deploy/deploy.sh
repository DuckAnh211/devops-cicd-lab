#!/usr/bin/env bash
set -euo pipefail

: "${DOCKERHUB_USERNAME:?Set DOCKERHUB_USERNAME}"
: "${IMAGE_TAG:?Set IMAGE_TAG to a full commit SHA}"
[[ "$DOCKERHUB_USERNAME" =~ ^[a-z0-9][a-z0-9_-]*$ ]] || exit 2
[[ "$IMAGE_TAG" =~ ^[a-f0-9]{40}$ ]] || exit 2
export DOCKERHUB_USERNAME IMAGE_TAG

target=/opt/devops-cicd-lab
source_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
cd "$target"
umask 077

# Pull before replacing the running service. Persist the tag only after healthy.
docker pull "$DOCKERHUB_USERNAME/devops-cicd-lab:$IMAGE_TAG"
install -m 644 "$source_dir/compose.yaml" compose.yaml
docker compose -p devops-cicd-lab up -d --no-build --wait --wait-timeout 120
actual_version=$(curl --fail --silent --show-error http://127.0.0.1:3000/ | python3 -c 'import json,sys; print(json.load(sys.stdin)["version"])')
if [[ "$actual_version" != "$IMAGE_TAG" ]]; then
  printf 'Expected version %s, received %s\n' "$IMAGE_TAG" "$actual_version" >&2
  exit 1
fi
if [[ -f .env ]]; then cp .env .previous.env; fi
printf 'DOCKERHUB_USERNAME=%s\nIMAGE_TAG=%s\n' "$DOCKERHUB_USERNAME" "$IMAGE_TAG" > .env.next
mv .env.next .env
docker compose -p devops-cicd-lab ps
curl --fail --silent --show-error http://127.0.0.1:3000/health
printf '\n'
