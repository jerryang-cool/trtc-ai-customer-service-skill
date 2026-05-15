---
name: trtc-ai-customer-service
version: 1.0.0
description: |
  Build an AI e-commerce customer service Web app with TRTC ConversationAI — voice/text dual-mode, trilingual, digital avatar optional.
  基于 Tencent RTC Conversational AI 快速构建 AI 电商客服 Web 应用 — 语音/文字双模、三语国际化、数字人可选。
---

# TRTC AI 电商客服 Skill

本 Skill 指导你基于腾讯云 TRTC ConversationAI 能力，快速构建 AI 电商客服 Web 应用。
场景预置了订单查询、退换货处理、商品咨询、物流追踪、优惠活动等电商业务模块。

## 触发条件

当用户提到以下任何场景时使用此 Skill（EN or CN）：
- "AI customer service" "smart customer support" "voice bot" "voice agent" "chat bot"
- "e-commerce support" "online store assistant" "shopping assistant" "after-sales service"
- "build a customer service app" "customer service demo" "support chatbot"
- "real-time voice chat" "voice-to-text conversation" "ASR + LLM + TTS"
- "TRTC conversation" "ConversationAI" "TRTC + AI" "TRTC + LLM"
- "digital human" "virtual agent" "avatar customer service"
- "StartAIConversation" "StopAIConversation" "ControlAIConversation"
- "order inquiry" "returns and exchanges" "shipping tracking" "product consultation"
- "AI 客服" "智能客服" "语音客服" "电商客服" "商城客服" "售后客服"
- "做一个客服系统" "搭建客服" "客服机器人" "数字人客服"
- "订单查询" "退换货" "物流追踪" "商品咨询"

即使用户只是简单说 "help me build an AI customer service" 或 "帮我做个 AI 客服" 也应触发。

## 架构总览

```
浏览器 (TRTC Web SDK v5)
     ↕ 音频 (WebRTC) + 自定义消息 (字幕/状态/文字输入)
TRTC Room
     ↕ 内置 ASR → LLM → TTS → 推回房间
TRTC AI Bot (云端)
     ↕ OpenAPI (TC3-HMAC-SHA256)
Flask 后端 (app.py)  —— 仅 UserSig 签发 + OpenAPI 中转
```

| 平面 | 通道 | 内容 |
|------|------|------|
| **媒体面** | WebRTC 音频流 | 用户麦克风 ↔ TRTC 房间 ↔ AI Bot |
| **控制面** | HTTP `/action` | 前端 → Flask → TRTC OpenAPI |
| **数据面** | TRTC 自定义消息 | 字幕(10000) / AI 状态(10001) / 文字输入(20000) / 打断(20001) |

后端**完全不调用 LLM**——LLM 由 TRTC 云端 AI Bot 内部调用，后端只负责签发 UserSig 和中转 OpenAPI 请求。

---

## 工作流程

根据用户需求选择合适的路径。

### 路径 A：从零创建新项目（推荐）

#### Step 1: 生成项目

运行脚手架脚本：

```bash
python {baseDir}/scripts/scaffold.py <项目目录> [--name <商城名称>] [--name-en <English name>] [--lang <zh|en|both>]
```

- `{baseDir}`：本 Skill 所在目录的绝对路径（由 Agent 自动替换为实际路径）
- `--name`：商城名称（默认"云尚商城"），用于中文/粤语的 SystemPrompt、欢迎语、告别语、前端 UI
- `--name-en`：英文商城名称（默认自动推导：中文名时为"CloudShop Mall"，英文名时与 `--name` 相同），用于英文 SystemPrompt、英文欢迎语/告别语
- `--lang`：语言支持范围，`zh`=仅中文、`en`=仅英文、`both`=中英粤三语（默认 `both`）
- 脚本自动生成全部文件：后端 + 前端 + 头像 + 鉴权库 + 启动脚本，无需手动复制任何文件

**检查点**：确认用户看到 `✅ 电商客服项目已生成到: xxx` 和完整文件列表，再继续。

#### Step 2: 配置密钥

引导用户运行启动脚本（**根据操作系统自动选择**：macOS/Linux 用 `./start.sh`，Windows 用 `start.bat`），首次运行会进入交互式引导：
- [1/4] 腾讯云 API 密钥 → [控制台获取](https://console.intl.cloud.tencent.com/cam/capi)
- [2/4] TRTC 应用凭据 → [控制台获取](https://console.trtc.io/app)
- [3/4] LLM 配置 → 参考 [LLM 配置指南](https://trtc.io/document/68338?product=conversationalai)，根据所选 LLM 服务商填入：
  - `LLMConfig.LLMType`：协议类型（如 `openai`）
  - `LLMConfig.Model`：模型名称（因服务商而异）
  - `LLMConfig.APIUrl`：API 端点 URL（因服务商而异）
  - `LLMConfig.APIKey`：API 密钥
- [4/4] AI 客服角色（品类 + 语气） → 可选定制，三语同步

**检查点**：确认用户看到 `✓ 所有密钥已配置完成！`。如果有跳过项，提醒手动编辑 `env.yaml`。

> **提示用户**：以上 4 步为最小必填项，启动成功后还有丰富的可定制选项（商城名称、欢迎语、TTS 音色、关键词等），详见 Step 4。

#### Step 3: 启动验证

启动脚本会自动创建虚拟环境、安装依赖、启动服务。

**验证标准**（告知用户逐项确认）：
1. 终端显示 `🚀 启动 TRTC AI 智能客服` + 访问地址（公网服务器会自动检测公网 IP 并启用 HTTPS，显示 `https://<公网IP>:8080`；本地开发则显示 `http://localhost:8080`）
2. 浏览器打开页面 → 能看到客服头像选择界面
3. 选择客服 → 点击"开始对话" → 听到 AI 播报欢迎语
4. 说话或打字 → AI 能正常回复

#### Step 4: 定制（可选）

启动成功后，**主动告知用户**以下所有可定制项，引导按需修改：

| 定制项 | 修改位置 | 说明 |
|--------|---------|------|
| **商城名称/品牌** | scaffold 的 `--name` 参数 | 一键替换全链路品牌文案（三语 SystemPrompt、欢迎语、告别语、前端 UI） |
| **部署区域** | `env.yaml` → `Deployment.Region` | `intl`=国际站（默认）/ `cn`=中国大陆，影响 TRTC OpenAPI 端点 |
| **AI 话术 / SystemPrompt** | `env.yaml` → `LLMConfig.SystemPrompt` / `SystemPromptYue` / `SystemPromptEn` | 三语独立配置，可定制角色人设、回复风格、业务范围 |
| **欢迎语** | `env.yaml` → `WelcomeMessage.zh` / `yue` / `en` | AI 进房后首条播报消息 |
| **告别语** | `env.yaml` → `FarewellMessage.zh` / `yue` / `en` | 关键词触发结束时播报 |
| **LLM 模型** | `env.yaml` → `LLMConfig.Model` / `APIUrl` / `APIKey` | 参考 [LLM 配置指南](https://trtc.io/document/68338?product=conversationalai) |
| **TTS 音色** | `config_loader.py` → `TTS_VOICE_MAP` | 参考 [TTS 音色配置指南](https://trtc.io/document/79682?product=conversationalai) |
| **商品/订单数据** | `static/mock-orders.json` | JSON 格式，含三语名称和价格，可替换为真实数据 |
| **数字人** | `env.yaml` → `AvatarConfig` 三项 | 三项全填启用，否则纯语音模式 |
| **对接真实订单系统** | 参考 `references/frontend-guide.md` | 替换 mock 数据为真实 API 调用 |
| **远程/公网部署** | `./start.sh --https` | 自动生成自签证书启用 HTTPS（WebRTC 麦克风要求） |
| **生产部署** | Flask → Gunicorn + Nginx | 正式证书 + `/action` 接口鉴权 |

### 路径 B：为现有项目集成 TRTC AI 对话

#### Step 1: 了解现有架构

确认用户的技术栈（后端语言、前端框架），以及要集成的能力范围。

#### Step 2: 按需提供指导

读取对应的参考文档并指导：

| 需求 | 读取文档 | 关键指导内容 |
|------|----------|-------------|
| 后端集成 | `references/architecture.md` | 5 个 Action 处理器实现、TRTC OpenAPI 调用、UserSig 签发 |
| 配置体系 | `references/config-guide.md` | env.yaml 结构、TTS/STT 映射、Region 切换 |
| 前端集成 | `references/frontend-guide.md` | TRTC Web SDK 进房流程、消息协议、关键词检测、字幕处理 |

#### Step 3: 验证集成

引导用户完成最小可用流程：进房 → 开麦 → StartAIConversation → 听到欢迎语。

---

## 常见问题排查

当用户遇到问题时，按以下清单排查：

| 现象 | 原因 | 解决方案 |
|------|------|----------|
| scaffold.py 报错退出 | Python 版本或参数错误 | 确认 Python 3.8+；检查输出目录路径是否合法 |
| `start.sh` 报 Python 版本不够 | Python < 3.8 | 安装 Python 3.8+ |
| venv 创建失败 | 缺少 `python3-venv` 包 | Ubuntu/Debian: `sudo apt install python3-venv`；macOS 自带 |
| 依赖安装失败 | 网络问题 | `start.sh` 会自动 fallback 官方源；或手动 `pip install -r requirements.txt` |
| `env.yaml` 解析报错 | YAML 缩进或格式错误 | 用在线 YAML 校验器检查；常见：冒号后缺空格、中文引号 |
| 页面打开空白 | 静态文件缺失 | 确认 `static/app.js` 和 `templates/customer_service.html` 存在 |
| 点"开始对话"无反应 | 密钥未填或填错 | 检查 `env.yaml` 中 SDKAPPID 不为 0、SECRET_ID/KEY 正确 |
| 点"开始对话"提示**进房失败** | TRTC 进房参数异常 | 检查 `SDKAPPID` 是否正确填写；UserSig 是否校验失败（核对 `TRTC.SECRET`） |
| 说话**无任何响应**（语音不可用） | 浏览器麦克风权限未授予或设备异常 | 检查浏览器地址栏麦克风权限；测试系统设备：录音机能否录到声音 |
| 仅显示**本地字幕，AI 无回应** | LLM 服务异常 | 检查 `LLMConfig.APIKey` / `APIUrl` / `Model` 是否正确；确认 LLM 账户额度充足 |
| AI 有字幕但**无语音播报** | TTS 服务异常 | 核对 TTS 参数（VoiceId、Language）；确认 TTS 套餐包资源充足 |
| LLM **长时间不回复**或超时报错 | LLM Timeout | 调大 `env.yaml` → `LLMConfig.Timeout`（如 5.0 → 10.0） |
| 进房成功但无欢迎语 | LLM APIKey 错误或 TRTC 服务未开通 | 检查 `LLMConfig.APIKey`；确认 TRTC 控制台已开通 AI 对话能力 |
| 非 localhost 访问**无声音或麦克风不可用** | WebRTC 安全策略要求 HTTPS | 运行 `./start.sh --https` 自动生成自签证书并启用 HTTPS；首次访问浏览器点击"高级→继续前往" |
| 公网 IP 访问**页面打不开** | 防火墙未放行端口 | 确认服务器防火墙/安全组已放行 8080 端口（TCP）|
| 端口 8080 被占用 | 其他进程占用 | `start.sh` 会自动检测并询问是否终止 |
| 浏览器控制台报 CORS 错误 | 前后端不同源 | 确保前端页面由 Flask 提供（同源）；不要用 `file://` 打开 HTML |

---

## 核心设计模式

> 详见 `references/architecture.md`

| 模式 | 要点 |
|------|------|
| StopAfterPlay 一站式结束 | `ControlAIConversation` + `StopAfterPlay=true`，TTS 播完自动停止 |
| 文字输入跳过 ASR | `type: 20000` 自定义消息直送 LLM |
| 中英文词边界匹配 | 中文用非中文字符边界，英文用 `\b` |
| 增量/累积自适应字幕 | 自动检测 TRTC 下发模式 |
| 机器人退房 + AI 状态双保险 | `REMOTE_USER_LEAVE` + `state=5` |
| 数字人可选降级 | `AvatarConfig` 三项齐全启用，否则纯语音 |

## 后端 API

统一通过 `POST /action` + `Action` 请求头区分：

| Action | 职责 |
|--------|------|
| `join` | 签发 UserSig（用户/机器人/数字人），下发关键词/告别语/数字人开关 |
| `StartAIConversation` | 组装参数调用 TRTC OpenAPI 启动 AI 对话 |
| `StopAIConversation` | 兜底停止（正常走 FarewellAndStop） |
| `FarewellAndStop` | 推送告别语 + StopAfterPlay 一站式结束 |
| `TransferAndStop` | 推送转接提示语 + StopAfterPlay 一站式结束 |

## 技术栈

| 层 | 技术 |
|----|------|
| 后端 | Python 3.8+ / Flask / tencentcloud-sdk-python |
| 前端 | 原生 JS / TRTC Web SDK v5 / CSS 变量系统 |
| AI 引擎 | TRTC ConversationAI（ASR + LLM + TTS 全链路云端） |
| 鉴权 | HMAC-SHA256 UserSig |
| 配置 | YAML（envyaml 库） |

## 安全注意事项

- `env.yaml` 包含密钥，必须加入 `.gitignore`，切勿提交
- UserSig 在服务端签发，密钥不暴露给前端
- 生产环境必须添加 `/action` 接口鉴权
- 前端使用 `escapeHtml()` 防止 XSS
- 非 localhost 部署必须使用 HTTPS（WebRTC 安全策略要求）
