# AGENTS.md：new-ai-workflow-template 仓库入口

本仓库是 **AI 原生开发工作流模板**（自已落地的源项目（后端仓 + C 端小程序仓）抽取通用化），不是一个可运行的业务项目。双线结构：`backend/` 后端线（12 Skill）、`frontend/` 前端线（3 Skill，消费后端 handoff 契约）。流水线见 [README.md](README.md)；接入方法见 [MIGRATION.md](MIGRATION.md)。

## 在本仓库内工作时

- **修改 Skill / Rule**：遵循单点维护——项目事实只写各线 `architecture/system-landscape.md`，Skill 与 Rule 引用不复制；改完跑对应线校验器，新增文件必须 UTF-8。
- **不要在本仓库造业务工件**：`{backend,frontend}/docs/*` 只放 `_golden/` 样例；接入项目后才会在迭代目录下产真实工件。
- **保持 Skill 自包含**：templates/ 与 references/ 随 SKILL.md 同目录；引用外部文档用相对路径且须可达（校验器管链接，tick 提及仅 WARN）。
- **项目示例值是有意的**：`booking-*` 模块名、`com.hema` 包名、错误码号段、`booking-bff-app.yaml` 等保留作示例（每个 SKILL.md 顶部有「模板版说明」）；不要在模板里"替换掉它们"，替换发生在接入项目时（清单见 MIGRATION.md §一.2 与 §四）。

## Skill 与 Rule 的分工

**规范听 Rule（`rules/`），流程听 Skill（`skills/`）**：Rule 管跨阶段的编码与文档规范（分层、异常、测试、布局、审查），Skill 管端到端流程（触发时机、产出物、何时阻断）。冲突时对「怎么写代码」听 Rule，对「先做什么后做什么」听 Skill。项目布局见 [backend/rules/project-layout.md](backend/rules/project-layout.md)。

## 代码审查

代码改动（`feature-coding` / `bugfix` / `frontend-feature-coding` 的测试通过后，`integration-test-design` 的 IT 代码合入前，以及 `api-blackbox-test` / `test-data-design` 生成的 pytest/seed 脚本）必须走独立代码审查，规则见 [backend/rules/code-review.md](backend/rules/code-review.md)，报告模板见 [backend/templates/code-review-report.md](backend/templates/code-review-report.md)。以下链接是模板仓库布局；接入项目后按实际分发布局调整。

**文档工件同样送审**：JSD / HLD / DD / TS 在进入下一环之前，由独立上下文审一次，规则见 [backend/rules/artifact-review.md](backend/rules/artifact-review.md)（每阶段三项必查、最多 5 条 findings、P0/P1 必修、限时 15–20 分钟）。

- 先跑自动门禁（`mvn test` / 前端测试 / 校验器 / 链接检查），不过不送审。
- 档位：L0 文档/路径/重命名/目录移动/构建描述符（无运行时逻辑）不派 agent；L1 ≤3 文件；L2 一般功能；L3 核心链路/DDL/跨模块契约。机械改动不因文件数升档。
- 同一批改动只审一次；L1–L3 分别 ≤10/20/30 分钟；最多 5 条 findings；不默认复审，连续 2 轮不通过交还人工。
- 审查通过前禁止 commit/push；报告落 `docs/reviews/{迭代}/REVIEW-CODE-{阶段}-*`（IMPL/IT/FIX/FE/BB/SEED 分阶段，避免覆盖）。
- 审查人只读（独立 AI 会话 / 审查 agent / 人）；L0 不落报告，在回复/提交说明写自动门禁结果。
- 审查流程不绑定具体 Agent：任意独立审查人读取项目 `AGENTS.md` 与本规则即可执行；接入项目时把本节复制到项目 `AGENTS.md`。

## 常用命令

```bash
bash backend/scripts/validate-skills.sh    # 后端线校验
bash frontend/scripts/validate-skills.sh   # 前端线校验
```
