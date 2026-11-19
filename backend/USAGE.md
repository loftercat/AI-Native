# USAGE：如何使用这套工作流

本手册面向**后端线**的接入后使用者（研发 / QA / 流程管理员），覆盖：动手前要准备什么、从哪里开始、一个迭代怎么走、AI 停下来时怎么办。**前端线**（消费后端 handoff 契约的三段流水线）见 [frontend/USAGE.md](../frontend/USAGE.md)。模板是什么、目录结构见 [README.md](../README.md)；接入替换见 [MIGRATION.md](MIGRATION.md)。

---

## 一、人工前置条件（AI 流程跑得动的前提）

### 1. 一次性前置（接入期做完，之后不再管）

| # | 前置 | 验证方式 |
|---|------|----------|
| 1 | 按 [MIGRATION.md](MIGRATION.md) 完成接入（画像、锚点替换、Golden 重写、分发、裁剪） | `bash scripts/validate-skills.sh` PASSED；对 Agent 说「列出你可用的 skill」能看到对应线的 Skill（后端未裁剪 12；裁 QA 专线后 9；若无存量用例再删 legacy-test-migration 则为 8） |
| 2 | 代码仓库可构建、存量测试全绿（`mvn test` 或等价命令） | 本地跑一遍构建测试 |
| 3 | （建议）独立审查人（独立 AI 会话 / 审查 agent / 人）可用 | 发起一次代码审查，能返回 P0–P3 |

### 2. 迭代级前置（每个迭代开始时，人做一次）

- **更新迭代号**：`config/current-sprint` 改为当前迭代（一行文本，如 `2026-S03`）。所有 Skill 落盘路径从这里取迭代号——忘改会把工件写进上个迭代目录。

### 3. 任务级 / 环境类前置（用到哪条线才需要）

| 线 | 前置 |
|----|------|
| 详设（detail-design） | 无 |
| 编码（feature-coding） | 代码仓库可编译；**TS 已落盘（必备）**，TS 为用例与 Mock 边界权威；详设 §9 齐备 |
| 集成测试（integration-test-design） | 本地 Docker 可用（Testcontainers 拉起真实数据库） |
| QA 黑盒（api-blackbox-test） | ① 已部署的测试环境；② 环境变量 `BLACKBOX_BASE_URL`；③ 各角色 Token 环境变量（`ADMIN_TOKEN` / `ADMIN_TOKEN_DENIED` / `APP_TOKEN` 等，清单在画像 §4.3.4，由运维/CI 注入，**不进 Git**）；④ Python + pytest/requests 环境 |
| 环境造数（test-data-design） | 数据库连接串环境变量 `SEED_DB_URL`（由运维/CI 注入） |
| 验收用例（qa-acceptance-case-design） | Story 卡 + OpenAPI 契约齐备（**硬依赖**） |

### 4. 人工介入点（流程设计上就不放权给 AI）

- **Epic 级拆卡确认**：story-splitting 产出 Story 列表后**须人确认才落盘**——卡的边界与优先级是人的决策。
- **bugfix 循环上限**：修复循环 >3 轮、根因回退 >2 次 → Skill 自动交还人工，不要硬催 AI 继续试。
- **存量迁移批量确认**：legacy-test-migration 单批 ≤200 条，超限须人工确认分批。
- **对外契约变更**：编码中发现需要改 OpenAPI/schema 语义时，AI 会暂停回 detail-design——人确认是否真的要动契约。
- **代码审查放行**：L1=P0/P1；L2=P0/P1 + 正确性/安全 P2；L3=P0–P2；外部验证 P2 记录验证方式后可放行；L0（文档/路径/机械改动）不派 agent，回复说明自动门禁结果。

> AI 各类停下行为（阻断提问 / `[AI推断]` / 提醒 / 降级 / 覆盖确认）的应对速查见 §四。

---

## 二、从哪里开始：按手上资产选入口

不需要从头走完整流水线——**入口由手上已有的资产决定**：

| 你手上有什么 | 从这里开始 |
|--------------|-----------|
| 原始需求（口头 / PRD 草稿 / 原型链接） | `journey-scenario-design` |
| Epic 卡（+ PRD，+ JSD 可选） | `high-level-design` |
| HLD（或 Epic + JSD） | `story-splitting` |
| Story 卡 | `detail-design` |
| DD（含 §9 测试策略） | `test-spec-alignment` |
| Story + DD + TS | `feature-coding` |
| 代码完成且跨模块/外部链路 | `integration-test-design` |
| 线上/联调缺陷 | `bugfix`（旁路，不走主线） |
| 存量项目无 Story 的老用例 | `legacy-test-migration`（旁路） |

QA 专员另有一条专线（同源 Story，非上下游）：Story + OpenAPI 齐备后 → `qa-acceptance-case-design` 产验收用例，其中 `execution=blackbox` 的行 → 部署后 `api-blackbox-test` 跑黑盒，需要环境数据时 → `test-data-design` 造数。无 QA 团队可整线裁掉（黑盒冒烟由集成测试承担）。

---

## 三、一个迭代的典型走法（主线演示）

**迭代开始（人 + AI 各一次）**：

1. 人：更新 `config/current-sprint`；准备 Epic 输入。
2. 手上是**原始需求**（PRD 草稿 / 口头 / 原型）→ 对 Agent 说：*「用 journey-scenario-design 把 <需求线索> 展开成 JSD」*；**Epic §4 旅程已详尽**（主路径完整且异常/备选场景已列）→ 跳过 JSD，直接下一步；仅有轻量文字描述 → 先跑 journey-scenario-design。
3. 对 Agent 说：*「用 high-level-design 基于 EPIC-xxx 出 HLD」*。
4. 对 Agent 说：*「用 story-splitting 按 HLD-EPIC-xxx 拆本迭代卡」* → **人工确认 Story 列表后**落盘，同时产出迭代交付计划（依赖拓扑决定开发顺序，W0 基础卡最先）。
   - **送审（推荐）**：对另一个独立 Agent 会话说「用 [rules/story-review.md](rules/story-review.md) 的清单审查 STORY-xxx」→ 报告落 `docs/reviews/{迭代}/`，结论通过才把状态改「已确认」。不送审也能跑，但状态填了「已确认」校验器会强制要求报告——跳过必须显式。

**迭代中（每张卡重复）**：

5. 对 Agent 说：*「用 detail-design 做 STORY-2026-S03-001」* → 产出 DD + OpenAPI + schema。
6. 对 Agent 说：*「用 test-spec-alignment 给 STORY-2026-S03-001 出 TS」*。
7. 对 Agent 说：*「用 feature-coding 实现 STORY-2026-S03-001，跑 Story 范围测试（`mvn test -pl <module> -am`）」*。
8. **代码审查**：独立审查人按 [rules/code-review.md](rules/code-review.md) 审本次 diff（各实现 Skill 验证通过后会提示触发；档位与闭环见规则）。
9. 跨模块/含外部链路的卡，追加：*「用 integration-test-design 给这张卡补集成测试」*；IT 合入前的审查由该 Skill 按 [rules/code-review.md](rules/code-review.md) 提示触发。
10. 单卡完成后，提测前 QA 线三件（均以 Story 编号为入口）：*「用 qa-acceptance-case-design 为 STORY-2026-S03-001 出验收用例」* → 部署后 *「用 api-blackbox-test 为 STORY-2026-S03-001 生成黑盒脚本」* → 需要环境数据时 *「用 test-data-design 为 STORY-2026-S03-001 造数」*。

**随时（旁路）**：出 bug → *「用 bugfix 处理这个缺陷：现象 <…> / 预期 <…> / 实际 <…> / 复现步骤 <…> / 环境版本 <…>」*（输入不完整时 Skill 会先做五要素澄清，超 2 轮阻断）；存量用例迁移 → *「用 legacy-test-migration 迁移 <用例导出文件>，目标模块 <module>」*。

> **触发格式**：*「用 <skill 名> <动作> <卡号或路径>」*——点名 skill 最稳，描述场景也能自动匹配（「给 STORY-xxx 写详设」）。关键是给出**卡号或路径**，Skill 会自己按「前置加载」清单去读上游工件；各 Skill 的触发示例见其 `SKILL.md` 文件头。

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

## 五、产出物落在哪

工件落点见根 [README.md](../README.md) 的「工件速查」节；命名规则见 [docs/agile/card-naming-conventions.md](docs/agile/card-naming-conventions.md)。
