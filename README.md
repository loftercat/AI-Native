# new-ai-workflow-template

AI 原生开发工作流模板：**后端线（12 Skill）+ 前端线（3 Skill）+ Rule + 项目画像 + Golden 样例 + 校验脚本**，把「需求 → 设计 → 代码 → 测试 → QA 验收」做成可重复、可审计的流程。

自已落地的源项目（后端仓 + C 端小程序仓）抽取通用化而来。项目专属值（模块名、号段、路径）保留为示例，接入时按 [MIGRATION.md](MIGRATION.md) 清单替换。

## 双线全景

```
── backend/（后端线，消费业务需求）──────────────────────────
业务原始需求
  → journey-scenario-design   → JSD（用户旅程 + 场景矩阵，AC 完备性源头）
  → high-level-design         → HLD（模块边界/集成矩阵/建议 Story）
  → story-splitting           → STORY 卡（AC/BR + 依赖拓扑 + 迭代计划）
  → detail-design             → DD + OpenAPI + schema/DDL + 代码骨架 + 测试策略
  → test-spec-alignment       → TS（用例级测试规格，编码前）
  → feature-coding            → 代码 + 测试（TDD，全绿）
  → integration-test-design   → *IT / *ScenarioIT（跨模块/外部链路）
  QA 专线：qa-acceptance-case-design → api-blackbox-test → test-data-design
  旁路：bugfix（七步闭环） / legacy-test-migration（存量用例改造）

        │  detail-design 定稿 OpenAPI → 发布 handoff 包
        ▼
── frontend/（前端线，消费后端契约）────────────────────────
后端 OpenAPI handoff（docs/handoff/）
  → frontend-story-splitting  → STORY-FE-*.md（AC + 本卡 operationId 范围）
  → frontend-detail-design    → DD-FE-*.md（页面状态机、组件树、AC→operationId 映射）
  → frontend-feature-coding   → pages/components/services + 测试（TDD）
```

两线可独立接入（只用前端线时，handoff 包直接向你的后端团队索取）。方法论见 [backend/docs/methodology/](backend/docs/methodology/) 与 [frontend/docs/methodology/](frontend/docs/methodology/)。

## 目录职责

| 目录 | 职责 |
|------|------|
| `backend/skills/`（12）+ `frontend/skills/`（3） | Skill（自包含：SKILL.md + templates/ + references/） |
| `backend/rules/`（11）+ `frontend/rules/`（4） | 编码与文档规范（纯 markdown；「规范听 Rule，流程听 Skill」） |
| `{backend,frontend}/architecture/system-landscape.md` | 各线**项目画像（接入必填）**：项目层事实唯一定义处 |
| `backend/reference/` | 后端通用工程指南（幂等、内存安全 IO、定时任务、统一响应） |
| `{backend,frontend}/glossary/` | 领域词表（前端与后端对齐的子集） |
| `frontend/docs/handoff/` | 前后端契约交接区（openapi 快照 + VERSION pin + stories-index） |
| `{backend,frontend}/docs/methodology/` | 方法论与 Skill 设计说明（含测试线总设计） |
| `backend/docs/training/` | 培训课件（黑盒选例、白盒分层、存量迁移） |
| `backend/docs/{requirements,design,test-spec,qa,api,schema,reviews}/` | 后端流程工件落点（`reviews/` 为 Story 审查报告；`_golden/` 为标准样例）；前端工件落点同理 |
| `backend/templates/` | 流程模板（Story 审查报告模板） |
| `backend/hooks/` | 机制化强制 Hook（公共代码保护 / diff 超限 / 漏测提醒） |
| `{backend,frontend}/scripts/validate-skills.sh` | 各线资产完整性校验（frontmatter + 引用可达 + 坏链检测） |
| `{backend,frontend}/config/current-sprint` | 各线当前迭代号（单一事实源） |

## 快速开始

0. **怎么用**：后端线见 [backend/USAGE.md](backend/USAGE.md)；前端线见 [frontend/USAGE.md](frontend/USAGE.md)（含提示词 Demo 与反模式）。
1. **接入**：按 [MIGRATION.md](MIGRATION.md) 替换项目锚点、填写两线画像（只用一线则只接一线）。
2. **分发**：把对应线 `skills/` 与 `rules/` 放到目标 Agent 技能目录（Cursor / Claude Code 等）。模板**不做 symlink 镜像**——多 Agent 场景建议 CI 同步拷贝（Windows 无 symlink 特权时镜像会失效，这是源项目的实测教训）。
3. **校验**：`bash backend/scripts/validate-skills.sh` 与 `bash frontend/scripts/validate-skills.sh`（各自扫本线 skills/rules/reference/architecture/glossary/docs-methodology；链接断 = FAIL，tick 提及 = WARN 人工确认；含未闭合方括号坏链检测）。建议接入 CI。

## Skill 一览

| 线 | Skill | 触发时机 | 产出 |
|----|-------|----------|------|
| backend | journey-scenario-design | 原始需求尚无结构化输入 | `JSD-EPIC-*.md` |
| backend | high-level-design | Epic/PRD 定稿 | `HLD-EPIC-*.md` |
| backend | story-splitting | HLD 完成要拆卡 | `STORY-{迭代}-*.md` + 迭代计划 |
| backend | detail-design | Story 定稿要写方案 | `DD-*.md` + OpenAPI + schema + 骨架 |
| backend | test-spec-alignment | DD 完成、编码前 | `TS-STORY-*.md` |
| backend | feature-coding | TS 就绪要写代码 | 代码 + `*Test` |
| backend | integration-test-design | 跨模块/外部链路实现后 | `*IT` / `*ScenarioIT` |
| backend | qa-acceptance-case-design | QA 消费 Story + OpenAPI | `AC-STORY-*.md` + 追溯 CSV |
| backend | api-blackbox-test | 验收用例含 blackbox 行 | `tests/blackbox/test_*.py` |
| backend | test-data-design | blackbox 需环境造数 | `DP-*.yaml` + seed 脚本 |
| backend | bugfix | 线上/联调缺陷（旁路） | 复现测试 + `FIX-*.md` |
| backend | legacy-test-migration | 存量用例批量改造（旁路） | 分类矩阵 + `TS-LEGACY-*.md` |
| frontend | frontend-story-splitting | 拿到 handoff 包要拆前端卡 | `STORY-FE-*.md` |
| frontend | frontend-detail-design | 前端 Story 定稿 | `DD-FE-*.md` |
| frontend | frontend-feature-coding | 详设完成要写页面 | 页面/组件/服务 + 测试 |

## 设计原则（继承自源项目）

- **单点维护**：项目事实只在各线 `system-landscape.md` 定义，Skill 与 Rule 引用不复制。
- **缺口三分法**：阻断（问用户）/ 可补充（`[AI推断]` 标注）/ 提醒（记录），AI 不静默猜。
- **契约单向流**：后端定契约 → handoff → 前端消费；前端永远不直接改 OpenAPI。
- **机械与语义分工**：确定性检查交给脚本（validate-skills、hooks、构建测试），语义与风险判断交给 Skill 流程与独立审查（Story 门禁见 [backend/rules/story-review.md](backend/rules/story-review.md)）。
- **同场景只写一遍**：Java 白盒守代码逻辑（PR 门禁），Python 黑盒守部署环境（发版门禁），见 [backend/docs/methodology/test-line.md](backend/docs/methodology/test-line.md)。
- **Golden 教学**：每类工件带标准样例（`_golden/`），「写一个 Golden，不是拷一个 Golden」——接入项目时应重写为本项目真实样例。
