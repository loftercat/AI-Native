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

## 接入替换（接入时做一次）

接入 = 填前端画像 + 从后端拿 handoff 包 + 替换前端锚点 + Golden 重写（执行模式同根 [MIGRATION.md](../MIGRATION.md) §一：AI 执行，人审定稿）：

1. **前端画像**：填 `architecture/system-landscape.md`——重点 §四（契约文件/鉴权/错误码对齐）与 §六（与后端流水线的协作机制）；词表 `glossary/` 与后端仓对齐。
2. **handoff 包**：从后端团队拿 OpenAPI 快照 + 版本 pin，放入 `docs/handoff/openapi/{后端服务标识}.yaml` 与 `VERSION`（机制见 [docs/handoff/README.md](docs/handoff/README.md)）。**前端永远不直接改契约**。
3. **替换前端锚点**（示例值 → 本项目）：

| 类别 | 示例值 | 替换为 |
|------|--------|--------|
| 契约文件 | `docs/handoff/openapi/booking-bff-app.yaml` | 你的后端服务契约快照 |
| 技术栈 | 微信小程序原生（`wx.*`、`pages/`、分包） | 你的前端框架（Vue/React/uni-app 等；`rules/miniprogram-*` 两条按栈重写或裁剪） |
| 页面/组件名 | `pages/destination-search/` 等 | 本项目页面结构（画像 §3.2） |
| 迭代号 | `2026-S01/S02` | 与后端线一致的迭代约定（`config/current-sprint`） |

自查（在 `frontend/` 目录执行）：`grep -rn "booking\|hema\|2026-S" skills/ rules/`，预期全部为上表已声明示例。

4. **Golden 重写**：AI 从前端画像选真实页面需求重写 `docs/**/_golden/` 的 STORY-FE / DD-FE 样例（destination-search-allocate 一族），画像不足时人工指定，提交人验收。

**接入后验收**：`bash scripts/validate-skills.sh` PASSED；拿到一次真实 handoff 包走通三段——frontend-story-splitting → frontend-detail-design → frontend-feature-coding。

## 使用

见 [USAGE.md](USAGE.md)（含可直接复制的提示词 Demo、端到端示例、反模式清单）。

## 与 backend 线的关系

同源不同层：backend 线产出 OpenAPI 契约（`detail-design` 定稿），经 handoff 交接给本线消费；**前端不定义契约**。两线可独立接入（只用前端线时，handoff 包直接从你的后端团队拿）。本线**未含 e2e 与 frontend-test-spec-alignment**（规划中，定型后补抽）。
