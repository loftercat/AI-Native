# USAGE：后端线使用手册

本手册面向**后端线**的接入后使用者（研发 / QA / 流程管理员），覆盖：动手前要准备什么、从哪里开始、一个迭代怎么走、AI 停下来时怎么办。

**相关文档**：前端线见 [frontend/USAGE.md](../frontend/USAGE.md)；模板结构与目录见 [README.md](../README.md)；接入替换见 [MIGRATION.md](MIGRATION.md)。

---

## 快速导航

| 我想… | 看 |
|--------|----|
| 确认开工前提 | [前置条件](#前置条件) |
| 按手上资产选环节 | [工作流环节选择](#工作流环节选择) |
| 走一个迭代 | [工作流迭代演示](#工作流迭代演示) |
| 处理 AI 的阻断、降级或覆盖提示 | [AI 停下来时怎么办](#ai-停下来时怎么办) |
| 找工件落点 | [工件落点](#工件落点) |

---

## 前置条件

开工前确认迭代号与环境凭据。

> 一次性接入（迭代号、画像与两档 13 项选型、条件 Rule 与 Hook 配置、Golden 重写、分发与裁剪）见 [MIGRATION.md](MIGRATION.md)；公共基础库登记见 [指南](docs/methodology/common-foundation-migration.md)。

### 迭代切换

- **首次迭代号**：接入时已在 [MIGRATION.md](MIGRATION.md) §一.1 设置，无需重复。
- **后续切换**：每个新迭代开始，把 `config/current-sprint` 改为当前迭代（一行文本，如 `2026-S03`）。所有 Skill 落盘路径从这里取迭代号——忘改会把工件写进上个迭代目录。
- **登记迭代行**：同一动作里，在 `docs/agile/sprint-registry.yaml` 追加本迭代行（`id` / `name` / `start` / `end` / `status: active`）——收尾时才有行可标记 closed。

### 环境与凭据

| 线 | 前置 |
|----|------|
| 集成测试（integration-test-design） | 本地 Docker（Testcontainers 拉起真实数据库） |
| API 黑盒（api-blackbox-test） | 已部署测试环境；`BLACKBOX_BASE_URL`；管理员/用户 Token（变量清单见画像 §4.3.4，由运维/CI 注入，**不进 Git**）；Python + pytest/requests |
| 环境造数（test-data-design） | `SEED_DB_URL`（由运维/CI 注入） |

> 详设、编码、验收用例的前置由各自 `SKILL.md` 的「前置加载」检查；缺 TS、§9 或 Story/OpenAPI 时 Skill 会阻断，不再在 USAGE 重复。

---

## 工作流环节选择

不需要从头走完整流水线——**从哪个环节开始，由手上已有的资产决定**：

| 你手上有什么 | 从这里开始 |
|--------------|-----------|
| 原始需求（口头 / PRD 草稿 / 原型链接） | `journey-scenario-design` |
| Epic 卡（+ PRD，+ JSD 可选） | `high-level-design` |
| HLD（或 Epic + JSD） | `story-splitting` |
| Story 卡 | `detail-design` |
| DD（含 §9 测试策略） | `test-spec-alignment` |
| Story + DD + TS | `feature-coding` |
| 代码完成需验证本服务真实 DB 与下游契约 | `integration-test-design`（单服务 `*IT`，下游微服务模拟隔离） |
| 部署后需验证跨微服务完整主链路 | `api-blackbox-test`（测试环境真实多服务联调） |
| 线上/联调缺陷 | `bugfix`（旁路，不走主线） |
| 存量项目无 Story 的老用例 | `legacy-test-migration`（旁路） |

QA 专员另有一条专线（同源 Story，非上下游）：Story + OpenAPI 齐备后 → `qa-acceptance-case-design` 产验收用例，其中 `execution=blackbox` 的行 → 部署后 `api-blackbox-test` 跑黑盒，需要环境数据时 → `test-data-design` 造数。**微服务架构下，即使没有独立 QA 团队也建议保留 `api-blackbox-test`**，用于部署后跨微服务主链路验证（单服务 `*IT` 仅守单服务边界）。

---

## 工作流迭代演示

### 迭代开始

1. 人：确认/更新 `config/current-sprint`（首次接入已由 [MIGRATION.md](MIGRATION.md) §一.1 设置），并在 `docs/agile/sprint-registry.yaml` 追加本迭代行（`id` / `name` / `start` / `end` / `status: active`）；准备 Epic 输入。
2. 手上是**原始需求**（PRD 草稿 / 口头 / 原型）→ 对 Agent 说：*「用 journey-scenario-design 把 <需求线索> 展开成 JSD」*；**Epic §4 旅程已详尽**（主路径完整且异常/备选场景已列）→ 跳过 JSD，直接下一步；仅有轻量文字描述 → 先跑 journey-scenario-design。
3. 对 Agent 说：*「用 high-level-design 基于 EPIC-xxx 出 HLD」*。
4. 对 Agent 说：*「用 story-splitting 按 HLD-EPIC-xxx 拆本迭代卡」* → **人工确认 Story 列表后**落盘，同时产出迭代交付计划（依赖拓扑决定开发顺序，W0 基础卡最先）。
   - **送审（推荐）**：对另一个独立 Agent 会话说「用 [rules/story-review.md](rules/story-review.md) 的清单审查 STORY-xxx」→ 报告落 `docs/reviews/{迭代}/`，结论通过才把状态改「已确认」。不送审也能跑，但状态填了「已确认」校验器会强制要求报告——跳过必须显式。

### 迭代中

5. 对 Agent 说：*「用 detail-design 做 STORY-2026-S03-001」* → 产出 DD + OpenAPI + schema。
6. 对 Agent 说：*「用 test-spec-alignment 给 STORY-2026-S03-001 出 TS」*。
7. 对 Agent 说：*「用 feature-coding 实现 STORY-2026-S03-001，跑目标微服务测试（单仓库用 `mvn test -pl <service-module> -am`，多仓用 `mvn test`）」*。
8. **代码审查**：独立审查人按 [rules/code-review.md](rules/code-review.md) 审本次 diff（各实现 Skill 验证通过后会提示触发；档位与闭环见规则）。
9. 涉及本服务持久化/事务/下游契约保真的卡，追加：*「用 integration-test-design 给这张卡补单服务集成测试」*；IT 合入前的审查由该 Skill 按 [rules/code-review.md](rules/code-review.md) 提示触发。
10. 单卡完成后，提测前 QA 线三件（均以 Story 编号为入口）：*「用 qa-acceptance-case-design 为 STORY-2026-S03-001 出验收用例」* → 部署后 *「用 api-blackbox-test 为 STORY-2026-S03-001 生成黑盒脚本」* → 需要环境数据时 *「用 test-data-design 为 STORY-2026-S03-001 造数」*。

### 随时

- **出 bug**：*「用 bugfix 处理这个缺陷：现象 <…> / 预期 <…> / 实际 <…> / 复现步骤 <…> / 环境版本 <…>」*（输入不完整时 Skill 会先做五要素澄清，超 2 轮阻断）。
- **存量用例迁移**：*「用 legacy-test-migration 迁移 <用例导出文件>，目标模块 <module>」*。

> **触发格式**：*「用 <skill 名> <动作> <卡号或路径>」*——点名 skill 最稳，描述场景也能自动匹配（「给 STORY-xxx 写详设」）。关键是给出**卡号或路径**，Skill 会自己按「前置加载」清单去读上游工件；各 Skill 的触发示例见其 `SKILL.md` 文件头。

**迭代收尾**（迭代结束、下个迭代开始前，一个人做一次）：

1. 对 Agent 说：*「做 {迭代} 迭代收尾，生成归档摘要」* → AI 从 `docs/{requirements,design,test-spec,qa,reviews}/{迭代}/`、`docs/api/` 与画像「变更记录」（`architecture/system-landscape.md`，按本迭代起止日期过滤）聚合生成 `docs/archive/ARCHIVE-{迭代}-summary.md`（模板见 `templates/sprint-archive-template.md`），你确认后落盘；文件已存在时 AI 会先问是否覆盖，不静默重写。
2. 更新 `docs/agile/sprint-registry.yaml`：本迭代 `status: closed` + `closed_at: YYYY-MM-DD`（只改自己迭代那一行；表中无本迭代行则先补行——迭代开始时漏登记）。
3. 切换 `config/current-sprint` 到新迭代。

> **多人协作**：迭代收尾是单点动作，不在多人分支上并行收尾同一迭代；归档目录即索引（每个迭代一份 `docs/archive/ARCHIVE-{迭代}-summary.md`），没有共享清单文件要维护。

---

## AI 停下来时怎么办

| AI 的行为 | 含义 | 你要做的 |
|-----------|------|---------|
| 标记**阻断**并提问 | 缺的信息不可推断（如模块归属不明、契约冲突） | 补充事实或拍板；回答后 AI 继续 |
| 内容带 `[AI推断]` 标注 | 缺但可合理推断，AI 先干起来留了标记 | 审查时逐条确认，错了让它改并去标记 |
| 只给**提醒** | 记录在案的风险/待办，不挡流程 | 迭代回顾时看一眼 |
| 编码中发现要改 OpenAPI/schema 语义 | 对外契约变更 | 暂停并回 detail-design，人确认是否改契约 |
| 降级运行（如无词表、无方法论文档） | 前置资产缺失但流程可走 | 质量预期下调；补齐资产后恢复 |
| 产出工件前说「已存在，是否覆盖」 | 防静默覆盖约定 | 确认是否真的要重写 |

---

## 工件落点

| 内容 | 位置 |
|------|------|
| 工件缩写与落点 | 根 [README.md](../README.md) 的「工件速查」节 |
| 命名规则 | [docs/agile/card-naming-conventions.md](docs/agile/card-naming-conventions.md) |
