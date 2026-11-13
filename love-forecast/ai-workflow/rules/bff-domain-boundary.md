# BFF 与域 Service 边界

改 `love-app` 或 `*-impl` 前必读。完整流程见 [bff-domain-boundary-guide.md](../skills/detail-design/references/bff-domain-boundary-guide.md)。

## 两类职责

| 类型 | 落点 | 示例 |
|------|------|------|
| **守卫（guard）** | BFF `*Controller` | `isBlank(keyword)`、`endTime <= startTime`、未登录 |
| **领域规则** | `*-impl` `*Service` / `*Validator` / `util/` | normalize、匹配、推荐、状态机、时间窗 |

BFF **薄**：鉴权、守卫、`Result` 包装、VO 转换。**禁止** normalize/分词/匹配/状态机/库存锁定。

## 必守

1. **单点**：同一 BR/算法仅一处实现类；多域复用放 `love-common`
2. **禁止** BFF 与 `*-impl` 各建同名同职责工具类（如双份 `KeywordNormalizer`）
3. AC 影响层含 BFF + domain → 端到端验收；guard 在 BFF，算法在域，**不得双层各做一遍**
4. BFF 只注入 `XxxApi`；**禁止** 注入 impl 内 `*Service` / `*Mapper`
5. 详设 §8 双层重复 → **阻断**，回溯 `detail-design`

## 示例

```java
// ✅ BFF：AC-10 守卫
if (StringUtils.isBlank(keyword)) {
    return Result.fail(PARAM_ERROR, "请输入目的地或大厦名称");
}
return Result.success(toVo(parkingLotApi.searchBookableLots(keyword)));

// ❌ BFF：领域 normalize（应在 profile-impl KeywordNormalizer）
String normalized = KeywordNormalizer.normalize(keyword);
```
