#!/usr/bin/env bash
# pre-release-check.sh — 发布前本地检查，CI 同步执行
set -euo pipefail

PASS=0
FAIL=1
errors=0

_ok()  { echo "  [PASS] $1"; }
_err() { echo "  [FAIL] $1"; errors=$((errors + 1)); }
_sep() { echo ""; echo "=== $1 ==="; }

# ── 1. 文档校准 ────────────────────────────────────────────────
_sep "文档校准"

# 确认 trans file 已记录（不再是 trans doc）
if grep -q '`trans file`' README.md; then
  _ok "README.md 包含 trans file 命令"
else
  _err "README.md 未包含 trans file 命令"
fi

# 确认功能状态无遗留"即将支持"误标
if grep -E '`trans (text|file|config|doctor)`' README.md | grep -q '即将支持'; then
  _err "README.md 中已上线命令仍标注为「即将支持」"
else
  _ok "README.md 功能状态无误标"
fi

# CHANGELOG Unreleased 不为空
if grep -q '## \[Unreleased\]' CHANGELOG.md; then
  _ok "CHANGELOG.md 包含 [Unreleased] 章节"
else
  _err "CHANGELOG.md 缺少 [Unreleased] 章节"
fi

# ── 2. 敏感信息扫描 ────────────────────────────────────────────
_sep "敏感信息扫描"

# 扫描目标：已跟踪的所有文本文件（排除 .git）
SCAN_TARGET=$(git ls-files | grep -v '^\.git')

# 真实 Key / Token（排除占位符和注释）
if echo "$SCAN_TARGET" | xargs grep -rn \
    -iE '(api_key|secret|token|password)\s*[=:]\s*[^<"'"'"'\s]{8,}' \
    2>/dev/null \
  | grep -v -E '(your_api_key|<token>|example|placeholder|#)'; then
  _err "发现疑似真实 API Key / Token"
else
  _ok "未发现真实 API Key / Token"
fi

# 内网 IP
if echo "$SCAN_TARGET" | xargs grep -rn \
    -E '(10\.[0-9]+\.[0-9]+\.[0-9]+|172\.(1[6-9]|2[0-9]|3[01])\.[0-9]+\.[0-9]+|192\.168\.[0-9]+\.[0-9]+)' \
    2>/dev/null; then
  _err "发现内网 IP 地址"
else
  _ok "未发现内网 IP 地址"
fi

# 手机号（11 位，1 开头）
if echo "$SCAN_TARGET" | xargs grep -rn \
    -E '\b1[3-9][0-9]{9}\b' \
    2>/dev/null; then
  _err "发现疑似手机号"
else
  _ok "未发现手机号"
fi

# 非公开邮箱（公开联系邮箱豁免）
if echo "$SCAN_TARGET" | xargs grep -rn \
    -E '\b[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\b' \
    2>/dev/null \
  | grep -v 'translate_api@baidu\.com'; then
  _err "发现非公开邮箱地址"
else
  _ok "未发现非公开邮箱"
fi

# ── 3. 安全审查 ────────────────────────────────────────────────
_sep "安全审查"

# 禁止提交 .env 文件
if echo "$SCAN_TARGET" | grep -q '\.env'; then
  _err "发现 .env 文件被跟踪，请从 git 移除"
else
  _ok ".env 文件未被跟踪"
fi

# 禁止提交私钥 / 证书
if echo "$SCAN_TARGET" | grep -qE '\.(pem|key|p12|pfx)$'; then
  _err "发现私钥或证书文件被跟踪"
else
  _ok "无私钥或证书文件"
fi

# 检查 CLAUDE.md 不入库
if echo "$SCAN_TARGET" | grep -q '^CLAUDE\.md$'; then
  _err "CLAUDE.md 不应提交到仓库，请加入 .gitignore"
else
  _ok "CLAUDE.md 未被跟踪"
fi

# ── 4. commit 账号信息检测 ─────────────────────────────────────
_sep "commit 账号信息检测"

LAST_MSG=$(git log -1 --pretty=%B 2>/dev/null || true)

# 禁止 Co-Authored-By / Signed-off-by 含真实邮箱
if echo "$LAST_MSG" | grep -iE '(co-authored-by|signed-off-by):\s*.+@'; then
  _err "最近一次 commit message 含身份邮箱 trailer"
else
  _ok "commit message 无身份邮箱 trailer"
fi

# 禁止 commit message 含手机号
if echo "$LAST_MSG" | grep -E '\b1[3-9][0-9]{9}\b'; then
  _err "最近一次 commit message 含手机号"
else
  _ok "commit message 无手机号"
fi

# ── 结果汇总 ────────────────────────────────────────────────────
echo ""
echo "────────────────────────────────────"
if [ "$errors" -eq 0 ]; then
  echo "所有检查通过，可以发布。"
  exit $PASS
else
  echo "发现 $errors 个问题，请修复后重试。"
  exit $FAIL
fi
