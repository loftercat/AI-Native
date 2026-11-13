# USAGE：如何使用这套工作流

本手册面向**后端线**的接入后使用者（研发 / QA / 流程管理员），回答三个问题：动手前人要准备好什么、从哪里开始、每一步人工介入点在哪。**前端线**（消费后端 handoff 契约的三段流水线）见 [frontend/USAGE.md](../frontend/USAGE.md)。模板是什么、目录结构见 [README.md](../README.md)；接入替换见 [MIGRATION.md](../MIGRATION.md)。

---

## 一、人工前置条件（AI 流程跑得动的前提）

### 1. 一次性前置（接入期做完，之后不再管）

| # | 前置 | 验证方式 |
|---|------|----------|
| 1 | 按 [MIGRATION.md](../MIGRATION.md) 完成接入：画像（`architecture/system-landscape.md`）逐节填好、项目锚点替换、Golden 用本项目业务重写 | `bash scripts/validate-skills.sh` PASSED |
| 2 | skills/、rules/、templates/ 已分发到所用 Agent 的技能目录（Cursor / Claude Code 等） | 对 Agent 说「列出你可用的 skill」，能看到 12 个；`templates/code-review-report.md` 可达 |
| 3 | 代码仓库可构建、存量测试全绿（`mvn test` 或等价命令） | 本地跑一遍构建测试 |
| 4 | （可选，建议）hooks 按 [hooks/README.md](hooks/README.md) 注册，`PROTECTED` 保护路径改成本项目公共代码 | 改 `booking-common` 等价目录时被拦下询问 |
| 5 | （可选，建议）`scripts/validate-skills.sh` 挂进 CI | 提交断链资产时 CI 红 |
| 6 | （建议）独立审查人（独立 AI 会话 / 审查 agent / 人）可用 | 发起一次代码审查，能返回 P0–P3 |

### 2. 迭代级前置（每个迭代开始时，人做一次）

- **更新迭代号**：`config/current-sprint` 改为当前迭代（一行文本，如 `2026-S03`）。所有 Skill 落盘路径从这里取迭代号——忘改会把工件写进上个迭代目录。
- **需求输入就绪**：至少有 Epic 卡（`docs/requirements/epics/EPIC-*.md`）或 PRD/原始需求。只有口头想法时，从 journey-scenario-design 开始结构化。

### 3. 任务级 / 环境类前置（用到哪条线才需要）

| 线 | 前置 | 缺失时行为 |
|----|------|-----------|
| 详设（detail-design） | 无 | — |
| 编码（feature-coding） | 代码仓库可编译；TS 已落盘则以其为用例权威（TS 可选，无 TS 时按详设 §9 测试策略执行并标注 `[AI推断]`） | 无 TS → 降级；详设缺失 → 按 Story + OpenAPI + §8 推断并标注（见该 Skill 降级策略表） |
| 集成测试（integration-test-design） | 本地 Docker 可用（Testcontainers 拉起真实数据库） | 集成测试跑不起来 |
| QA 黑盒（api-blackbox-test） | ① 已部署的测试环境；② 环境变量 `BLACKBOX_BASE_URL`；③ 各角色 Token 环境变量（`ADMIN_TOKEN` / `ADMIN_TOKEN_DENIED` / `APP_TOKEN` 等，清单在画像 §4.3.4，由运维/CI 注入，**不进 Git**）；④ Python + pytest/requests 环境 | `BLACKBOX_BASE_URL` 缺失 → 用例 skip（非 fail） |
| 环境造数（test-data-design） | 数据库连接串环境变量 `SEED_DB_URL`（由运维/CI 注入） | seed 脚本 `sys.exit(0)` skip |
| 验收用例（qa-acceptance-case-design） | Story 卡 + OpenAPI 契约齐备（**硬依赖**） | Skill 阻断，不产出伪造 URL 的用例 |

### 4. 人工必须保留的决策点（流程设计上就不放权给 AI）

- **Epic 级拆卡确认**：story-splitting 产出 Story 列表后**须人确认才落盘**——卡的边界与优先级是人的决策。
- **阻断类缺口裁决**：Skill 遇到「信息不足且不可推断」时停下提问（缺口三分法），人回答后继续；AI 会用 `[AI推断]` 标注它补的内容，人工审查时优先看这些标注。
- **bugfix 循环上限**：修复循环 >3 轮、根因回退 >2 次 → Skill 自动交还人工，不要硬催 AI 继续试。
- **存量迁移批量确认**：legacy-test-migration 单批 ≤200 条，超限须人工确认分批。
- **对外契约变更**：编码中发现需要改 OpenAPI/schema 语义时，AI 会暂停回 detail-design——人确认是否真的要动契约。
- **代码审查放行**：按档位闭环未满足不放行（L1=P0/P1；L2=P0–P2；L3=P0–P3）；外部验证 P2 记录验证方式后可放行；L0 改动跳过审查须在回复说明。

---

## 二、从哪里开始：按手上资产选入口

不需要从头走完整流水线——**入口由手上已有的资产决定**：

| 你手上有什么 | 从这里开始 | 产出 |
|--------------|-----------|------|
| 原始需求（口头 / PRD 草稿 / 原型链接） | `journey-scenario-design` | JSD（用户旅程 + 场景矩阵） |
| Epic 卡 / PRD 定稿 | `high-level-design` | HLD（模块边界 + 建议 Story） |
| HLD（或 Epic + JSD） | `story-splitting` | Story 卡 + 迭代交付计划 |
| Story 卡 | `detail-design` | DD + OpenAPI + schema + 代码骨架 |
| DD（含 §9 测试策略） | `test-spec-alignment` | TS 测试规格 |
| Story + DD + TS | `feature-coding` | 代码 + 测试（TDD 全绿） |
| 代码完成且跨模块/外部链路 | `integration-test-design` | `*IT` 集成测试 |
| 线上/联调缺陷 | `bugfix`（旁路，不走主线） | 复现测试 + 修复 + FIX 报告 |
| 存量项目无 Story 的老用例 | `legacy-test-migration`（旁路） | 分类矩阵 + TS-LEGACY |

QA 专员另有一条专线（同源 Story，非上下游）：Story + OpenAPI 齐备后 → `qa-acceptance-case-design` 产验收用例，其中 `execution=blackbox` 的行 → 部署后 `api-blackbox-test` 跑黑盒，需要环境数据时 → `test-data-design` 造数。无 QA 团队可整线裁掉（黑盒冒烟由集成测试承担）。

---

## 三、一个迭代的典型走法（主线演示）

**迭代开始（人 + AI 各一次）**：

1. 人：更新 `config/current-sprint`；准备 Epic 输入。
2. 对 Agent 说：*「用 journey-scenario-design 处理 EPIC-xxx，产出 JSD」*（或已有 HLD 则跳到下一步）。
3. 对 Agent 说：*「用 high-level-design 基于 EPIC-xxx 出 HLD」*。
4. 对 Agent 说：*「用 story-splitting 按 HLD-EPIC-xxx 拆本迭代卡」* → **人工确认 Story 列表后**落盘，同时产出迭代交付计划（依赖拓扑决定开发顺序，W0 基础卡最先）。
   - **送审（推荐）**：对另一个独立 Agent 会话说「用 [rules/story-review.md](rules/story-review.md) 的清单审查 STORY-xxx」→ 报告落 `docs/reviews/{迭代}/`，结论通过才把状态改「已确认」。不送审也能跑，但状态填了「已确认」校验器会强制要求报告——跳过必须显式。

**迭代中（每张卡重复）**：

5. 对 Agent 说：*「用 detail-design 做 STORY-2026-S03-001」* → 产出 DD + OpenAPI + schema。
6. 对 Agent 说：*「用 test-spec-alignment 给 STORY-2026-S03-001 出 TS」*。
7. 对 Agent 说：*「用 feature-coding 实现 STORY-2026-S03-001，跑全量测试」*。
8. **代码审查（commit 前）**：对独立审查人（新会话 / 审查 agent / 人）说 *「按 rules/code-review.md §三 给全输入（档位、Story/AC、diff 范围、DD/TS/OpenAPI、mvn test 结果、关注点）审查 STORY-2026-S03-001，档位 L2」*；报告落 `docs/reviews/{迭代}/REVIEW-CODE-IMPL-*`，按档位闭环（L1=P0/P1；L2=P0–P2；L3=P0–P3）后才允许 commit / 进集成测试。L0（纯注释/格式化/重命名/日志文案）跳过并说明原因。审查人不要求与实现使用同一 Agent。
9. 跨模块/含外部链路的卡，追加：*「用 integration-test-design 给这张卡补集成测试」*；IT 代码合入前按同一规则审 `REVIEW-CODE-IT-*`。
10. 单卡完成后，提测前：QA 走 `qa-acceptance-case-design` → 部署后 `api-blackbox-test`。

**随时（旁路）**：出 bug → *「用 bugfix 处理这个缺陷：<现象/复现路径/期望>」*（输入不完整时 Skill 会先做五要素澄清，超 2 轮阻断）。

> 触发方式不拘话术：点名 skill 名最稳（「用 detail-design 做 X」）；描述场景也能自动匹配（「给 STORY-xxx 写详设」）。关键是给出**卡号或路径**，Skill 会自己按「前置加载」清单去读上游工件。

---

## 四、AI 停下来问你时怎么办

| AI 的行为 | 含义 | 你要做的 |
|-----------|------|---------|
| 标记**阻断**并提问 | 缺的信息不可推断（如模块归属不明、契约冲突） | 补充事实或拍板；回答后 AI 继续 |
| 内容带 `[AI推断]` 标注 | 缺但可合理推断，AI 先干起来留了标记 | 审查时逐条确认，错了让它改并去标记 |
| 只给**提醒** | 记录在案的风险/待办，不挡流程 | 迭代回顾时看一眼 |
| 降级运行（如无词表、无方法论文档） | 前置资产缺失但流程可走 | 质量预期下调；补齐资产后恢复 |
| 产出工件前说「已存在，是否覆盖」 | 防静默覆盖约定 | 确认是否真的要重写 |

---

## 五、产出物落在哪（验收清单）

| 阶段 | 落点 | 命名 |
|------|------|------|
| JSD / Epic / Story | `docs/requirements/`（epics/ 与 `{迭代}/`） | 见 [docs/agile/card-naming-conventions.md](docs/agile/card-naming-conventions.md) |
| HLD / DD | `docs/design/` | 同上 |
| OpenAPI / schema | `docs/api/{服务标识}/`、`docs/schema/{服务}/` | 同上 |
| TS / 集成测试规格 | `docs/test-spec/{迭代}/`；集成测试代码进模块 test 目录 | 同上 |
| 验收用例 / 数据画像 | `docs/qa/{迭代}/`、`docs/qa/data-profiles/` | 同上 |
| 代码审查报告 | `docs/reviews/{迭代}/` | `REVIEW-CODE-{阶段}-*`（IMPL/IT/FIX/FE/BB/SEED） |
| 黑盒脚本 / 造数 | `tests/blackbox/`、`tests/data/` | `test_*.py`、`seed_*.py` |
| 前端 Story / 详设 | `frontend/docs/{requirements,design}/{迭代}/` | `STORY-FE-*` / `DD-FE-*`（golden 见 `frontend/docs/**/_golden/`） |
| 每类工件的「标准长什么样」 | `docs/**/_golden/` | GOLDEN-001 族 |

每类工件拿 `_golden/` 对照样例检查结构是否走样——这是最快的人工验收方法。
