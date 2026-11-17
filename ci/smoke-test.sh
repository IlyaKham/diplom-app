#!/usr/bin/env bash
set -Eeuo pipefail
image="${1:?Provide an image}"
expected_version="${2:?Provide the expected version}"
container="diplom-test-${GITHUB_RUN_ID:-local}-${GITHUB_RUN_ATTEMPT:-1}"
started=false
cleanup() {
  code=$?
  if [[ "$started" == true ]]; then
    if [[ "$code" != 0 ]]; then docker logs "$container"; fi
    docker rm --force "$container" >/dev/null
  fi
  exit "$code"
}
trap cleanup EXIT
docker run --detach --name "$container" --read-only --tmpfs /tmp:rw,noexec,nosuid,size=16m \
  --cap-drop ALL --security-opt no-new-privileges:true --publish 127.0.0.1:18080:8080 "$image"
started=true
base=http://127.0.0.1:18080
curl --fail --silent --show-error --retry 20 --retry-connrefused --retry-delay 1 "$base/healthz" | grep -qx ok
curl --fail --silent --show-error "$base/" | grep -q '<title>Diplom'
curl --fail --silent --show-error "$base/style.css" >/dev/null
curl --fail --silent --show-error "$base/app.js" >/dev/null
curl --fail --silent --show-error "$base/version.json" | jq -e --arg version "$expected_version" '.version == $version and (.revision | length > 0)' >/dev/null
[[ "$(curl --silent --output /dev/null --write-out '%{http_code}' "$base/missing-page")" == 404 ]]
[[ "$(docker exec "$container" id -u)" == 101 ]]
docker exec "$container" nginx -t
echo 'Application HTTP, build metadata, non-root user and read-only filesystem checks passed.'
