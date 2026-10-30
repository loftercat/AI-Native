# TDD 项目约定

## 技术栈

- Java 21、JUnit 5、Mockito、Spring Boot Test
- 构建：Maven（`mvn test` / `mvn test -pl {module}`）

## 流程

1. 读 Story AC → 写失败测试（红）
2. 最小实现（绿）
3. 重构，保持 diff 小

## 测试分层

| 层 | 路径 | 说明 |
|----|------|------|
| 域单元测试 | `*-impl/src/test/java/` | Service、状态机；Mock Mapper、`XxxApi`、Client |
| BFF API 测试 | `booking-bff-app/`、`booking-bff-admin/` 的 `src/test/java/` | `@WebMvcTest` + MockMvc；Mock 域 `XxxApi` |
| 启动集成 | `booking-app/src/test/java/`（按需） | `@SpringBootTest` 关键链路 |

**注意**：Controller 测试在 **BFF 模块**，不在 `*-impl`。

## 断言

- 对齐 Story AC 可见结果：HTTP 状态、`Result.code`、关键 `data` 字段
- 域测试：业务码、`BizException`、状态迁移
- 模块与类名以详设 §8 为准

## 需求变更

- 无 Story「变更记录」→ 拒绝偷偷改 AC
- 有变更记录 → 先改/删废弃测试，再红绿

## 与详设

- 先详设后编码；OpenAPI 与 Controller 路径一致
- V1 集成测试不依赖 Nacos / 外部支付真实环境（Mock Client）
