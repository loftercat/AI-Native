# Flutter Android / iOS 工作流模板

面向采用 MVVM 的 Flutter Android / iOS 新项目，与 frontend 共用阶段、工件和审查档位。**三段流水线 + 代码审查门禁**：需求拆解 → 客户端详设 → TDD 编码，消费后端 handoff 契约；编码后、联调/提测前做独立代码审查。

## 快速导航

| 我想… | 看 |
|--------|----|
| 日常使用 | [USAGE.md](USAGE.md) |
| 接入新项目 / 升级模板 | [MIGRATION.md](MIGRATION.md) |
| 配置新项目的默认技术栈 | [config/tech-stack.md](config/tech-stack.md) |
| 看目录结构 | [目录职责](#目录职责) |
| 看与后端关系 | [与 backend 线的关系](#与-backend-线的关系) |
| 看整体流水线 | 根 [README.md](../README.md) |

## 工作流

```text
Epic/PRD/原型 + 适用的后端 OpenAPI handoff（docs/handoff/）
  → flutter-story-splitting   → STORY-Flutter-*.md（AC + 本卡 operationId 范围）
  → flutter-detail-design     → DD-Flutter-*.md（页面状态机、组件树、AC→operationId 映射）
  → flutter-feature-coding    → Widget/ViewModel/Repository + 测试（TDD）
  → 代码审查（rules/code-review.md）→ REVIEW-CODE-Flutter-*（联调/提测前）
```

## 目录职责

| 目录 | 职责 |
|------|------|
| `skills/` | 3 个客户端 Skill（自包含） |
| `rules/` | 9 条规范：工程与性能、契约与错误、状态与存储、原生桥接、UI 验收、测试发布、代码审查 |
| `architecture/system-landscape.md` | 客户端画像（**接入必填**；含 §四 契约与鉴权、§六 与后端协作机制） |
| `glossary/domain-glossary.md` | 客户端词表（与后端仓对齐的子集） |
| `docs/handoff/` | 前后端契约交接区（openapi 快照 + VERSION pin + stories-index） |
| `docs/methodology/` | 客户端方法论（与后端方法论的差异、两条主线） |
| `templates/` | 代码审查报告模板（`code-review-report.md`） |
| 应用根 `docs/{requirements,design,reviews}/{迭代}/` | 真实 Story、DD、代码审查和接入审查报告 |
| `docs/{requirements,design}/_golden/` | STORY-Flutter / DD-Flutter 标准样例（destination-search-allocate 一族） |
| `config/current-sprint` | 当前迭代号 |
| `config/tech-stack.md` | 生成新项目画像时采用的默认技术栈 |
| `scripts/validate-skills.sh` | 客户端资产完整性校验 |

接入后，项目技术选型见[项目画像 §3.1](architecture/system-landscape.md#31-技术栈)。编写组件、工具和接口时，可参考[中文业务注释写法](rules/flutter-project.md)。

## 接入项目

模板引入方式见根 [README.md](../README.md)「快速开始」。完整接入按 [MIGRATION.md](MIGRATION.md)：handoff → 画像 → 锚点替换 → Golden 重写 → 分发 → 裁剪 → 自验与独立接入审查。AI 执行，人在画像与映射、最终验收两处确认；旧布局迁移和模板升级也在该指南维护。

## 使用

见 [USAGE.md](USAGE.md)（含可直接复制的提示词 Demo、端到端示例、反模式清单）。项目事实只在本线系统画像维护。

[工程与路由](rules/flutter-project.md)、[性能与生命周期](rules/flutter-performance.md)、[网络鉴权](rules/api-client-conventions.md)、[错误反馈](rules/error-display-conventions.md)、[共享状态、存储与事件](rules/state-storage-events.md)、[原生 SDK](rules/platform-bridge.md)、[UI 与设计验收](rules/ui-design.md)、[测试与发布](rules/testing-release.md)、[独立代码审查](rules/code-review.md)。

阅读[搜索与分配 Story](docs/requirements/_golden/STORY-Flutter-GOLDEN-001-destination-search-allocate.md)和[对应 DD](docs/design/_golden/DD-Flutter-GOLDEN-001-destination-search-allocate.md)可看同一条 AC 如何贯穿三阶段。

同名目录可直接并排比较。Skill 名的前缀分别为 frontend 与 flutter，工件前缀分别为 FE 与 Flutter。工程与性能规则在前端名为 miniprogram-project / miniprogram-performance，在本线对应 flutter-project / flutter-performance。另四份规则补充移动端细节，均在已有步骤中按需引用。

## 与 backend 线的关系

后端用 `detail-design` 定稿 OpenAPI，再用 `api-handoff` 发布快照、VERSION 和 Story ↔ operationId 索引。只接入 Flutter 时，向后端团队索取同版三件套。发布目标与同步方式见 [handoff 约定](docs/handoff/README.md)。

本线不增设单独的 test-spec-alignment 或 Story/DD 审查阶段；Flutter 单元、Widget、集成测试和设备验证纳入编码步骤。

在线根运行 `bash scripts/validate-skills.sh --quiet-tick` 校验本线资产。
