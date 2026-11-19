# 项目布局与工作流边界

> 目的：工作流（方法 + 工件）与业务代码各有其位，不混放。布局唯一：模板整目录嵌入项目，新项目与存量项目同法。

## 一、五类资产

| 类型 | 内容 | 归属 |
|------|------|------|
| 工作流方法 | `AI-Native/{线}/` 下 `skills/`、`rules/`、`templates/`、`reference/`、`hooks/`、`scripts/`、`docs/{methodology,_golden}`（`training` 仅后端线） | 工作流层 |
| 项目上下文 | `AI-Native/{线}/` 下 `architecture/`（画像）、`glossary/`（词表）、`config/`（current-sprint） | 工作流层 |
| 项目产物 | `AI-Native/{线}/docs/{requirements,design,test-spec,qa,reviews,api,schema}` | 工作流层 |
| 可执行测试 | `AI-Native/{线}/tests/{blackbox,data}` | 工作流层 |
| 业务代码 | Maven 模块、构建文件 | **项目根**；路径以画像 §二 模块表为准 |

## 二、唯一布局（AI-Native 嵌入式）

模板整目录嵌入项目根（放入方式与项目根 `AGENTS.md` 的建法见仓库根 [README.md](../../README.md)「快速开始」）；存量项目原有代码不动。布局如下：

```text
{project}/
├── AGENTS.md            # 项目 AI 入口（建法见根 README「快速开始」）
├── README.md            # 项目自己的说明
├── {业务代码}            # Maven 模块等，在项目根生长（模块路径写进画像 §二）
└── AI-Native/           # 工作流层（模板整目录；升级时只对比替换通用层，工件目录不动）
    ├── backend/         # 后端线根：skills/rules/…/architecture/config + docs 工件 + tests
    │   └── MIGRATION.md # 后端线接入指南
    └── frontend/        # 前端线根（可选）
```

- 所有 Skill 与校验器按**线根**（`AI-Native/backend/`、`AI-Native/frontend/`）解析路径。
- Skill 找业务代码按画像 §二 的模块路径，不依赖目录巧合。
- **不要拆散 `AI-Native/`**：把 skills/ 或画像挪到项目其他位置会让线根路径约定与校验器失效；要调整就整层一起动，并同步项目根 `AGENTS.md` 的指路。

## 三、模板升级

母版（GitHub）通用层更新后，只把 `AI-Native/{线}/` 下的方法目录（`skills/`、`rules/`、`templates/`、`reference/`、`scripts/`、`docs/methodology` 等）与母版对比合并；`docs/{迭代工件}`、`architecture/`（画像）、`config/`、`glossary/` 是项目自己的，**不随模板覆盖**。

## 四、模块聚合（多域仓库推荐）

```text
{project}-{domain}/              # packaging=pom，仅聚合
├── {domain}-api/                # 契约：Api/DTO/枚举/错误码
└── {domain}-impl/               # 实现：Provider/Service/Client/Mapper
```

- 外层聚合模块保留项目前缀（如 `meeting-room`）；域内子模块可去前缀（`room-api`、`room-impl`），避免 `meeting-room/meeting-room-api` 重复。
- artifactId 与目录一致；依赖方向只允许 `impl → api`，BFF 只依赖 `*-api`。
- 嵌套模块构建用相对路径：`mvn -pl {project}-{domain}/{domain}-impl -am`；裸 artifactId 不会解析。
- 单域小仓库不必聚合；不要为了聚合造空模块或空 POM。

详细 Java 约束见 [java-project.md](java-project.md)。
