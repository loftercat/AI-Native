# 项目布局与工作流边界

> 目的：避免「工作流方法 / 项目上下文 / 项目产物 / 可执行测试」混放。布局二选一，不要半拆。

## 一、四类资产

| 类型 | 内容 | 归属 |
|------|------|------|
| 工作流方法 | `skills/`、`rules/`、`templates/`、`reference/`、`hooks/`、`scripts/`、`docs/methodology|training|_golden` | 工作流目录 |
| 项目上下文 | `architecture/`（画像）、`glossary/`（词表）、`config/`（current-sprint / sprint-registry） | 工作流目录 |
| 项目产物 | `docs/requirements|design|test-spec|qa|reviews|api|schema` | 工程目录 |
| 可执行测试 | `tests/blackbox`、`tests/data` | 工程目录 |
| 业务代码 | Maven 模块、构建文件 | 工程目录 |

## 二、两种布局

### 标准布局（默认，单线/小项目）

```text
{project}/
├── backend/                     # 后端线项目根
│   ├── skills/ rules/ templates/ reference/ hooks/ scripts/
│   ├── docs/{methodology,training,_golden}/
│   ├── architecture/ glossary/ config/
│   ├── docs/{requirements,design,test-spec,qa,reviews,api,schema}/
│   ├── tests/{blackbox,data}/
│   └── {maven-modules}/
└── frontend/                    # 前端线项目根，结构同源
```

所有 Skill 路径按**项目根**解析。

### 分离式布局（一个项目一个工作流实例）

```text
{project}/
├── ai-workflow/                 # 工作流实例
│   ├── skills/ rules/ templates/ reference/ hooks/ scripts/
│   ├── docs/{methodology,training,_golden}/
│   └── architecture/ glossary/ config/
├── backend/                     # 工程
│   ├── {maven-modules}/
│   ├── docs/{requirements,design,test-spec,qa,reviews,api,schema}/
│   └── tests/{blackbox,data}/
└── frontend/                    # 可选的另一条线，同样处理
```

路径解析：

- `architecture/...`、`glossary/...`、`config/...` → **工作流根**（`ai-workflow/`）
- `docs/...`、`tests/...` → **工程根**（如 `backend/`）
- Skill 只写逻辑路径，不写死 `../`；移动布局时只改「根映射」和校验器。

## 三、采用规则

- 单线、单人维护、工作流不单独交付 → **标准布局**，少一层。
- 多线（后端 + 前端）、或工作流本身要作为交付物 → **分离式**；多线必须**统一**拆分，不能只拆后端。
- **不要半拆**：只移 skills 不移 context，或只移 context 不改校验器，都会让路径解析分裂。
- 校验器必须同时识别两个根；必需目录缺失时 **fail-closed**，不能静默 `PASSED`。

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
