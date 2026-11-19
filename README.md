# AI-Native-template

AI 原生开发工作流模板：**后端、小程序前端、Flutter 移动端工作流 + Rule + 项目画像 + Golden 样例 + 校验脚本**，把「需求 → 设计 → 代码 → 测试 → QA 验收」做成可重复、可审计的流程。

## 快速开始

**接入（新项目与存量项目同法）**：

1. **引入**：把AI-Native工程放到项目的根目录下、**不带 `.git`**，放入后目录名保持为 `AI-Native/`。存量项目原有代码与目录不动，复制 [AGENTS.md](AGENTS.md) 文档到项目根路径下，假如存量项目已有AGENTS.md，则进行整合；复制/整合后为文中指向模板的相对链接和命令补上 `AI-Native/` 前缀（包括指向模板 README 的链接）。
2. **接入**：后端按 [backend/MIGRATION.md](backend/MIGRATION.md) §一（填画像 → 替换锚点 → 重写 Golden → 分发到 Agent → 工作流裁剪，每步 AI 执行、人审定稿）；前端按 [frontend/README.md](frontend/README.md) 的「接入替换」。Flutter 项目按 [Flutter 接入与升级](flutter/USAGE.md#接入与升级) 填画像并验收。

## 详细使用说明
后端线见 [backend/USAGE.md](backend/USAGE.md)；前端线见 [frontend/USAGE.md](frontend/USAGE.md)，移动端见 [Flutter 使用手册](flutter/USAGE.md)。

## 工作流全景介绍

把「需求 → 设计 → 代码 → 测试 → 验收」拆成一组按序衔接的 Skill 流水线：每个环节的产出落盘为文档契约（Story / DD / TS / OpenAPI），作为下一环节的输入；流程由 AI 执行，人在固定介入点把关（映射确认、审查放行），Story / 文档工件 / 代码三道独立审查守住质量。后端发布契约，小程序与 Flutter 按各自 Story 消费 handoff。

## 工作流全景

```
── backend/（后端线，消费业务需求）──────────────────────────
业务原始需求
  → journey-scenario-design   → JSD（用户旅程 + 场景矩阵，AC 完备性源头）
  → high-level-design         → HLD（模块边界/集成矩阵/建议 Story）
  → story-splitting           → STORY 卡（AC/BR + 依赖拓扑 + 迭代计划）
  → detail-design             → DD + OpenAPI + schema/DDL + 代码骨架 + 测试策略
  → test-spec-alignment       → TS（用例级测试规格，编码前）
  → feature-coding            → 代码 + 测试（TDD，全绿）
  → 代码审查（rules/code-review.md）→ REVIEW-CODE-IMPL-*（commit/IT 前）
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
  → 代码审查（rules/code-review.md）→ REVIEW-CODE-FE-*（联调/提测前）
```

Flutter 移动端同样消费后端 handoff，纯本地卡直接从需求拆分开始。拆卡、详设、编码和审查的入口见 [Flutter 工作流](flutter/README.md)。

后端与客户端可独立接入（只用前端线时，handoff 包直接向你的后端团队索取）。方法论见 [backend/docs/methodology/](backend/docs/methodology/) 与 [frontend/docs/methodology/](frontend/docs/methodology/)。

## Skill 入口

| 类别 | Skill | 什么时候进 |
|------|-------|-----------|
| 主线 7 环 | JSD → HLD → Story → DD → TS → feature-coding → IT | 新需求、改需求 |
| QA 专线 3 环 | qa-acceptance-case-design → api-blackbox-test → test-data-design | 提测 / 发版验收 |
| 旁路 2 环 | bugfix / legacy-test-migration | 缺陷 / 存量用例 |
| Flutter 移动端 | flutter-story-splitting → flutter-detail-design → flutter-feature-coding | Android / iOS 页面、本地数据或原生能力 |
| 前端 3 环 | frontend-story-splitting → frontend-detail-design → frontend-feature-coding | 前端页面 |

主线是菜单不是必经路：入口由手上已有资产决定；逐个 Skill 的触发时机与产出见下文「Skill 一览」。

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
| flutter | flutter-story-splitting | 需求或契约已就绪 | STORY-FL 卡 |
| flutter | flutter-detail-design | Story 范围和验收依据明确 | DD-FL 详设 |
| flutter | flutter-feature-coding | 详设可实现 | 应用代码、测试及适用的审查报告 |

## 目录职责

| 目录 | 职责 |
|------|------|
| `backend/skills/`（12）+ `frontend/skills/`（3） | Skill（自包含：SKILL.md + templates/ + references/） |
| `backend/rules/`（15）+ `frontend/rules/`（5） | 编码与文档规范（纯 markdown；「规范听 Rule，流程听 Skill」） |
| `{backend,frontend}/architecture/system-landscape.md` | 各线**项目画像（接入必填）**：项目层事实唯一定义处 |
| `flutter/` | [移动端资产目录](flutter/README.md)，含画像、契约交接、阶段工件和校验器 |
| `backend/reference/` | 后端通用工程指南（幂等、内存安全 IO、定时任务、统一响应） |
| `{backend,frontend}/glossary/` | 领域词表（前端与后端对齐的子集） |
| `frontend/docs/handoff/` | 前后端契约交接区（openapi 快照 + VERSION pin + stories-index） |
| `{backend,frontend}/docs/methodology/` | 方法论与 Skill 设计说明（含测试线总设计） |
| `backend/docs/training/` | 培训课件（黑盒选例、白盒分层、存量迁移） |
| `backend/docs/{requirements,design,test-spec,qa,api,schema,reviews}/` | 后端流程工件落点（`reviews/` 为 Story 审查报告 + 代码审查报告；`_golden/` 为标准样例）；前端工件落点同理 |
| `{backend,frontend}/templates/` | 流程模板（backend：Story 审查 + 代码审查；frontend：代码审查） |
| `backend/hooks/` | 机制化强制 Hook（公共代码保护 / diff 超限 / 漏测提醒） |
| `{backend,frontend}/scripts/validate-skills.sh` | 各线资产完整性校验（frontmatter + 引用可达 + 坏链检测） |
| `{backend,frontend}/config/current-sprint` | 各线当前迭代号（单一事实源） |

## 设计原则（继承自源项目）

- **单点维护**：项目事实只在各线 `system-landscape.md` 定义，Skill 与 Rule 引用不复制。
- **缺口三分法**：阻断（问用户）/ 可补充（`[AI推断]` 标注）/ 提醒（记录），AI 不静默猜。
- **契约单向流**：后端定契约 → handoff → 前端消费；前端永远不直接改 OpenAPI。
- **机械与语义分工**：确定性检查交给脚本（validate-skills、hooks、构建测试），语义与风险判断交给 Skill 流程与独立审查（Story 门禁见 [backend/rules/story-review.md](backend/rules/story-review.md)；代码审查见 [backend/rules/code-review.md](backend/rules/code-review.md)）。
- **代码审查**：编码后、合并前由独立上下文审 diff + Story/DD/TS/OpenAPI，P0–P3 按档位闭环；报告落 `docs/reviews/{迭代}/REVIEW-CODE-{阶段}-*`。
- **同场景只写一遍**：Java 白盒守代码逻辑（PR 门禁），Python 黑盒守部署环境（发版门禁），见 [backend/docs/methodology/test-line.md](backend/docs/methodology/test-line.md)。
- **Golden 教学**：每类工件带标准样例（`_golden/`），「写一个 Golden，不是拷一个 Golden」——接入项目时应重写为本项目真实样例。
