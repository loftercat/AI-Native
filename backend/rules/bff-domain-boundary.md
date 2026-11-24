# BFF 与领域微服务边界

改 `booking-bff-*` 或领域微服务 `*-impl` 前必读。完整流程见 [bff-domain-boundary-guide.md](../skills/detail-design/references/bff-domain-boundary-guide.md)。

## 两类职责

| 类型 | 落点 | 示例 |
|------|------|------|
| **守卫与聚合（guard / BFF）** | 独立 BFF 服务 `*Controller` / 聚合层 | `isBlank(keyword)`、`endTime <= startTime`、用户鉴权、多服务读数据组装、VO 转换 |
| **领域规则（domain）** | 领域微服务 `*-impl` `*Service` / `*Validator` / `util/` | normalize、匹配、推荐、状态机、库存锁定、写操作幂等与一致性编排 |

BFF 保持**薄**：只负责对外 HTTP 入口、鉴权、参数守卫、读聚合与 VO 转换，**无独立业务数据库**。**禁止**在 BFF 写核心领域算法（normalize/匹配/推荐）、状态机推进、库存锁定或跨服务复杂写事务编排。

## 必守

1. **单点实现**：同一 BR/算法仅在归属领域微服务中实现一次；多服务复用的纯技术工具按画像 §5.4 **P-6** 边界放入 `booking-common`（严禁放业务 DTO/逻辑）。
2. **禁止重复造工具**：禁止 BFF 与 `*-impl` 各建同名同职责业务工具类（如双份 `KeywordNormalizer`）。
3. **端到端验收不双做**：AC 影响层含 BFF + 领域服务时，guard 在 BFF，业务规则在领域服务，**不得双层各做一遍**。
4. **仅经远程契约调用**：BFF 仅通过 `*-api` 定义的远程客户端（协议见画像 §5.4 **P-2**，如 OpenFeign / Dubbo / gRPC）经 `client/` 封装调用领域服务；**严禁**依赖任何领域服务的 `*-impl`。
5. **详设拦截**：详设 §8 出现 BFF 与领域服务双层重复实现或越界写编排 → **阻断**，回溯 `detail-design`。

## 示例

```java
// ✅ BFF：AC-10 参数守卫 + 经远程客户端调用领域服务
if (StringUtils.isBlank(keyword)) {
    throw new BizException(BookingErrorCode.INVALID_KEYWORD);
}
return Result.success(toVo(inventoryClient.searchBookableLots(keyword)));

// ❌ BFF：直接写领域 normalize 或本地状态机（应下沉至领域微服务 *-impl）
String normalized = KeywordNormalizer.normalize(keyword);
```
