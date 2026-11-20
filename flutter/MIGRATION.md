# MIGRATION：Flutter 线接入指南

本线与前端线采用相同的六步接入流程和两个确认点：handoff → 画像 → 锚点替换 → Golden → 分发 → 裁剪。日常开发见 [USAGE.md](USAGE.md)。

> 本线面向 Flutter Android / iOS。MVVM、状态管理、路由和存储基线见[画像 §3.1](architecture/system-landscape.md)；存量工程记录实际选型，接入工作流不自动迁移应用架构。
> AI 按步骤执行，已有明确决策不重复询问；到人工介入点自报「第 X/2 个确认点」。

## 快速导航

| 阶段 | 内容 |
|------|------|
| [§一.1](#1-获取-handoff-包) | 获取 handoff 包 |
| [§一.2](#2-填写-flutter-画像) | 填写 Flutter 画像 |
| [§一.3](#3-替换项目锚点) | 替换项目锚点 |
| [§一.4](#4-重写-golden) | 重写 Golden |
| [§一.5](#5-分发到-agent) | 分发到 Agent |
| [§一.6](#6-工作流裁剪) | 工作流裁剪 |
| [§二](#二接入后验收) | 接入后验收 |
| [§三](#三旧布局迁移与模板升级) | 旧布局迁移与模板升级 |

## 一、接入步骤

前置：按仓库根 [README.md](../README.md)「快速开始」把模板（不带 `.git`）放入项目根 `AI-Native/`，用 [AGENTS 模板](../templates/AGENTS.template.md)生成或整合项目入口，只保留接入的线。Flutter 开发路由到 `AI-Native/flutter/AGENTS.md`。已有项目说明、业务代码和文档保持各自归属。

### 1. 获取 handoff 包

1. 向后端取得 OpenAPI 快照及版本 pin（tag 或 commit SHA）。
2. 放入 `docs/handoff/openapi/{后端服务标识}.yaml` 与 `docs/handoff/VERSION`；可附 Story 摘要和 `stories-index.md`。详见 [handoff 约定](docs/handoff/README.md)。
3. Flutter 只消费契约；接口变更先由后端更新 OpenAPI，再同步快照，不在本线改协议。

**涉及后端但 handoff 缺失时向用户提问**，沿用前端的两个选择：

- **① 现在向后端团队获取**（推荐）。
- **② 先接入、后补契约**：画像 §四标「handoff 待补」，`VERSION` 写 `TBD`；契约文件、版本、URL、成功判据、鉴权和错误码映射作为一组待补项，整体跳过相关替换。接入可以完成，网络 Story 的拆卡、详设和编码仍需等待真实契约，不能用示例或 mock 代替后端发布。

**纯 UI、本地或仅原生 SDK 功能**：确认不调用业务后端后，卡上的契约、版本和 API 范围填 `N/A`，可继续三阶段；不为此伪造 OpenAPI 或创建 VERSION。原生 SDK 仍需真实能力、权限和回调约定。支付等含服务端下单/查单的功能不属于此豁免。项目同时有网络功能时，保留项目级待补项，仅无后端依赖的卡豁免。

**handoff 到达后**：同步快照和真实 VERSION → 填画像 §四 → 补执行契约替换组 → 重跑 §一.3 的残留检查和 §二的网络卡验收。不能只把 `TBD` 改成版本号而不核对快照。

### 2. 填写 Flutter 画像

项目事实只维护在 [architecture/system-landscape.md](architecture/system-landscape.md)，[词表](glossary/domain-glossary.md)与后端领域术语对齐。

| 项目形态 | AI 执行 |
|----------|---------|
| 已有 Flutter 工程 | 扫描 `pubspec.yaml` / `pubspec.lock`、SDK 配置、`lib/`、路由、请求层、Android/iOS 工程与 CI，起草实际选型、组件目录、鉴权及构建测试命令；不以模板默认值覆盖已有选型 |
| 从 0 开始 | 按画像逐节访谈，确定应用根、目标平台、技术基线、组件/路由、原生能力和验证环境；每节已拍板内容直接纳入草案 |

重点：§3.1 技术与版本、§3.2 含 `pubspec.yaml` 的应用根及现有组件、§3.3 环境与构建变体、§四契约与鉴权、§六协作机制。测试账号只登记取得方式，不写密钥。

画像草案与下一步映射表**合并确认一次**；不额外设置画像确认点。

### 3. 替换项目锚点

| # | 介入时机 | AI 随附结果 | 人做什么 |
|---|----------|------------|----------|
| 1 | 画像草案 + 锚点映射表就绪 | 应用根、技术栈、平台、组件、契约对齐；源值 → 目标值及待补项 | 一次确认画像和映射 |
| 2 | 六步完成后的验收报告 | 校验器结果、残留/表外形态、Golden 改动、三阶段试跑结果、待补项及未验证项 | 确认残留清零，或仅剩已声明的待补项 |

**AI 任务书**：

1. 读代码和适用的 handoff，提交画像草案及映射提案。**→ 人工介入点 1**。
2. 确认后替换本线 `skills/`、`rules/` 的执行锚点；长路径先处理。同步画像、词表、`config/current-sprint`；与后端共用迭代时保持一致，独立接入按项目约定。handoff 待补时跳过整个契约组。
3. 执行下方检查并语义扫描表外的具体路径、系统名、号段和平台配置；继续 §4–6，再汇总 §二验收报告。**→ 人工介入点 2**。不要在 Golden 和分发之前提前宣布验收完成。

| 类别 | 源值/识别方式 | 替换依据 |
|------|----------------|----------|
| 契约文件、服务标识 | `docs/handoff/openapi/booking-bff-app.yaml`、`{后端服务标识}.yaml` | handoff 实际文件与画像 §4.1 |
| URL 与响应语义 | `/api/v1/booking/app`；执行指令中的具体成功码、鉴权方式、错误码 | 画像 §四与实际 schema/examples；待补时不猜 |
| 迭代号 | `2026-S01`、`2026-S02` | `config/current-sprint` 与项目迭代约定 |
| 应用路径与平台 | 应用根、`lib/` 分层、原生适配目录、构建测试命令 | 画像 §3.1–3.3；分发后工作流链接与应用路径分别解析 |

**替换边界**：契约执行路径等必须替换；页面/组件示例名、业务示例、Golden 文件名和「模板版说明」保留，Golden 内容在 §4 重写。Flutter 规则已通过画像引用技术选型，不引入前端小程序的 `wx.*`、分包或后端公共库。不要全局把 `200`、`401` 或库名替换成另一值；区分 HTTP 状态、业务码和教学示例，按契约逐项处理。

**验收命令**（项目根）：

```bash
# 按映射表选“未被目标选用”的源值；命中逐条分类，不盲删示例。
rg -n 'booking-bff-app|/api/v1/booking' AI-Native/flutter/skills AI-Native/flutter/rules
# 预期无未处理的执行锚点；待补项与保留的教学示例分别列出。
rg -n '2026-S' AI-Native/flutter/config AI-Native/flutter/skills AI-Native/flutter/rules
# config 与工件执行路径用目标值；正文示例可保留。
bash AI-Native/flutter/scripts/validate-skills.sh --quiet-tick
```

### 4. 重写 Golden

- 从真实需求及适用的契约选一张小卡，重写 `docs/requirements/_golden/` 与 `docs/design/_golden/` 的配套 STORY-Flutter / DD-Flutter。保持文件名模式及结构；若改名，同步引用和校验清单。
- 核对同一 AC 可追到契约/本地行为、设计稿、状态、双端差异和测试；随附「3 处关键改动 + 建议抽查 1 份」。
- 证据不足时请用户指定真实场景；待补网络契约时可选真实本地卡演示，网络样例仍列待补，不用虚构协议凑验收。

### 5. 分发到 Agent

AI 探测当前 Agent 的技能/规则目录并做格式适配。分发方式和 §6 裁剪选项合并处理，已有明确选择直接沿用；仅有多 Agent 需求时讨论多份分发。

- `AI-Native/flutter/` 是维护源。分发 `skills/`、`rules/`、`templates/` 时，保留它们对本线入口、画像、Golden 等资产的可达引用；符号链接或副本需按真实位置验证，不能只复制三个 SKILL.md。
- Flutter 运行资产独立于后端和前端目录；流程说明中的根接入指南属于安装期导航，不是业务开发依赖。
- 从项目根验证入口能找到三个 Skill；启动时扫描技能的 Agent 用新会话验证发现结果。命令未注册时可直接指定 SKILL.md 路径。
- 本线无 hooks；应用质量检查使用画像登记的 CI 命令。无需因接入模板自动安装后端 hooks。

### 6. 工作流裁剪

- 默认保留三段 Skill 和独立代码审查，与前端相同；不增设 Flutter 专属 Story/DD 审查阶段或单独的 test-spec-alignment Skill。
- 存储、原生桥接、设计和发布规则按卡涉及的能力加载；Flutter 的 Widget / integration_test 属于编码阶段验证，不新增流水线环节。
- 如确需删除资产，同步清理引用、入口及校验器的必需资产清单，再跑校验；不要只删文件。

## 二、接入后验收

1. 本线校验器 **PASSED**：`bash AI-Native/flutter/scripts/validate-skills.sh --quiet-tick`，相对链接可达。
2. 真实小卡走通 flutter-story-splitting → flutter-detail-design → flutter-feature-coding；按编码 Skill 完成自动检查和适用的独立代码审查。在画像 §3.2 的应用根执行格式检查、`flutter analyze`、`flutter test` 及所需设备验证，保存实际结果。
3. 核对 Story / DD / 审查报告落在 `AI-Native/flutter/docs/{requirements,design,reviews}/{迭代}/`，代码和测试在应用根；网络三段引用同一真实快照、VERSION 和 operationId。
4. handoff 待补时网络卡试跑延后，报告区分「模板接入通过」与「网络开发待补」；纯本地项目以本地卡验收。设备未验证项按[审查规则](rules/code-review.md)记录，不能写成通过。

汇总以上结果、源值残留和全部待补项后，到**第 2/2 个确认点**。

## 三、旧布局迁移与模板升级

旧版若将工作流平铺工程根，先在项目副本盘点同名目录，把工作流资产按相对路径归入 `AI-Native/flutter/`。共用 `docs/`、`scripts/` 逐项判断归属，业务代码和测试留在应用根。更新项目入口、提示词、CI 和历史工件的旧路径，保持已有卡、报告和契约版本可追溯。

升级时对比合并 `skills/`、`rules/`、`templates/`、`scripts/`、方法论和入口说明，保留项目对命令、迭代命名及校验项的适配。画像、词表、配置、真实 handoff、设计稿、项目 Golden 和迭代工件以项目版本为准，不用模板覆盖。重跑 §二适用验收。
