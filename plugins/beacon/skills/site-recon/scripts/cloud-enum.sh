#!/usr/bin/env bash
# Cloud infrastructure enumeration – AWS S3, Azure Blob, GCS, Cloudflare R2
# Usage: TARGET=example.com ./cloud-enum.sh
set -euo pipefail

if [[ -z "${TARGET:-}" ]]; then
  echo "Error: TARGET environment variable not set" >&2
  exit 1
fi

TARGET_SLUG=$(echo "${TARGET}" | tr '.' '-')

echo "=== Cloud Storage Enumeration for ${TARGET} ==="

echo "--- AWS S3 Buckets ---"
for pattern in "${TARGET_SLUG}" "${TARGET}" "${TARGET//./-}" "assets-${TARGET}" "${TARGET}-assets" "${TARGET}-media" "static-${TARGET}" "cdn-${TARGET}"; do
  status=$(curl -sf -o /dev/null -w "%{http_code}" --max-time 5 "https://${pattern}.s3.amazonaws.com/" || true)
  if [[ "$status" =~ ^2 ]]; then
    echo "S3-BUCKET-FOUND: https://${pattern}.s3.amazonaws.com/ [${status}]"
  fi
  status=$(curl -sf -o /dev/null -w "%{http_code}" --max-time 5 "https://s3.amazonaws.com/${pattern}/" || true)
  if [[ "$status" =~ ^2 ]]; then
    echo "S3-BUCKET-FOUND: https://s3.amazonaws.com/${pattern}/ [${status}]"
  fi
done

echo "--- Azure Blob Storage ---"
for pattern in "${TARGET_SLUG}" "${TARGET}" "${TARGET//./-}"; do
  status=$(curl -sf -o /dev/null -w "%{http_code}" --max-time 5 "https://${pattern}.blob.core.windows.net/" || true)
  if [[ "$status" =~ ^2 ]]; then
    echo "AZURE-BLOB-FOUND: https://${pattern}.blob.core.windows.net/ [${status}]"
  fi
done

echo "--- Google Cloud Storage ---"
for pattern in "${TARGET_SLUG}" "${TARGET}" "${TARGET//./-}"; do
  status=$(curl -sf -o /dev/null -w "%{http_code}" --max-time 5 "https://storage.googleapis.com/${pattern}/" || true)
  if [[ "$status" =~ ^2 ]]; then
    echo "GCS-BUCKET-FOUND: https://storage.googleapis.com/${pattern}/ [${status}]"
  fi
  status=$(curl -sf -o /dev/null -w "%{http_code}" --max-time 5 "https://${pattern}.storage.googleapis.com/" || true)
  if [[ "$status" =~ ^2 ]]; then
    echo "GCS-BUCKET-FOUND: https://${pattern}.storage.googleapis.com/ [${status}]"
  fi
done

echo "--- Cloudflare R2 ---"
for pattern in "${TARGET_SLUG}" "${TARGET}" "${TARGET//./-}"; do
  status=$(curl -sf -o /dev/null -w "%{http_code}" --max-time 5 "https://${pattern}.r2.cloudflarestorage.com/" || true)
  if [[ "$status" =~ ^2 ]]; then
    echo "R2-BUCKET-FOUND: https://${pattern}.r2.cloudflarestorage.com/ [${status}]"
  fi
done

echo "=== Cloud enumeration complete ==="