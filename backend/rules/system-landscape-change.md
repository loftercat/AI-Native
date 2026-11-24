# 系统画像变更约束

画像（`architecture/system-landscape.md`）是项目层事实与微服务技术选型的唯一定义处。它的变更会传导到已生成的 `skills/`、`rules/` 与 Golden——**改动画像就欠一次回刷**：漏刷不会报错，只会静默漂移。

## 一、回刷对照

### 1.1 项目事实变更

| 画像变更 | 需回刷的派生项 |
|----------|---------------|
| §二 服务清单（服务名/数量/数据归属） | `skills/`、`rules/` 中的服务/模块名引用（锚点替换的映射结果）；Golden 中的服务名 |
| §3.6 跨服务通信矩阵 | 仅使用期消费（详设调用关系、单服务 `*IT` 下游模拟清单），无需回刷通用 Rule |
| §3.7 错误码号段 | `skills/`、`rules/exception-and-result.md` 中的号段描述与 `*ErrorCode` 示例 |
| §六 URL 前缀 | `skills/`、`rules/java-project.md` 中的 URL 示例 |
| §二 业务域（域数量/命名） | Golden 全族重写；词表同步 |
| §4.3.4 测试账号 / §四 外部系统 | 仅使用期消费（造数、集成 Mock 边界），无需回刷 |

### 1.2 微服务技术选型占位拍板回刷（画像 §5.4）

当画像 §5.4 中的任意项从 `[TBD]` 拍板定稿或发生切换时，按此表回刷派生规范：

| 占位编号 | 选型项 | 需回刷的派生项 |
|----------|--------|----------------|
| **P-1** | 仓库组织模式（单仓多服务 / 多仓） | `rules/project-layout.md`、`AGENTS.md`、多仓模式下的文档总仓与契约同步约定 |
| **P-2** | 服务间同步调用协议（OpenFeign / Dubbo / gRPC 等） | `rules/java-project.md`、`rules/bff-domain-boundary.md`、`rules/integration-test-conventions.md`（下游模拟方式）、`skills/detail-design/references/code-skeleton-guide.md`、`skills/feature-coding/references/layer-guides.md` |
| **P-3** | 数据库访问框架（ORM） | 选 MyBatis → 确认启用 `rules/mybatis-conventions.md`；选 JPA/jOOQ 等 → 替换 `rules/mybatis-conventions.md` 并同步 `rules/integration-test-conventions.md`、`skills/detail-design/references/schema-conventions.md` 与 `feature-coding` 引用 |
| **P-4** | 响应格式与跨服务错误码规则 | 画像 §3.7、`rules/exception-and-result.md`、`reference/exception-and-result.md` |
| **P-5** | 内部接口防外泄与服务间鉴权 | `rules/java-project.md`、`AGENTS.md`、`skills/detail-design/references/code-skeleton-guide.md` |
| **P-6** | 公共库边界（`*-common`） | `rules/java-project.md`、`AGENTS.md`、`hooks/bugfix-protect-common.sh` 保护路径 |
| **E-1** | 服务注册与配置中心 | `rules/integration-test-conventions.md`、`rules/tdd-project-conventions.md`（测试环境关闭注册配置的方式） |
| **E-2 / E-3 / E-4** | 异步消息 / 跨服务一致性 / 事件契约 | `skills/detail-design/references/special-scenarios.md`、`reference/idempotency-guide.md`（按需补充项目级异步与一致性落地细则） |
| **E-5** | 自动化接口契约测试 | `rules/integration-test-conventions.md`、`skills/integration-test-design/SKILL.md` |
| **E-6** | 多实例定时任务防重方案 | `reference/scheduled-task-guide.md`（注明项目选定的锁/调度框架） |
| **E-7** | 调用链追踪与日志排查 | `skills/bugfix/SKILL.md`（排障入口说明）、`AGENTS.md`（按需） |

## 二、变更记录

画像末尾「变更记录」表的**影响面**列标注本次变更需回刷哪些派生项（无影响写「无」）；未标注时按上表推导。

## 三、验证

回刷后：

- 跑 `bash scripts/validate-skills.sh`（硬断链与画像小节编号检查）
- 跑 [MIGRATION.md](../MIGRATION.md) §一.3 的残留检查（用映射表中未被目标选用的旧值构造 grep）

## 四、与单点维护的关系

项目事实与微服务技术选型只写画像（见 [AGENTS.md](../../AGENTS.md)）；本约束是「单点维护」的操作细则——Skill 与 Rule 引用画像而不复制正文，所以画像变更只需按上表回刷派生引用，不必追着十几个文件改正文。画像被 Skill 与校验器引用的小节编号（`§3.7` / `§4.3.4` / `§4.7` / `§5.4`）不得改动，编号漂移锚点即断。
