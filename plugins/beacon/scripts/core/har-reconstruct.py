#!/usr/bin/env python3
"""
har-reconstruct.py — Converts Chrome DevTools MCP or cmux browser network capture JSON to HAR 1.2.

Auto-detects input format. Filters analytics/static noise.

Usage:
    python3 har-reconstruct.py --input <path> --output <path> [--domain <domain>]
"""

import argparse
import json
import sys
from datetime import datetime, timezone
from urllib.parse import urlparse


ANALYTICS_BLOCKLIST = {
    "google-analytics.com",
    "googletagmanager.com",
    "mixpanel.com",
    "hotjar.com",
    "amplitude.com",
    "segment.io",
    "segment.com",
    "facebook.net",
    "doubleclick.net",
    "ads.twitter.com",
}

STATIC_EXTENSIONS = {
    ".woff", ".woff2", ".ttf", ".eot",
    ".png", ".jpg", ".jpeg", ".gif", ".svg", ".ico", ".webp",
    ".mp4", ".mp3",
}


def detect_format(entries):
    """Return 'chrome' or 'cmux' based on entry shape."""
    if not entries:
        return "chrome"
    first = entries[0]
    if "reqid" in first:
        return "chrome"
    if "request" in first and isinstance(first["request"], dict):
        return "cmux"
    # Default to chrome
    return "chrome"


def headers_dict_to_list(headers_dict):
    """Convert a dict of headers to HAR-style list of {name, value}."""
    if not headers_dict:
        return []
    if isinstance(headers_dict, list):
        return headers_dict
    return [{"name": k, "value": str(v)} for k, v in headers_dict.items()]


def get_mime_type(headers):
    """Extract mimeType from response headers (dict or list)."""
    if isinstance(headers, dict):
        for k, v in headers.items():
            if k.lower() == "content-type":
                return v.split(";")[0].strip()
    elif isinstance(headers, list):
        for item in headers:
            if item.get("name", "").lower() == "content-type":
                return item.get("value", "").split(";")[0].strip()
    return "application/octet-stream"


def build_entry_from_chrome(raw):
    """Convert a Chrome MCP format entry to HAR entry."""
    url = raw.get("url", "")
    method = raw.get("method", "GET").upper()
    status = raw.get("status", 0)
    req_headers = raw.get("request_headers", {})
    resp_headers = raw.get("response_headers", {})
    resp_body = raw.get("response_body", "") or ""

    mime_type = get_mime_type(resp_headers)
    body_size = len(resp_body.encode("utf-8")) if resp_body else 0

    return {
        "startedDateTime": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.000Z"),
        "time": 100,
        "cache": {},
        "timings": {"send": 0, "wait": 100, "receive": 0},
        "request": {
            "method": method,
            "url": url,
            "httpVersion": "HTTP/1.1",
            "headers": headers_dict_to_list(req_headers),
            "cookies": [],
            "queryString": [],
            "headersSize": -1,
            "bodySize": -1,
        },
        "response": {
            "status": status,
            "statusText": "",
            "httpVersion": "HTTP/1.1",
            "headers": headers_dict_to_list(resp_headers),
            "cookies": [],
            "redirectURL": "",
            "headersSize": -1,
            "bodySize": body_size,
            "content": {
                "size": body_size,
                "mimeType": mime_type,
                "text": resp_body,
            },
        },
    }


def build_entry_from_cmux(raw):
    """Convert a cmux format entry to HAR entry."""
    request = raw.get("request", {})
    response = raw.get("response", {})

    url = request.get("url", "")
    method = request.get("method", "GET").upper()
    req_headers = request.get("headers", {})

    status = response.get("status", 0)
    resp_headers = response.get("headers", {})
    resp_body = response.get("body", "") or ""

    mime_type = get_mime_type(resp_headers)
    body_size = len(resp_body.encode("utf-8")) if resp_body else 0

    return {
        "startedDateTime": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.000Z"),
        "time": 100,
        "cache": {},
        "timings": {"send": 0, "wait": 100, "receive": 0},
        "request": {
            "method": method,
            "url": url,
            "httpVersion": "HTTP/1.1",
            "headers": headers_dict_to_list(req_headers),
            "cookies": [],
            "queryString": [],
            "headersSize": -1,
            "bodySize": -1,
        },
        "response": {
            "status": status,
            "statusText": "",
            "httpVersion": "HTTP/1.1",
            "headers": headers_dict_to_list(resp_headers),
            "cookies": [],
            "redirectURL": "",
            "headersSize": -1,
            "bodySize": body_size,
            "content": {
                "size": body_size,
                "mimeType": mime_type,
                "text": resp_body,
            },
        },
    }


def should_keep(url, domain):
    """Return True if the entry should be kept after filtering."""
    if not url:
        return False

    parsed = urlparse(url)
    host = parsed.hostname or ""
    path = parsed.path or ""

    # Domain filter
    if domain:
        if domain not in url:
            return False

    # Analytics blocklist: check if host matches or ends with a blocklist entry
    for blocked in ANALYTICS_BLOCKLIST:
        if host == blocked or host.endswith("." + blocked):
            return False

    # Static extension filter
    path_lower = path.lower()
    for ext in STATIC_EXTENSIONS:
        if path_lower.endswith(ext):
            return False

    return True


def parse_args():
    parser = argparse.ArgumentParser(
        description="Convert Chrome DevTools MCP or cmux browser network capture JSON to HAR 1.2."
    )
    parser.add_argument("--input", required=True, help="Path to chrome-requests.json or cmux-requests.json")
    parser.add_argument("--output", required=True, help="Output HAR file path")
    parser.add_argument("--domain", default="", help="Target domain to keep (e.g. example.com); other domains filtered out")
    return parser.parse_args()


def main():
    args = parse_args()

    try:
        with open(args.input, "r", encoding="utf-8") as f:
            raw_data = json.load(f)
    except FileNotFoundError:
        print(f"Error: input file not found: {args.input}", file=sys.stderr)
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"Error: invalid JSON in input file: {e}", file=sys.stderr)
        sys.exit(1)

    if not isinstance(raw_data, list):
        print("Error: input JSON must be an array of request entries", file=sys.stderr)
        sys.exit(1)

    fmt = detect_format(raw_data)

    entries = []
    for raw in raw_data:
        if fmt == "chrome":
            url = raw.get("url", "")
            entry = build_entry_from_chrome(raw)
        else:
            url = raw.get("request", {}).get("url", "")
            entry = build_entry_from_cmux(raw)

        if should_keep(url, args.domain):
            entries.append(entry)

    har = {
        "log": {
            "version": "1.2",
            "creator": {"name": "beacon-plugin", "version": "0.2.0"},
            "entries": entries,
        }
    }

    try:
        with open(args.output, "w", encoding="utf-8") as f:
            json.dump(har, f, indent=2)
    except OSError as e:
        print(f"Error: could not write output file: {e}", file=sys.stderr)
        sys.exit(1)

    print(f"Written {len(entries)} entries to {args.output}")


if __name__ == "__main__":
    main()
