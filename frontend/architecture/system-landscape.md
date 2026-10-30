# 系统画像：{项目名} 前端（{端形态}）

> **AI Skill 上下文资产**（`frontend/architecture/system-landscape.md`）。前端全部 Skill 的项目层事实唯一定义处。  
> **接入必填**：带「示例」标注内容来自源项目（C 端微信小程序），接入时整节替换为你的前端工程事实。

---

## 一、产品全景

一段话说清前端产品做什么：目标用户、核心用户旅程（从进入到结束的主流程）、本仓库职责边界（哪些页面/能力在前端，哪些依赖后端）。

## 二、系统边界

| 系统 | 一句话定位 | 与本仓库关系 |
|------|-----------|-------------|
| **{后端仓库}** | 提供 OpenAPI 契约与运行环境 | 经 handoff 同步契约；前端只消费不定义 |
| （示例）设计稿源（蓝湖/Figma） | UI 真相 | 拆卡时对照原型；有 MCP 工具可自动取图 |
| （示例）登录/认证服务 | 签发 Token | 前端只做 Token 存取与刷新 |

## 三、技术栈与目录结构

### 3.1 技术栈

| 分类 | 技术 | 说明 |
|------|------|------|
| （示例）框架 | 微信小程序原生 | — |
| （示例）状态 | 页面 data + 全局 store | — |
| （示例）测试 | Jest（services/utils 单测） | 页面/组件层测试策略接入时定 |

### 3.2 目录结构

写清工程目录约定（页面/组件/服务/工具落点），feature-coding 按此落文件。（示例：微信官方目录结构 `pages/ components/ services/ utils/ api/`。）

### 3.3 分包策略（如有）

主包/分包划分与体积预算。

## 四、集成与契约

### 4.1 API 契约（唯一真相）

| 项 | 值 |
|----|-----|
| 契约文件 | `docs/handoff/openapi/{后端服务标识}.yaml`（从后端同步，**前端不修改**） |
| 契约版本 | `docs/handoff/VERSION`（tag 或 commit SHA） |
| baseUrl | （示例）`/api/v1/{项目}/app`（与 OpenAPI `servers` 一致） |
| 成功判据 | `response.code === 200`（以 body 为准，不只看 HTTP 状态码） |
| 鉴权 | （示例）`Authorization: Bearer <token>` |

**当前后端已发布 operation**（随 handoff 更新；拆卡时只选本页相关项）：

| operationId | Method | Path（相对 baseUrl） | 后端 Story |
|-------------|--------|---------------------|------------|
| （示例）`searchLots` | GET | `/lots` | S-001 |

### 4.2 鉴权流程

用 text 图画清：登录拿 Token → 存储 → 请求拦截注入 → 401 处理链路。

### 4.3 错误码分层（与后端对齐）

| 层级 | 来源 | 前端处理 |
|------|------|----------|
| （示例）系统层 | 后端公共库 `ErrorCode`（401 等） | 重新登录 / 通用提示 |
| （示例）BFF 守卫层 | 400 段 | Toast |
| （示例）域业务层 | 按号段路由（见后端画像 §3.7） | 按 Story AC 展示 `message` |

详见后端 [../backend/reference/exception-and-result.md](../../backend/reference/exception-and-result.md)（若两线同用本模板）。

---

## 五、AI Native 工程资产

| 层级 | 路径 | 职责 |
|------|------|------|
| 执行层 | `skills/frontend-*/SKILL.md` | Agent 运行时步骤 |
| 横切层 | `rules/*.md` | 编码与文档规范 |
| 样例层 | `docs/**/_golden/` | Few-shot 标准样例 |
| 配置 | `config/current-sprint` | 当前迭代 |
| 词表 | `glossary/domain-glossary.md` | 术语一致 |

## 六、与后端流水线的协作

```text
后端：story-splitting → detail-design → OpenAPI 定稿 → tag
              ↓
        发布 handoff 包（OpenAPI + VERSION + Story 摘要/stories-index）
              ↓
前端：同步 docs/handoff/ → frontend-story-splitting → frontend-detail-design → frontend-feature-coding
              ↓
        联调（同一 OpenAPI tag 与后端环境一致）
```

**原则**：同一迭代内 OpenAPI 先定稿，再跑前端详设；接口/字段/错误码变更**必须先改后端 OpenAPI**，再同步本仓——前端仓永远不直接改契约。

---

## 变更记录

| 日期 | 变更 |
|------|------|
| （示例）2026-08-01 | 初版画像 |
