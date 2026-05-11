#!/usr/bin/env bash
# Container & Orchestration discovery – Docker Registry, Kubernetes, dashboards
# Usage: TARGET=example.com ./container-scan.sh
set -euo pipefail

if [[ -z "${TARGET:-}" ]]; then
  echo "Error: TARGET environment variable not set" >&2
  exit 1
fi

echo "=== Container & Orchestration Discovery for ${TARGET} ==="

echo "--- Docker Registry API ---"
status=$(curl -sf -o /dev/null -w "%{http_code}" --max-time 5 "https://${TARGET}/v2/_catalog" || true)
if [[ "$status" =~ ^2 ]]; then
  echo "DOCKER-REGISTRY: https://${TARGET}/v2/_catalog [${status}]"
  curl -sf --max-time 10 "https://${TARGET}/v2/_catalog" | python3 -c "import sys,json; d=json.load(sys.stdin); print('Repos:', d.get('repositories',[]))" 2>/dev/null || true
fi

status=$(curl -sf -o /dev/null -w "%{http_code}" --max-time 5 "https://${TARGET}/v2/" || true)
if [[ "$status" =~ ^2 ]]; then
  echo "DOCKER-REGISTRY-V2: https://${TARGET}/v2/ [${status}]"
fi

echo "--- Kubernetes API Endpoints ---"
for port in 6443 8443 8080 443; do
  status=$(curl -k -sf -o /dev/null -w "%{http_code}" --max-time 5 "https://${TARGET}:${port}/api/v1/namespaces" || true)
  if [[ "$status" =~ ^2 ]]; then
    echo "K8S-API-FOUND: https://${TARGET}:${port}/api/v1/namespaces [${status}]"
  fi
  status=$(curl -k -sf -o /dev/null -w "%{http_code}" --max-time 5 "https://${TARGET}:${port}/apis/apps/v1/deployments" || true)
  if [[ "$status" =~ ^2 ]]; then
    echo "K8S-DEPLOYMENTS-FOUND: https://${TARGET}:${port}/apis/apps/v1/deployments [${status}]"
  fi
done

echo "--- Container Orchestration Dashboards ---"
for path in "/dashboard" "/kubernetes-dashboard" "/k8s-dashboard" "/rancher" "/portainer" "/ui" "/manage" "/admin"; do
  status=$(curl -sf -o /dev/null -w "%{http_code}" --max-time 5 "https://${TARGET}${path}" || true)
  if [[ "$status" =~ ^2 ]]; then
    echo "DASHBOARD-FOUND: https://${TARGET}${path} [${status}]"
  fi
done

echo "=== Container scan complete ==="