# TDD 项目约定（微服务版）

## 技术栈

- Java + JUnit 5 + Mockito + Spring Boot Test（具体版本、ORM 与调用协议见 [system-landscape.md](../architecture/system-landscape.md) §5.1 / §5.4）
- 构建：Maven（单仓库多服务用 `mvn test -pl {service-module} -am`；独立仓库直接 `mvn test`）

## 流程

1. 读 Story AC → 写失败测试（红）
2. 最小实现（绿）
3. 重构，保持 diff 小

## 测试分层

| 层 | 路径 | 说明 |
|----|------|------|
| 服务单元测试 | 各领域服务 `*-impl/src/test/java/` | Service、Facade、状态机；Mock 持久化层、下游远程客户端、外部 Client；**无 DB** |
| 入口 API 测试 | 各 BFF 或领域服务 `src/test/java/` | `@WebMvcTest` / `@SpringBootTest(MOCK)` + MockMvc；Mock 下游远程客户端或 Service；**无 DB** |
| 单服务集成测试 | 各微服务 `src/test/java/`（按需，归 `integration-test-design`） | `@SpringBootTest` 本服务真实链路 + 独立容器 DB；下游微服务模拟隔离 |
| 跨服务主链路验证 | `tests/blackbox/`（部署后，归 `api-blackbox-test`） | 多服务真实联调与主流程验收 |

**注意**：对外 HTTP Controller 测试在 BFF 服务，内部远程入口测试在对应领域服务 `*-impl`；禁止跨服务测试耦合。

## 断言

- 对齐 Story AC 可见结果：响应状态、业务码与关键返回字段（响应格式以画像 §3.7 为准）
- 领域服务测试：业务码、异常语义、状态迁移、向下游发起的远程调用参数
- 服务与类名以详设 §8 为准

## 需求变更

- 无 Story「变更记录」→ 拒绝偷偷改 AC
- 有变更记录 → 先改/删废弃测试，再红绿

## 与详设及环境隔离

- 先详设后编码；对外/对内接口契约与实现路径一致
- 单服务单元测试与集成测试必须关闭服务注册发现（按画像 §5.4 E-1），不依赖外部注册中心、真实下游服务或真实第三方环境
