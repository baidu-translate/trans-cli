# trans-cli

> 百度翻译 AI 命令行工具 — 支持 200+ 语种，终端、管道、JSON 输出开箱即用。

```bash
$ trans text "你好世界"
Hello World
```

---

## 目录

- [安装](#安装)
- [快速开始](#快速开始)
- [功能](#功能)
- [配置](#配置)
- [错误处理](#错误处理)
- [支持语种](#支持语种)
- [联系我们](#联系我们)

---

## 安装

**前置条件：百度翻译 AI API Key**

1. [注册并开通免费额度](https://fanyi-api.baidu.com/api/trans/product/desktop)
2. 在[控制台](https://fanyi-api.baidu.com/manage/apiKey)获取 API Key

**安装 CLI**

```bash
npm install -g @bdtrans/trans-cli
```

> 要求 Node.js 18+

---

## 快速开始

```bash
# 1. 设置 API Key（环境变量方式）
export TRANS_API_KEY=your_api_key_here

# 2. 验证配置
trans doctor

# 3. 翻译
trans text "你好世界"
```

也可以通过配置文件持久化：

```bash
trans config init
trans config set api_key your_api_key_here
```

---

## 功能

| 子命令 | 描述 | 状态 |
|--------|------|------|
| `trans text` | 文本翻译，支持 200+ 语种互译 | 可用 |
| `trans config` | 初始化和管理配置 | 可用 |
| `trans doctor` | 自检：API Key、网络连通性、账户状态 | 可用 |
| `trans doc` | 文档翻译 | 即将支持 |
| `trans image` | 图片翻译 / OCR | 即将支持 |
| `trans audio` | 语音翻译 | 即将支持 |

### 使用示例

```bash
# 基本翻译（自动检测源语言）
trans text "你好世界"

# 指定目标语言
trans text "Hello World" --to zh

# 管道用法
echo "今天天气真好" | trans text

# JSON 输出（适合脚本集成）
trans text "你好" --json
```

---

## 配置

优先级（由高到低）：`--api-key` flag > `TRANS_API_KEY` 环境变量 > `~/.trans-cli/config.json`

```json
{
  "api_key": "your_api_key"
}
```

---

## 错误处理

成功结果写入 `stdout`，所有错误写入 `stderr`，适合管道和脚本集成。

### 退出码

| 退出码 | 含义 |
|--------|------|
| `0` | 成功 |
| `1` | 参数错误、输入为空 |
| `2` | 鉴权或配置问题 |
| `3` | API 业务错误（余额不足、频率超限等） |
| `4` | 网络错误 |

### `--json` 模式错误码

| `code` | 含义 | 解决方法 |
|--------|------|---------|
| `CONFIG_MISSING` | API Key 未配置 | 设置 `TRANS_API_KEY` 环境变量 |
| `AUTH_FAILED` | Key 无效或未开通服务 | 检查 Key 及服务开通状态 |
| `QUOTA_EXCEEDED` | 账户余额不足 | [前往充值](https://fanyi-api.baidu.com/manage/account) |
| `RATE_LIMITED` | 请求过于频繁 | 降低调用频率或升级套餐 |
| `NETWORK_ERROR` | 网络不可达 | 检查网络连接 |
| `INVALID_INPUT` | 输入为空或非法 | 检查输入内容 |
| `INVALID_LANGUAGE` | 不支持的语言代码 | 查阅[支持语种列表](https://fanyi-api.baidu.com/doc/21) |
| `API_ERROR` | 其他 API 错误 | 重试，或联系支持 |

---

## 支持语种

支持 200+ 语种互译，覆盖 4 万多个语言方向，源语言支持自动检测。

完整语种列表：[fanyi-api.baidu.com/doc/21](https://fanyi-api.baidu.com/doc/21)

---

## 联系我们

问题反馈或商务合作：[translate_api@baidu.com](mailto:translate_api@baidu.com)
