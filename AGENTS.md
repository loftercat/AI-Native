# AGENTS.md：AI-Native-template 仓库入口

本仓库是 **AI 原生开发工作流模板**，不是一个可运行的业务项目。双线结构：`backend/` 后端线、`frontend/` 前端线（消费后端 handoff 契约）。流水线见 [README.md](README.md)；接入方法后端见 [backend/MIGRATION.md](backend/MIGRATION.md)、前端见 [frontend/MIGRATION.md](frontend/MIGRATION.md)。

## 在本仓库内工作时

- **修改 Skill / Rule**：遵循单点维护——项目事实只写各线 `architecture/system-landscape.md`，Skill 与 Rule 引用不复制；改完跑对应线校验器，新增文件必须 UTF-8。
- **不要在本仓库造业务工件**：`{backend,frontend,flutter}/docs/*` 只放 `_golden/` 样例；接入项目后才会在迭代目录下产真实工件。
- **保持 Skill 自包含**：templates/ 与 references/ 随 SKILL.md 同目录；引用外部文档用相对路径且须可达（校验器管链接，tick 提及仅 WARN）。
- **修改画像模板**：`architecture/system-landscape.md` 是模板时，保留被 Skill 引用的小节编号（§3.7 错误码号段、§4.3.4 测试账号约定、§4.7 责任域定位）——Skill 按编号读画像，编号漂移锚点就断。接入后的画像变更须按 [backend/rules/system-landscape-change.md](backend/rules/system-landscape-change.md) 回刷派生项。
- **项目示例值是有意的**：`booking-*` 模块名、`com.hema` 包名、错误码号段、`booking-bff-app.yaml` 等保留作示例（每个 SKILL.md 顶部有「模板版说明」）；不要在模板里"替换掉它们"，替换发生在接入项目时（锚点处理见 backend/MIGRATION.md §一.3）。

## 接入引导（AI 主导）

用户表达接入意图（如「帮我接入这套工作流」）时，AI 按以下序列引导，人只在各介入点决策。到达介入点时自报进度（「第 X/N 个确认点」，让人始终知道还剩几个决策）：

0. **定位模板**：会话不在模板仓时（如已开在目标项目），请用户提供模板仓路径，读取该路径下 AGENTS.md 的本节后继续。
1. **探测优先，能不问就不问**：探测**目标项目根**（用户已给路径时用该路径；会话开在模板仓时先取得目标根再探测）——空目录 → 新项目；有代码 → 已有代码项目；已有 `AI-Native/` → 阻断确认是否重复接入；已有 `AGENTS.md` → 走整合。仅探测有歧义或用户主动说明时才问形态与路径。
2. **引入**：按根 [README.md](README.md)「快速开始」步骤 1 执行（复制模板、命名 `AI-Native/`、建/整合项目根 AGENTS.md、链接加前缀）；目标目录非 git 仓库时提议 `git init`（接入完成即首提交）。
3. **接入**：问接哪条线（后端 / 前端 / 都接，都接时先后端、再前端——契约单向流）。后端读 [backend/MIGRATION.md](backend/MIGRATION.md) 按任务书执行——画像步骤新项目走访谈、存量走扫码起草（§一.2 表）；介入点停下等人；前端读 [frontend/MIGRATION.md](frontend/MIGRATION.md)——handoff 包缺失时向用户提问（去后端拿 / 先后补），同样在介入点停下。分发方式与裁剪选项打包为一次收尾提问，不逐项问。分支细节住在各指南，本节只做路由，不复制。
4. **验收**：跑对应线校验器（tick 类 WARN 用 `--quiet-tick` 只看计数）与指南内验收命令，交报告给人确认。

## Skill 与 Rule 的分工

**规范听 Rule（`rules/`），流程听 Skill（`skills/`）**：Rule 管跨阶段的编码与文档规范（分层、异常、测试、布局、审查），Skill 管端到端流程（触发时机、产出物、何时阻断）。冲突时对「怎么写代码」听 Rule，对「先做什么后做什么」听 Skill。项目布局见 [backend/rules/project-layout.md](backend/rules/project-layout.md)。

## 代码审查

代码与文档工件都必须独立审查；规则以三份 Rule 为准（接入项目后按实际分发布局调整链接）：

| 对象 | 规则 | 报告落点 |
|------|------|----------|
| 代码：`feature-coding` / `bugfix` / `frontend-feature-coding` / IT / 黑盒 / 造数脚本 | [backend/rules/code-review.md](backend/rules/code-review.md) | `docs/reviews/{迭代}/REVIEW-CODE-{阶段}-*`（IMPL/IT/FIX/FE/BB/SEED） |
| Story：拆卡后、进详设前 | [backend/rules/story-review.md](backend/rules/story-review.md) | `docs/reviews/{迭代}/REVIEW-STORY-{迭代}-{序号}-{slug}.md`；「已确认」须有通过报告 |
| 阶段工件：JSD / HLD / DD / TS | [backend/rules/artifact-review.md](backend/rules/artifact-review.md) | `docs/reviews/{迭代}/REVIEW-{JSD\|HLD\|DD\|TS}-{slug}.md` |

- 先跑自动门禁（`mvn test` / 前端测试 / 校验器 / 链接检查），不过不送审。
- 档位 L0–L3、P0–P3 闭环、审查时限与复审策略以 `code-review.md` 为准；L0 文档/路径/机械改动不派 agent，在回复或提交说明写自动门禁结果。
- 审查通过前禁止 commit/push；审查人只读，可为独立 AI 会话 / 审查 agent / 人，不绑定具体 Agent。
- 接入项目时用 `templates/AGENTS.template.md` 生成项目 `AGENTS.md`，不要直接复制本文件。

## 常用命令

```bash
bash flutter/scripts/validate-skills.sh    # Flutter 线校验
bash backend/scripts/validate-skills.sh    # 后端线校验
bash frontend/scripts/validate-skills.sh   # 前端线校验
```
