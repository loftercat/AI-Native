# AC → 用例映射指引（ac-to-case-guide）

> 配套 `test-spec-alignment` Skill。把 Story AC + 详设 §9 展开为**用例级**测试规格时的映射规则与常见坑。

## 1. 定位

回答三个问题，产出 TS §2~§6：

1. **每条 AC 测不测、在哪层测**（单元 / BFF API / Mapper / 集成）
2. **失败 AC 断言写什么**（具体 `code` / `message`，禁止「提示错误」）
3. **Fixture 给什么**（输入、Mock 返回、边界值）

## 2. AC → 用例归属规则

| AC 特征 | 归属层 | 理由 |
|---------|--------|------|
| 纯算法/规则（匹配、排序、窗口、状态判断） | 单元 `*ServiceTest` 或专用工具类 Test | 域内逻辑，Mock 依赖即可验证 |
| 领域业务成败（库存、状态机、错误码） | 单元（断言 `BizException.code`）+ 可选 Mapper 验证数据 | 错误码在 `*-api`，文案在 Story |
| HTTP 路由、参数校验、DTO 装配、鉴权 | BFF API `@WebMvcTest`（Mock 域 `XxxApi`） | 只测 BFF，不碰 DB |
| 数据过滤/映射 SQL（状态过滤、时间窗） | Mapper Test（真实 H2 + 种子） | SQL 语义须真库验证 |
| 跨模块串联 / 外部系统链路 | 集成 `@SpringBootTest`（可选） | 归 `integration-test-design` 消费 |
| 纯 UI / 地图 / 第三方页面 | **前端-only / N/A** | 本仓库不测，写 §5 标注 |

**判定顺序**：先看 AC 语义属于「HTTP 契约」「领域规则」「数据访问」「端到端」哪一类，再落到上表。同一条 AC 可拆多个层（如 AC-01 在单元+BFF 各一条用例）。

## 3. 失败 AC 断言写法

- **必须有具体断言**：`code=1601`、`message=「无可预约的车位」`。禁止「断言返回错误」「提示错误」。
- 文案来源：**Story AC 的 `Then` 优先**；Story 未给文案时查详设错误码表；两者都没有 → 写进 §6 缺口阻断，要求补 Story。
- 错误码三段式校验：
  ```java
  assertEquals(1601, ex.getCode());
  assertEquals("无可预约的车位", ex.getMessage());
  ```
- **HTTP 层**：本仓库 `Result` 业务失败 `code !== 200`，HTTP 层可为 200。断言写 `Result.code`，不写 HTTP 状态（除非 OpenAPI 明确 4xx）。

## 4. Fixture / 边界值设计

| 维度 | 必查边界 |
|------|----------|
| 字符串 | 空串 `""` vs `null` vs 仅空白 `"   "` vs 含多余空格 `华润  大厦` |
| 数值/距离 | 恰好阈值（100m）、等距多候选、0 个候选 |
| 时间 | `end == start`、`end < start`、跨日、营业时间边界 |
| 状态 | 空闲/锁定/占用/维护 各状态在结果中的去留 |
| 空数据 | 列表空、说明字段未配置（返回空串而非 500） |

每个边界给一行 `输入 → Mock/种子返回 → 期望`，`feature-coding` 直接照写。

## 5. 与详设 §9 的关系

- 详设 §9 给**类名 + AC 编号**粒度；本指引把它细化到**方法 + Given/When/Then 断言**。
- 详设 §9 没列的 AC：按 §2 归属表自行落层，仍须出现在 TS §2。
- 详设 §9 与 OpenAPI 错误码不一致 → §6 阻断，**不猜**。

## 6. 常见坑

| 坑 | 解法 |
|----|------|
| 把 BFF API 测试写成带 DB 的集成测试 | BFF `@WebMvcTest` Mock 域，不碰 DB |
| 失败 AC 只写「返回错误」 | 回 Story/详设找文案；找不到写 §6 阻断 |
| 所有 AC 堆到一个 `@SpringBootTest` | 按 §2 分层归属，越底层越多 |
| 断言 HTTP 500 而非 `Result.code` | 本仓库业务失败 HTTP 层可为 200，断言 `Result` |
| 遗漏「前端-only」AC 的 Java 测试 | 标 §5 N/A，`feature-coding` 不写 |
