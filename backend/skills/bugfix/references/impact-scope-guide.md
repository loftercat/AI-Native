# 受影响测试范围分级规则（impact-scope-guide，微服务版）

> bugfix Skill Step 6 使用。按「改动符号的可见性与服务契约边界」判定，不按「文件位置」。
> 微服务底线：严禁跨服务依赖对方 `*-impl` 内部类；跨服务影响只经 `*-api` 远程契约 / 内部接口契约 / `*-common` 公共库传导。构建命令按画像 `§5.4 P-1`（单仓库多服务 vs 一服务一独立仓库）执行。

## 判定决策树

```text
改动的符号是什么？是否改变了对外/对内服务契约或公共库？
│
├─ 改本服务 *-impl 内部逻辑或内部类签名（未改变 *-api 远程契约 / 内部接口路径与报文）
│  → 仅跑本服务测试：
│    · 单仓库多服务（画像 P-1）：mvn -pl <service>/<impl> -am test
│    · 一服务一独立仓库（画像 P-1）：本仓执行 mvn test
│
├─ 改 *-api 远程契约接口 / DTO / 内部 OpenAPI 或 .proto（跨服务契约变）
│  → 跑本服务 + 所有消费该契约的下游/上游服务测试：
│    · 单仓库多服务：mvn -pl <本服务>,<消费服务1>,<消费服务2> -am test
│    · 一服务一独立仓库：先在本仓跑通 mvn test 并发布新契约制品/同步契约文档，
│      再在受影响服务仓逐个拉取并执行 mvn test（或触发 CI 验证）
│
├─ 改 booking-common（公共横切库，按画像 P-6）
│  → · 单仓库多服务：跑全量 mvn test
│    · 一服务一独立仓库：发版后触发所有消费服务仓回归测试
│
├─ 改外部公司级公共基础库（如 hema-common）
│  → 停下来，不归当前项目仓，交还人工
│
├─ 改持久化查询（如画像 P-3 选 MyBatis 时的 Mapper XML，或 JPA Query/SQL）
│  → 跑本服务测试 + 显式跑对应持久化测试类：
│    · 单仓库多服务：mvn -pl <service>/<impl> -am test -Dtest=<PersistenceTestClass>
│    · 一服务一独立仓库：mvn test -Dtest=<PersistenceTestClass>
│
└─ 改对外/对内接口契约（docs/api/）或跨服务联动逻辑
   → 额外跑 tests/blackbox 下相关黑盒脚本：
     pytest tests/blackbox/ -k <相关用例>
```

## 边界判定示例

| 改动 | 所在服务 | 契约是否变化 | 跑哪些测试 |
|------|----------|--------------|------------|
| `ParkingLotQueryService` private 方法或内部逻辑 | `inventory-impl` | 未变 | 仅库存服务（`inventory-impl`） |
| `ParkingLotQueryService.getLotDetail` 加回 null 守卫 | `inventory-impl` | 未变（内部方法体） | 仅库存服务（上下游通过远程契约隔离） |
| `InventoryClient` / `InventoryApi`（`inventory-api`）请求/响应 DTO 字段变 | `inventory-api` | **契约变化** | 库存服务 + 所有消费 `inventory-api` 的服务（如 BFF、订单服务） |
| `BookingErrorCode` 枚举项或横切工具类 | `booking-common` | 横切公共库 | 单仓全量 `mvn test` / 多仓触发消费服务回归 |
| `ParkingLotMapper.xml` SQL（MyBatis 栈） | `inventory-impl` | 本服务持久层 | 库存服务 + 该 Mapper 所有测试 |

## 跑测试的硬约束

- 失败时修**代码**，不修**测试断言**（BR-11）
- 禁止 `@Disabled` 跳过失败测试（BR-11）
- 循环计数器 > 3 → 交还人工（AC-08）

## 如何确认受影响的消费服务

1. 查画像 [system-landscape.md](../../../architecture/system-landscape.md) §3.6 跨服务通信矩阵，列出所有调用本服务的上游方
2. 单仓库多服务下可 Grep 契约接口/DTO 类名或运行 `mvn dependency:tree` 确认消费模块
3. 不确定影响面时按「涉及跨服务契约」处理（宁可多跑不可漏跑，必要时走部署后 `api-blackbox-test`）
