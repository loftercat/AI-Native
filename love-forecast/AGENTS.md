# AGENTS.md：恋爱预见（love-forecast）项目入口

**恋爱预见**是一个 Web 端亲密关系沟通辅助工具：用户描述情境，系统给出三档可执行的回复建议；可选导入历史聊天记录，让建议更贴合这个具体的人。技术栈 Java 21 + Spring Boot 3.2 + Spring AI + MySQL。

## 目录与路径解析

本项目采用**分离式布局**：工作流在一个目录，工程在另一个目录。

```text
love-forecast/
├── ai-workflow/     # 工作流实例：skills / rules / templates / reference / hooks / scripts
│                    #             architecture / glossary / config
│                    #             docs/{methodology,training,agile} + 各产物目录下的 _golden
├── backend/         # 工程：代码模块、docs/{requirements,design,api,schema,test-spec,qa,reviews}、tests
├── AGENTS.md        # 本文件
└── MIGRATION.md     # 模板接入清单（Skill 相对链接需要）
```

**Skill 里写的是逻辑路径，按两个根解析**：

| 逻辑路径 | 实际位置 |
|---------|---------|
| `architecture/...`、`glossary/...`、`config/...` | `ai-workflow/` |
| `docs/methodology`、`docs/training`、`docs/**/_golden` | `ai-workflow/docs/` |
| `docs/requirements`、`docs/design`、`docs/api`、`docs/schema`、`docs/test-spec`、`docs/qa`、`docs/reviews`、`tests/...` | `backend/` |
| 业务代码 | `backend/{module}/` |

## 项目事实的唯一来源

模块名、错误码号段、测试账号、外部系统边界，只在 [ai-workflow/architecture/system-landscape.md](ai-workflow/architecture/system-landscape.md) 定义。Skill 与 Rule 引用它，不复制。

本目录是独立项目根，与 `new-ai-workflow-template/backend/` 无引用关系；模板升级时人工比对，不自动同步。

## 流水线入口

按手上资产选入口，不必从头走：

| 手上有什么 | 用哪个 Skill | 产出 |
|-----------|-------------|------|
| PRD / 原始需求 | `journey-scenario-design` | JSD |
| Epic / PRD 定稿 | `high-level-design` | HLD |
| HLD / Story 卡 | `story-splitting` | Story |
| Story 卡 | `detail-design` | DD + OpenAPI + schema |
| DD 完成 | `test-spec-alignment` | TS |
| TS 就绪 | `feature-coding` | 代码 + 测试 |

当前迭代见 `ai-workflow/config/current-sprint`（`2026-S01`）；迭代级工件的落盘路径从这里取。

## 前置阻断

进入流水线前必须满足：

- **PRD 就绪**：有角色与端、业务目标、核心能力、非目标。
- **系统画像已接入**：`ai-workflow/architecture/system-landscape.md` 已用本项目事实填写，不含 `{项目名}` 占位符或 `（示例）` 标注。

不满足则停下补，不要用 `[AI推断]` 补画像——画像推断错，下游模块归属全部错位。

## 代码审查

代码改动必须走独立审查，规则见 [ai-workflow/rules/code-review.md](ai-workflow/rules/code-review.md)，报告模板见 [ai-workflow/templates/code-review-report.md](ai-workflow/templates/code-review-report.md)。

- 先跑自动门禁（`mvn test` / 校验器），不过不送审。
- 档位：L0 文档/路径/机械改动不派 agent；L1 ≤3 文件；L2 一般功能；L3 核心链路/DDL/跨模块契约。
- 同一批只审一次；L1–L3 分别 ≤10/20/30 分钟；最多 5 条 findings。
- 审查通过前禁止 commit / push；报告落 `backend/docs/reviews/{迭代}/REVIEW-CODE-{阶段}-*`。

## 产品层硬约束

1. **不做人格判断**。只输出可复算的行为计数与原句，不输出类型标签、特质分数、临床结论。依据 [persona-analysis-standard.md](backend/docs/requirements/epics/persona-analysis-standard.md)。
2. **建议不基于人格**。个性化只来自行为模式与用户自身语言习惯。
3. **不要求对方同意**。用户本人授权即可，导入页明确告知风险。
4. **事实与推断分离**。爱好、职业、经历只能来自用户显式陈述，禁止从语言风格反推。

## 常用命令

```bash
# 工作流资产校验
cd ai-workflow && bash scripts/validate-skills.sh

# 工程命令（代码建好后在 backend/ 下）
cd backend
mvn -DskipTests install
mvn -pl love-app spring-boot:run     # localhost:8080
mvn test
```
