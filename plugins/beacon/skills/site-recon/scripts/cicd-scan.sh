#!/usr/bin/env bash
# CI/CD Pipeline enumeration – GitHub Actions, GitLab CI, Jenkins, CircleCI
# Usage: TARGET=example.com ./cicd-scan.sh
set -euo pipefail

if [[ -z "${TARGET:-}" ]]; then
  echo "Error: TARGET environment variable not set" >&2
  exit 1
fi

echo "=== CI/CD Pipeline Discovery for ${TARGET} ==="

echo "--- GitHub Actions Workflows ---"
for path in ".github/workflows/" ".github/workflows/*.yml" ".github/workflows/*.yaml"; do
  status=$(curl -sf -o /dev/null -w "%{http_code}" --max-time 5 "https://${TARGET}/${path}" || true)
  if [[ "$status" =~ ^2 ]]; then
    echo "GITHUB-ACTIONS: https://${TARGET}/${path} [${status}]"
  fi
done

echo "--- GitLab CI/CD ---"
status=$(curl -sf -o /dev/null -w "%{http_code}" --max-time 5 "https://${TARGET}/.gitlab-ci.yml" || true)
if [[ "$status" =~ ^2 ]]; then
  echo "GITLAB-CI: https://${TARGET}/.gitlab-ci.yml [${status}]"
fi
status=$(curl -sf -o /dev/null -w "%{http_code}" --max-time 5 "https://gitlab.${TARGET}/.gitlab-ci.yml" || true)
if [[ "$status" =~ ^2 ]]; then
  echo "GITLAB-CI-SUBDOMAIN: https://gitlab.${TARGET}/.gitlab-ci.yml [${status}]"
fi

echo "--- Jenkins ---"
status=$(curl -sf -o /dev/null -w "%{http_code}" --max-time 5 "https://${TARGET}/jenkins/" || true)
if [[ "$status" =~ ^2 ]]; then
  echo "JENKINS-DASHBOARD: https://${TARGET}/jenkins/ [${status}]"
  content=$(curl -sf --max-time 10 "https://${TARGET}/jenkins/api/json" || true)
  if [[ -n "$content" ]]; then
    echo "JENKINS-API: https://${TARGET}/jenkins/api/json accessible"
  fi
fi

echo "--- Other CI/CD Configurations ---"
for file in ".travis.yml" "azure-pipelines.yml" ".circleci/config.yml" "Jenkinsfile" ".gitlab-ci.yml"; do
  status=$(curl -sf -o /dev/null -w "%{http_code}" --max-time 5 "https://${TARGET}/${file}" || true)
  if [[ "$status" =~ ^2 ]]; then
    echo "CI-CD-CONFIG: https://${TARGET}/${file} [${status}]"
  fi
done

echo "--- Build Automation Endpoints ---"
for path in "/build" "/ci" "/pipeline" "/deploy" "/webhook" "/hooks"; do
  status=$(curl -sf -o /dev/null -w "%{http_code}" --max-time 5 "https://${TARGET}${path}" || true)
  if [[ "$status" =~ ^2 ]]; then
    echo "BUILD-ENDPOINT: https://${TARGET}${path} [${status}]"
  fi
done

echo "=== CI/CD scan complete ==="