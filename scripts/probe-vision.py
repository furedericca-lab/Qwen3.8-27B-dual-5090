#!/usr/bin/env python3
"""Run a deterministic local PNG vision smoke through the Responses API."""

import argparse
import base64
import hashlib
import json
import pathlib
import re
import struct
import time
import urllib.error
import urllib.request
import zlib

from responses_api import output_text


SPECIAL_TOKEN_RE = re.compile(r"<\||<\s*/?think\s*>|<\s*(?:vision_start|vision_end|image_pad)\s*>", re.IGNORECASE)


def png_chunk(kind, payload):
    header = kind + payload
    return struct.pack(">I", len(payload)) + header + struct.pack(">I", zlib.crc32(header) & 0xFFFFFFFF)


def make_test_png(width=64, height=32):
    row = b"\x00" + (b"\xff\x00\x00" * (width // 2)) + (b"\x00\x00\xff" * (width // 2))
    raw = row * height
    return (
        b"\x89PNG\r\n\x1a\n"
        + png_chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0))
        + png_chunk(b"IDAT", zlib.compress(raw, 9))
        + png_chunk(b"IEND", b"")
    )


def write_json(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n")


def post(base_url, name, payload, run_dir):
    request_path = run_dir / f"{name}-request.json"
    response_path = run_dir / f"{name}-response.json"
    write_json(request_path, payload)
    data = json.dumps(payload, ensure_ascii=False).encode()
    request = urllib.request.Request(
        base_url.rstrip("/") + "/v1/responses",
        data=data,
        headers={"Content-Type": "application/json"},
    )
    status = 0
    headers = {}
    raw = b""
    try:
        with urllib.request.urlopen(request, timeout=1800) as response:
            status = response.status
            headers = dict(response.headers.items())
            raw = response.read()
    except urllib.error.HTTPError as exc:
        status = exc.code
        headers = dict(exc.headers.items())
        raw = exc.read()
    (run_dir / f"{name}-status.txt").write_text(f"http_status={status}\n")
    write_json(run_dir / f"{name}-headers.json", headers)
    try:
        result = json.loads(raw.decode())
    except (UnicodeDecodeError, json.JSONDecodeError):
        result = {"raw_response": raw.decode(errors="replace")}
    write_json(response_path, result)
    if status < 200 or status >= 300:
        raise SystemExit(f"FAIL: {name} HTTP status {status}; see {response_path}")
    return result


def validate_text(response, name):
    if response.get("status") != "completed":
        raise SystemExit(f"FAIL: {name} status={response.get('status')!r}")
    text = output_text(response).strip()
    if not text:
        raise SystemExit(f"FAIL: {name} has no output_text")
    if SPECIAL_TOKEN_RE.search(text):
        raise SystemExit(f"FAIL: {name} leaked special tokens")
    return text


def common_payload():
    return {
        "model": "default",
        "temperature": 0,
        "max_output_tokens": 128,
        "stream": False,
        "chat_template_kwargs": {"enable_thinking": False},
    }


def run_text(base_url, name, prompt, run_dir):
    payload = common_payload()
    payload["input"] = prompt
    response = post(base_url, name, payload, run_dir)
    return validate_text(response, name)


def run_vision(base_url, image_url, run_dir):
    payload = common_payload()
    payload["input"] = [{
        "role": "user",
        "content": [
            {
                "type": "input_text",
                "text": '只返回 JSON，识别图片左右两边的颜色：{"left":"...","right":"..."}',
            },
            {"type": "input_image", "image_url": image_url},
        ],
    }]
    response = post(base_url, "vision", payload, run_dir)
    text = validate_text(response, "vision")
    try:
        parsed = json.loads(text)
    except json.JSONDecodeError as exc:
        raise SystemExit(f"FAIL: vision output is not JSON: {text!r}") from exc
    if not isinstance(parsed, dict):
        raise SystemExit("FAIL: vision JSON output is not an object")
    left = str(parsed.get("left", "")).lower()
    right = str(parsed.get("right", "")).lower()
    left_ok = "red" in left or "红" in left
    right_ok = "blue" in right or "蓝" in right
    if not left_ok or not right_ok:
        raise SystemExit(f"FAIL: vision colors were left={left!r}, right={right!r}")
    return text, parsed


parser = argparse.ArgumentParser()
parser.add_argument("--base-url", default="http://172.30.0.214:8000")
parser.add_argument("--run-dir", type=pathlib.Path)
parser.add_argument("--sequence", action="store_true", help="run text -> image -> text")
args = parser.parse_args()

root = pathlib.Path(__file__).resolve().parents[1]
run_dir = args.run_dir or root / "evidence" / f"vision-smoke-{time.strftime('%Y%m%dT%H%M%SZ', time.gmtime())}"
run_dir.mkdir(parents=True, exist_ok=True)
png = make_test_png()
png_path = run_dir / "red-left-blue-right.png"
png_path.write_bytes(png)
image_url = "data:image/png;base64," + base64.b64encode(png).decode()
(run_dir / "image.sha256").write_text(hashlib.sha256(png).hexdigest() + "  red-left-blue-right.png\n")

summary = {
    "base_url": args.base_url,
    "image": {
        "path": str(png_path),
        "sha256": hashlib.sha256(png).hexdigest(),
        "bytes": len(png),
        "layout": "left half pure red, right half pure blue",
    },
    "sequence": args.sequence,
}
if args.sequence:
    summary["text_before"] = run_text(args.base_url, "text-before", "Reply with exactly READY.", run_dir)
    summary["vision_text"], summary["vision_json"] = run_vision(args.base_url, image_url, run_dir)
    summary["text_after"] = run_text(args.base_url, "text-after", "Reply with exactly TEXT_OK.", run_dir)
else:
    summary["vision_text"], summary["vision_json"] = run_vision(args.base_url, image_url, run_dir)

write_json(run_dir / "summary.json", summary)
print(json.dumps(summary, ensure_ascii=False, indent=2))
print(f"PASS: vision smoke retained in {run_dir}")
