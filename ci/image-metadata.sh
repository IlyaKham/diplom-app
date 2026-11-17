#!/usr/bin/env bash
set -Eeuo pipefail
[[ "${YC_REGISTRY_ID:-}" =~ ^[a-z0-9]{20}$ ]] || { echo 'Set the YC_REGISTRY_ID repository variable.' >&2; exit 1; }
[[ "${GITHUB_SHA:-}" =~ ^[a-f0-9]{40}$ ]] || { echo 'Invalid Git commit SHA.' >&2; exit 1; }

release=false
version="sha-${GITHUB_SHA:0:12}"
tag="sha-$GITHUB_SHA"
if [[ "$GITHUB_REF" == refs/tags/v* ]]; then
  [[ "$GITHUB_REF_NAME" =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$ ]] || { echo 'Release tags must look like v1.0.0 or v1.0.0-rc.1.' >&2; exit 1; }
  release=true
  version="$GITHUB_REF_NAME"
  tag="$GITHUB_REF_NAME"
fi

{
  printf 'image=cr.yandex/%s/diplom-app:%s\n' "$YC_REGISTRY_ID" "$tag"
  printf 'version=%s\n' "$version"
  printf 'release=%s\n' "$release"
  printf 'built_at=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
} >> "$GITHUB_OUTPUT"
