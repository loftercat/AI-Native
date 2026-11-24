# Java 适配层（adapters/java.md）

> 配套 [legacy-test-migration SKILL](../../SKILL.md)。
> 核心分类标准与语言无关；本文件只提供 Java 生态的锚定与落点映射。首版可实跑。

## 1. 层 → 测试形态

| layer | 测试类命名 | 目录 | 说明 |
|-------|-----------|------|------|
| W1 | `*ServiceTest` | `{module}-impl/src/test/java/.../service/` | JUnit5 + Mockito，无 Spring 上下文 |
| W2 | `*ControllerTest` | 各 BFF / 领域服务 `src/test/java/.../` | `@WebMvcTest` + `MockMvc` |
| W3 | `*IT` | 各微服务 `{service}-impl/src/test/java/.../` | 继承本服务 `AbstractIntegrationTest`，真实 Spring + Testcontainers MySQL + 下游模拟桩 |
| W4 | `*ScenarioIT` | 各微服务 `{service}-impl/src/test/java/.../`（跨服务主流程归 B1） | 单服务内多步骤业务链路 |
| W5 | `*MapperTest` / `*RepositoryTest` | `{service}-impl/src/test/java/.../` | 持久层切片（按画像 §5.4 P-3 ORM 选型） |
| W6 | 前端组件（另仓） | 前端仓 | Vitest |
| B1 | `tests/blackbox/*.py` | `tests/blackbox/` | pytest + `requests`，打部署态（含跨微服务主链路） |
| B3 | `tests/blackbox/*.py` | `tests/blackbox/` | 真实第三方联调 |
| B5 | `*IT` + seed | 归属微服务 `src/test` + `tests/data/` | 批处理/定时，配合 `test-data-design` |

## 2. Mock / DB 约定

| 场景 | 方案 |
|------|------|
| 进程外下游微服务 | 单测层 Mockito `@Mock`；单服务 `*IT` 按画像 §5.4 P-2 用 WireMock 或 RPC Stub |
| 外部系统（支付/车场/IoT） | Mock Client 或 WireMock |
| W1 DB | Mock 持久化层 |
| W3/W4 DB | 本服务独立 Testcontainers MySQL + Flyway + `@Sql` fixture |

## 3. 锚定信号（Step 4）

| 用例线索 | Java 锚点 |
|----------|-----------|
| 接口路径 | `@RequestMapping`/`@GetMapping` 方法 |
| operationId | Controller 方法名 |
| DTO 字段 | `*DTO`/`*Request`/`*Response` 的 getter/record 组件 |
| 错误码/文案 | `BookingErrorCode` / `*ErrorCode` 枚举项 |
| 表 / 字段 | Mapper XML `id` / DO 字段 |
| 业务动作 | `*Service` / `*Facade` 方法 |

## 4. 与仓库约定对齐

- 见 `skills/feature-coding/`、`rules/integration-test-conventions.md`、`rules/mybatis-conventions.md`
- `coverage` 填方法名（如 `SpaceQueryService#query`），不创建文件
