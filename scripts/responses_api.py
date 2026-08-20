"""Small HTTP and response helpers for the local OpenAI Responses API."""

import json
import urllib.request


def request_text(url, payload=None, timeout=1800):
    data = None if payload is None else json.dumps(payload).encode()
    headers = {} if payload is None else {"Content-Type": "application/json"}
    req = urllib.request.Request(url, data, headers)
    with urllib.request.urlopen(req, timeout=timeout) as response:
        return response.read().decode()


def request(url, payload=None, timeout=1800):
    return json.loads(request_text(url, payload, timeout))


def require_completed(response, context="response"):
    status = response.get("status")
    if status != "completed":
        raise SystemExit(
            f"FAIL: {context} status={status!r} "
            f"incomplete_details={response.get('incomplete_details')!r}"
        )
    return response


def output_items(response, item_type=None):
    items = response.get("output", [])
    if not isinstance(items, list):
        return []
    if item_type is None:
        return items
    return [item for item in items if item.get("type") == item_type]


def output_text(response):
    parts = []
    for item in output_items(response):
        if item.get("type") == "output_text":
            parts.append(item.get("text", ""))
            continue
        if item.get("type") != "message":
            continue
        for content in item.get("content", []):
            if content.get("type") == "output_text":
                parts.append(content.get("text", ""))
    return "".join(parts)
