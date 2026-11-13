# frontend：前端 AI 原生工作流模板

自源项目（C 端微信小程序仓）抽取。**三段流水线 + 代码审查门禁**：需求拆解 → 前端详设 → TDD 编码，消费后端 handoff 契约；编码后、联调/提测前做独立代码审查。

```
Epic/PRD/原型 + 后端 OpenAPI handoff（docs/handoff/）
  → frontend-story-splitting   → STORY-FE-*.md（AC + 本卡 operationId 范围）
  → frontend-detail-design     → DD-FE-*.md（页面状态机、组件树、AC→operationId 映射）
  → frontend-feature-coding    → pages/components/services + 测试（TDD）
  → 代码审查（rules/code-review.md）→ REVIEW-CODE-FE-*（联调/提测前）
```

## 目录职责

| 目录 | 职责 |
|------|------|
| `skills/` | 3 个前端 Skill（自包含） |
| `rules/` | 5 条前端规范：API Client 约定、错误展示、性能、工程结构、代码审查 |
| `architecture/system-landscape.md` | 前端画像（**接入必填**；含 §四 契约与鉴权、§六 与后端协作机制） |
| `glossary/domain-glossary.md` | 前端词表（与后端仓对齐的子集） |
| `docs/handoff/` | 前后端契约交接区（openapi 快照 + VERSION pin + stories-index） |
| `docs/methodology/` | 前端方法论（与后端方法论的差异、两条主线） |
| `templates/` | 代码审查报告模板（`code-review-report.md`） |
| `docs/reviews/` | 前端代码审查报告落点（`REVIEW-CODE-FE-*`） |
| `docs/{requirements,design}/_golden/` | STORY-FE / DD-FE 标准样例（destination-search-allocate 一族） |
| `config/current-sprint` | 当前迭代号 |
| `scripts/validate-skills.sh` | 前端资产完整性校验 |

## 使用

见 [USAGE.md](USAGE.md)（含可直接复制的提示词 Demo、端到端示例、反模式清单）。接入替换见根 [MIGRATION.md](../MIGRATION.md) §三。

## 与 backend 线的关系

同源不同层：backend 线产出 OpenAPI 契约（`detail-design` 定稿），经 handoff 交接给本线消费；**前端不定义契约**。两线可独立接入（只用前端线时，handoff 包直接从你的后端团队拿）。
