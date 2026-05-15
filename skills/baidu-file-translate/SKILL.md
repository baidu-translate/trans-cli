---
name: baidu-file-translate
description: >
  Use this skill for file translation with trans-cli (Baidu LLM File
  Translation API). Covers the submit → poll → download async workflow,
  requestId lifecycle, Agent-safe polling strategy (submit+query loop, never
  rely on --wait alone), error handling for DOC_FAILED / WAIT_TIMEOUT / AUTH_FAILED,
  supported formats (docx/pdf/xlsx/pptx/html/txt/xml/md), and --download flag.
  Trigger on: trans file commands, file translation, document translation,
  requestId status polling, DOC_FAILED / WAIT_TIMEOUT errors, or any question
  about translating a file with trans-cli.
homepage: https://fanyi.baidu.com
metadata: {"clawdbot":{"emoji":"📄","requires":{"bins":["trans"],"env":["TRANS_API_KEY"]},"install":[{"id":"npm","kind":"npm","package":"@bdtrans/trans-cli","bins":["trans"],"label":"Install trans-cli (npm)"}]}}
---

# baidu-file-translate — Agent Reference

File translation is **async**. Always use the submit → poll loop below.
Never rely on `--wait` without a timeout — it may block indefinitely in an
Agent framework.

```
Step 1: trans file submit <file> --from auto --to en --json
        → exit ≠ 0 → handle by error code (see Error Handling)
        → exit 0   → record request_id from stdout

Step 2: every 5 s: trans file query <request_id> --json
        → exit ≠ 0              → handle error; DOC_FAILED = don't retry
        → exit 0, status=processing → keep polling
        → exit 0, status=done       → use file_url, or re-run with --download
```

Set an Agent-level timeout (e.g. 10 min). On WAIT_TIMEOUT, save the
request_id — the job is still running and can be resumed later.

---

## trans file submit \<file\>

```bash
trans file submit report.pdf --from zh --to en --json
trans file submit report.pdf --to en --reference "Use academic tone"
```

| Flag | Default | Description |
|------|---------|-------------|
| `--from` | auto | Source language (auto-detect) |
| `--to` | zh | Target language — **`auto` is not accepted** |
| `--reference` | — | Custom translation instruction, ≤ 1000 Unicode code points |
| `--trans-image` | false | Also translate text inside images |
| `--wait` | false | Block until done (always pair with `--wait-timeout`) |
| `--wait-timeout` | 0 (no limit) | Max wait time for `--wait` mode |

## trans file query \<requestId\>

```bash
trans file query REQ123 --json
trans file query REQ123 --download --output ./output/
```

| Flag | Default | Description |
|------|---------|-------------|
| `--download` | false | Download the translated file when done |
| `--output` | ./ | Download directory (used with `--download`) |
| `--wait` | false | Block until done |
| `--wait-timeout` | 0 (no limit) | Max wait time for `--wait` mode |

---

## JSON Contract

**submit success (stdout):**
```json
{"request_id": "REQ123", "status": "submitted"}
```

**query — in progress (stdout):**
```json
{"request_id": "REQ123", "status": "processing", "name": "report.pdf", "from": "zh", "to": "en"}
```

**query — done (stdout):**
```json
{"request_id": "REQ123", "status": "done", "file_url": "https://...", "char_count": 1000, "amount": 70}
```

With `--download`, the done response gains:
```json
{"local_path": "/absolute/path/to/report_en.pdf"}
```

**error (stderr, exit ≠ 0):**
```json
{"code": "AUTH_FAILED", "message": "...", "help_url": "https://fanyi-api.baidu.com/manage/apiKey"}
```

`help_url` is omitted when not applicable.

---

## Error Handling

```
exit ≠ 0
├── CONFIG_MISSING (exit 2) → guide user to set TRANS_API_KEY
├── AUTH_FAILED    (exit 2) → key invalid/expired; check fanyi-api.baidu.com/manage/apiKey
├── QUOTA_EXCEEDED (exit 3) → balance exhausted; recharge, then retry
├── RATE_LIMITED   (exit 3) → back off 30 s, then retry
├── NETWORK_ERROR  (exit 4) → check connectivity, retry
├── DOC_FAILED     (exit 3) → server-side failure; do NOT retry
├── INVALID_INPUT  (exit 1) → fix file path / format / --to value
└── WAIT_TIMEOUT   (exit 1) → job still running; save request_id and resume later
```

stderr carries errors only — there are no progress events on stderr.

---

## Supported Formats

docx / doc / pdf / xlsx / xls / pptx / ppt / html / htm / txt / xml / md

`file_url` expires after **30 days**.
