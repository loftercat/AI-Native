# Java 适配层（adapters/java.md）

> 配套 [legacy-test-migration SKILL](../../SKILL.md)。
> 核心分类标准与语言无关；本文件只提供 Java 生态的锚定与落点映射。首版可实跑。

## 1. 层 → 测试形态

| layer | 测试类命名 | 目录 | 说明 |
|-------|-----------|------|------|
| W1 | `*ServiceTest` | `{module}-impl/src/test/java/.../service/` | JUnit5 + Mockito，无 Spring 上下文 |
| W2 | `*ControllerTest` | `booking-bff-*/src/test/java/.../controller/` | `@WebMvcTest` + `MockMvc` |
| W3 | `*IT` | `booking-app/src/test/java/.../` | 继承 `AbstractIntegrationTest`，真实 Spring + H2/Testcontainers |
| W4 | `*ScenarioIT` | `booking-app/src/test/java/.../` | 多步骤业务链路 |
| W5 | `*MapperTest` | `{module}-impl/src/test/java/.../mapper/` | `@MybatisTest`（持久层切片） |
| W6 | 前端组件（另仓） | 前端仓 | Vitest |
| B1 | `tests/blackbox/*.py` | `tests/blackbox/` | pytest + `requests`，打部署态 |
| B3 | `tests/blackbox/*.py` | `tests/blackbox/` | 真实第三方联调 |
| B5 | `*IT` + seed | `booking-app/src/test` + `tests/data/` | 批处理/定时，配合 `test-data-design` |

## 2. Mock / DB 约定

| 场景 | 方案 |
|------|------|
| 其他域 `XxxApi` | Mockito `@Mock` |
| 外部系统（支付/车场/IoT） | Mock Client |
| W1 DB | Mock Mapper |
| W3/W4 DB | H2（`AbstractIntegrationTest`）或 Testcontainers + `@Sql` fixture |

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
