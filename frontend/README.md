# frontend：前端 AI 原生工作流模板

三段流水线：需求拆解 → 前端详设 → TDD 编码；消费后端 handoff 契约，编码后、联调/提测前做独立代码审查。所有项目专属值统一从 `architecture/system-landscape.md`、`config/current-sprint` 与 `docs/handoff/` 读取，接入时无需全局替换 Skill 正文。

## 快速导航

| 我想… | 看 |
|--------|----|
| 日常使用 | [USAGE.md](USAGE.md) |
| 接入新项目 | [MIGRATION.md](MIGRATION.md) |
| 看目录结构 | [目录职责](#目录职责) |
| 看与后端关系 | [与 backend 线的关系](#与-backend-线的关系) |
| 看整体流水线 | 根 [README.md](../README.md) |

---

## 工作流

```text
Epic/PRD/原型 + 后端 OpenAPI handoff（docs/handoff/）
  → frontend-story-splitting   → STORY-FE-*.md（AC + 本卡 operationId 范围）
  → frontend-detail-design     → DD-FE-*.md（页面状态机、组件树、AC→operationId 映射）
  → frontend-feature-coding    → pages/components/services + 测试（TDD）
  → 代码审查（rules/code-review.md）→ REVIEW-CODE-FE-*（联调/提测前）
```

---

## 目录职责

| 目录 | 职责 |
|------|------|
| `skills/` | 3 个前端 Skill（自包含，纯抽象通用模板） |
| `rules/` | 5 条前端规范：API Client 约定、错误展示、性能、工程结构、代码审查 |
| `architecture/system-landscape.md` | 前端画像（**接入必填**；含 §四 契约与鉴权、§六 与后端协作机制） |
| `glossary/domain-glossary.md` | 前端词表（与后端仓对齐的子集） |
| `docs/handoff/` | 前后端契约交接区（openapi 快照 + VERSION pin + stories-index） |
| `docs/methodology/` | 前端方法论（与后端方法论的差异、两条主线） |
| `templates/` | 代码审查报告模板（`code-review-report.md`） |
| `docs/reviews/` | 前端代码审查报告落点（`REVIEW-CODE-FE-*`）；接入后在前端工程根 `docs/reviews/` |
| `docs/{requirements,design}/_golden/` | STORY-FE / DD-FE 标准样例（接入时按本项目重写） |
| `config/current-sprint` | 当前迭代号 |
| `scripts/validate-skills.sh` | 前端资产完整性校验 |

---

## 接入

- **前置**：模板放入项目的方式见仓库根 [README.md](../README.md)「快速开始」。
- **完整步骤**：handoff 包与迭代号 → 前端画像 → 重写 Golden（建议）→ 分发与裁剪 → AI 自动接入审查，见 [MIGRATION.md](MIGRATION.md)。
- **分工**：AI 执行，人只在人工介入点拍板。

---

## 使用

见 [USAGE.md](USAGE.md)（含可直接复制的提示词模板、端到端示例、反模式清单）。

---

## 与 backend 线的关系

- backend 线产出 OpenAPI 契约（`detail-design` 定稿），再由后端 `api-handoff`  Skill 冻结成 handoff 包（快照 + VERSION + Story↔operationId 索引）交给本线消费。
- **前端不定义契约**。
- 两线可独立接入；只用前端线时，handoff 包直接向你的后端团队索取（同样要求三件套齐全）。
- 本线**未含 e2e 与 frontend-test-spec-alignment**（规划中，定型后补抽）。
