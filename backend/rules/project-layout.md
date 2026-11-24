# 项目布局与工作流边界（微服务版）

> 目的：工作流（方法 + 工件）与业务代码各有其位，不混放。仓库组织模式（单仓库多服务 vs 一服务一独立仓库）不在模板写死，接入时按画像 [system-landscape.md](../architecture/system-landscape.md) §5.4 P-1 选定后落地。

## 一、五类资产

| 类型 | 内容 | 归属 |
|------|------|------|
| 工作流方法 | `AI-Native/{线}/` 下 `skills/`、`rules/`、`templates/`、`reference/`、`hooks/`、`scripts/`、`docs/{methodology,agile,training,_golden}`（`agile`、`training` 仅后端线） | 工作流层 |
| 项目上下文（线根） | `AI-Native/{线}/` 下 `architecture/`（画像）、`glossary/`（词表）、`config/`（current-sprint）；前端 `docs/{handoff,prototype}`（契约快照与设计稿） | 工作流层（项目数据，模板升级不覆盖） |
| 项目产物 | **项目根** `docs/{requirements,design,test-spec,qa,reviews,api,schema,archive}`；前端线为前端工程根 `docs/{requirements,design,reviews}` | **项目根**（多仓模式下跨服务总文档归文档总仓，见 §四） |
| 可执行测试 | **项目根** `tests/{blackbox,data}` | **项目根**（或独立 QA/总仓） |
| 业务代码 | 网关、BFF、领域微服务工程与构建文件 | 路径以画像 §二 服务表为准 |

## 二、标准布局（AI-Native 嵌入式）

模板整目录嵌入项目根（放入方式与项目根 `AGENTS.md` 的建法见仓库根 [README.md](../../README.md)「快速开始」）；存量项目原有代码不动。

### 模式 A：单仓库多服务（画像 P-1 默认推荐）

多个微服务放在同一个 Git 仓库中，文档与工作流统一放在仓库根：

```text
{project}/
├── AGENTS.md                  # 项目 AI 入口（建法见根 README「快速开始」）
├── README.md                  # 项目自己的说明
├── docs/                      # 项目工件：requirements / design / test-spec / qa / reviews / api / schema / archive
├── tests/                     # 跨服务可执行测试：blackbox / data
├── {project}-gateway/         # 可选：API 网关服务（独立启动）
├── {project}-bff-app/         # C 端 BFF 服务（独立启动，对外 HTTP）
├── {project}-bff-admin/       # B 端 BFF 服务（独立启动，对外 HTTP）
├── {project}-{domain}/        # 领域微服务聚合目录（packaging=pom）
│   ├── {domain}-api/          # 契约包：远程客户端接口、DTO、域错误码、事件对象
│   └── {domain}-impl/         # 独立启动服务：内部接口入口、业务逻辑、独立 DB 迁移脚本与 *IT
├── {project}-common/          # 横切公共库（受画像 §5.4 P-6 边界约束）
└── AI-Native/                 # 工作流层（模板整目录；升级时只对比替换通用层）
    ├── backend/               # 后端线根
    └── frontend/              # 前端线根（可选）
```

### 模式 B：一服务一独立仓库（画像 P-1 选择多仓时）

每个微服务独占一个 Git 仓库；接入时须在画像 §5.4 P-1 明确以下 3 项并同步本节：

1. **跨服务文档总仓**：EPIC / JSD / HLD / 跨服务迭代索引与 `sprint-registry.yaml` 的存放仓库与目录路径。
2. **契约跨仓同步方式**：`*-api`（如发布私服 Maven 制品）与 `docs/api/{服务标识}/` 接口文档如何在提供方与调用方仓库之间同步与锁定版本。
3. **工作流与校验复用**：每个服务仓引入 `AI-Native/backend/` 子集或通过统一同步脚本分发，服务内 Story / DD / TS / 审查报告落本服务仓 `docs/`，`validate-skills.sh` 在各仓独立执行。

### 通用路径约定

- **工作流资产按线根**（`AI-Native/backend/`、`AI-Native/frontend/`）解析：`skills/`、`rules/`、`docs/{methodology,agile,training}`、`docs/**/_golden`、前端 `docs/{handoff,prototype}` 均相对线根。
- **工件按项目根**解析：`docs/{requirements,design,test-spec,qa,reviews,api,schema,archive}` 与 `tests/{blackbox,data}` 相对项目根；前端线为**前端工程根** `docs/{requirements,design,reviews}`（与 `pages/` 同级）。
- **后端线校验器**同时扫描线根 `docs/`（模板仓自检）与项目根 `docs/`（接入后工件）；线根出现非 `_golden` 工件会提示迁移（前端线校验器只查链接，无 Story 门禁）。
- Skill 找业务代码按画像 §二 的服务路径，不依赖目录巧合。
- **不要拆散 `AI-Native/`**：把 skills/ 或画像挪到项目其他位置会让线根路径约定与校验器失效；要调整就整层一起动，并同步项目根 `AGENTS.md` 的指路。

## 三、模板升级

母版（GitHub）通用层更新后，只把 `AI-Native/{线}/` 下的方法目录（`skills/`、`rules/`、`templates/`、`reference/`、`scripts/`、`docs/methodology` 等）与母版对比合并；`architecture/`（画像）、`config/`、`glossary/`、`docs/**/_golden`（已按项目业务重写，视为项目资产）、`docs/agile/sprint-registry.yaml`（迭代状态是项目数据）、前端 `docs/{handoff,prototype}` 与项目根 `docs/`、`tests/` 是项目自己的，**不随模板覆盖**。

## 四、领域微服务模块聚合

```text
{project}-{domain}/              # packaging=pom，仅聚合
├── {domain}-api/                # 契约：远程接口/客户端、DTO、枚举、域错误码
└── {domain}-impl/               # 独立启动服务：内部远程入口/Service/Client/持久化 + 独立 DB 迁移 + *IT
```

- 外层聚合目录保留项目前缀（如 `meeting-room`）；内部子模块可去前缀（`room-api`、`room-impl`），避免 `meeting-room/meeting-room-api` 重复。
- artifactId 与目录一致；依赖方向只允许 `impl → api`，其他服务与 BFF 只能依赖 `*-api`，**严禁依赖其他服务的 `*-impl`**。
- 每个领域服务的 `{domain}-impl` 与每个 BFF 均为独立可执行服务；单仓库多服务下构建指定服务用相对路径：`mvn test -pl {project}-{domain}/{domain}-impl -am`（裸 artifactId 不会解析）。
- 仅单一简单服务可不设聚合目录；不要为了聚合造空模块或空 POM。

详细 Java 微服务约束见 [java-project.md](java-project.md)。
