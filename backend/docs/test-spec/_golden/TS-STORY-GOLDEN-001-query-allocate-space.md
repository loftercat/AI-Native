# TS-STORY-GOLDEN-001-query-allocate-space

| 字段 | 值 |
|------|-----|
| 迭代 | GOLDEN（范本） |
| 状态 | 已确认（范本） |
| 来源 | STORY-GOLDEN-001-query-allocate-space.md（AC-01~09） · DD-STORY-2026-S01-001-query-allocate-space.md §9 · OpenAPI `docs/api/booking-bff-app/` |
| 服务/模块 | booking-bff-app、booking-inventory |
| 复杂度 | 中等 |

> **范本说明**：演示 TS 文档结构与粒度（用例级 AC→用例追溯 + 分层矩阵 + Fixture + N/A 标注 + 缺口）。源自真实详设 DD-STORY-2026-S01-001-query-allocate-space.md 的 §9 测试策略，按 `test-spec-alignment` Skill 展开为用例级。勿将 `_golden` 路径当作真实迭代落盘位置；本范本 AC 编号取 Golden Story 的 AC-01~09（真实卡另有 AC-10~12，详设 §9 引用处一并保留）。

## 1. 定位

验证「按目的地查车场 → 查详情（含收费说明）→ 查可售概况 → 自动推荐车位」**准备阶段**的全部 AC 与关键 BR：BFF 层 `@WebMvcTest` Mock 域接口；inventory 域单元测试覆盖推荐算法、窗口校验、关键词规范化；Mapper 走真实 H2。失败断言统一 `Result.code !== 200` + Story 文案（HTTP 层可为 200）。

## 2. AC → 用例追溯表

| AC | 用例（测试类#方法） | 层 | 成败 | 断言（`code` / `message` / 关键字段） | 备注 |
|----|--------------------|----|------|---------------------------------------|------|
| AC-01 | `ParkingLotQueryServiceTest#search_whenKeywordMatches_returnsLots` | 单元 | 成功 | `code=200`；列表含 `lotId`、名称、地址、`bookingEnabled=true` | BR-03 |
| AC-01 | `AppParkingLotControllerTest#search_whenKeywordValid_returns200` | BFF API | 成功 | `code=200`；`$.data[0].bookingEnabled=true` | Mock `ParkingLotApi` |
| AC-02 | `ParkingLotQueryServiceTest#search_whenNoMatch_returnsEmpty` | 单元 | 失败 | `code=1603`；`message`=「很抱歉，此大厦暂无车位预约服务」 | `[AI推断]` 无匹配错误码 1603（详见 §6） |
| AC-02 | `AppParkingLotControllerTest#search_whenNoMatch_returnsMessage` | BFF API | 失败 | `message`=「很抱歉，此大厦暂无车位预约服务」 | |
| AC-03 | `ParkingLotQueryServiceTest#detail_whenFeeConfigured_returnsDescriptions` | 单元 | 成功 | `code=200`；含 `parkingFeeDescription`（「首小时」「24小时最高」）、`bookingServiceFeeDescription`（「首2小时」「超时」）；**不**含订金/支付字段 | BR-05 |
| AC-04 | `ParkingSpaceQueryServiceTest#countAvailable_whenMixedStatus_returnsOnlyAvailable` | 单元 | 成功 | `availableCount=3`；占用车位不计入 | BR-01 |
| AC-05 | `ParkingSpaceQueryServiceTest#allocate_whenNearbyExists_picksNearest` | 单元 | 成功 | `spaceId=S-101`；`walkDistanceToElevatorMeters` 为正整数；**不**创建预约单、**不**锁定 | BR-02 边界：恰好 100m |
| AC-05 | `AppReservationPrepareControllerTest#allocate_whenAvailable_returnsSpace` | BFF API | 成功 | `$.data.spaceId=S-101` | Mock `SpaceInventoryApi` |
| AC-06 | `ParkingSpaceQueryServiceTest#allocate_whenNoAvailable_throws1601` | 单元 | 失败 | `code=1601`；`message`=「无可预约的车位」 | 详设错误码 `NO_AVAILABLE_SPACE` |
| AC-07 | `AppReservationPrepareControllerTest#validate_whenEndNotAfterStart_rejects` | BFF API | 失败 | `message`=「预约结束时间须晚于开始时间」 | AC-07 校验在 BFF |
| AC-08 | `ParkingSpaceQueryServiceTest#query_whenNotBookable_throws1602` | 单元 | 失败 | `code=1602`；`message`=「该车场暂不支持预约」 | 详设错误码 `LOT_NOT_BOOKABLE` |
| AC-09 | `ParkingLotQueryServiceTest#detail_whenNotExists_throws1604` | 单元 | 失败 | `code=1604`；`message`=「车场不存在」 | `[AI推断]` 不存在错误码 1604（详见 §6） |

## 3. 分层测试矩阵

> 对齐 `skills/feature-coding/references/test-quality.md`。详设 §9 测试类清单在下方映射。

| 层 | 测试类 | 覆盖 AC / BR | Mock 什么 | 不 Mock 什么 | 备注 |
|----|--------|--------------|-----------|--------------|------|
| 单元 | `KeywordNormalizerTest`（inventory-impl） | trim、合并空白、分词（BR-06/AC-11 关联） | 无 | 自身逻辑 | 详设 §9 |
| 单元 | `BookingWindowValidatorTest` | AC-12；BR-04 边界 | 无 | 自身逻辑 | 详设 §9；跨日/临界值 |
| 单元 | `ParkingLotQueryServiceTest` | AC-01/02/03/09；BR-03、BR-05 | `LotQueryMapper`/`FeeConfigClient` | 查询编排 | 详设 §9 |
| 单元 | `ParkingSpaceQueryServiceTest` | AC-04/05/06/08；BR-01/02 | `SpaceMapper` | 推荐与可售逻辑 | BR-02 100m、等距 |
| BFF API | `AppParkingLotControllerTest`（`@WebMvcTest`） | AC-01/02/03；关键词非法（AC-10） | `ParkingLotApi` | 无 DB | 详设 §9 |
| BFF API | `AppReservationPrepareControllerTest`（`@WebMvcTest`） | AC-04~08；时段校验（AC-12） | `SpaceInventoryApi` | 无 DB | 详设 §9 |
| Mapper | `ParkingLotQueryMapperTest` / `SpaceMapperTest`（真实 H2） | BR-01 状态过滤、BR-03 可预约过滤 | 无 | H2 真库 + 种子数据 | 可选；含在 feature-coding |
| 集成（可选） | `@SpringBootTest` + 种子数据 | 端到端搜索「华润置地大厦E座」 | 外部系统（支付/车场/iam） | 真 DB | 详设 §9；归 `integration-test-design` 消费 |

## 4. Fixture / 种子数据设计

| 场景 | 输入 | Mock / 种子返回 | 边界值 |
|------|------|----------------|--------|
| AC-01 关键词命中 | `keyword=万象城` | 车场 L1（名称含「万象城」，`bookingEnabled=true`） | 首尾空格；`华润  大厦` 连续空格（BR-06） |
| AC-02 无匹配 | `keyword=不存在的大厦XYZ` | 空列表 | 空串 `""`、仅空白 `"   "`（AC-10 失败） |
| AC-04 可售统计 | `lotId=L1`、10:00–12:00 | 3 空闲 + 1 占用 | 占用/锁定/维护中均排除（BR-01） |
| AC-05 推荐最近 | `lotId=L1`、时段 | S-101（距电梯 80m）、S-102（120m） | **恰好 100m**（BR-02 阈值）；两车位等距 |
| AC-06 无可预约 | `lotId=L1`、时段 | 空闲数为 0 | `mapper.selectAvailableForAllocate()` 返回空列表 |
| AC-07 时段不合法 | `endTime <= startTime` | — | 相等、早于 |
| AC-08 未开放预约 | `lotId=L2`（`bookingEnabled=false`） | 车场 L2 | 详情/可售/分配三接口同文案（1602） |
| AC-09 车场不存在 | `lotId=999999` | Mapper 返回 null | 详情与可售两接口（1604） |
| AC-03 收费说明为空 | `lotId=L1` | 两段说明未配置 | 返回空串 `""` 而非 500（`[AI推断]`，详设 §10） |

## 5. 前端-only / N/A 标注

| AC | 标注 | 原因 |
|----|------|------|
| AC-01/03 的「列表/详情页布局、地图、语音输入、导航到位」 | 前端-only | 纯 UI，后端仅提供 API（见 STORY §2.2） |
| BR-05 的「费率展示排版」 | 前端-only | API 返回两段文案即可，排版不测 |
| 真实卡 AC-10「关键词空白」中前端输入控件拦截部分 | N/A | BFF 校验为主，前端仅兜底 |

## 6. 缺口与阻断项

| 类别 | 内容 | 动作 |
|------|------|------|
| 无匹配错误码 | AC-02 仅给文案，详设错误码表列出 1601/1602 但未明确「无匹配」与「车场不存在」码值 | **阻断**：回溯 `detail-design` 明确 1603（无匹配）/1604（不存在），或复用 1602；本范本暂以 1603/1604 为 `[AI推断]` |
| 关键词非法断言 | 详设 §9 提到 AC-10 测 `isBlank`，但未给 `message` 文案 | 补 Story AC-10 文案（Story 层可判定）或标 `[AI推断]` 用详设文案 |
| 端到端集成 | §9「集成（可选）」未列种子数据文件 | 由 `integration-test-design` 定义；本 TS 标注可选 |

## 7. 变更记录

| 日期 | 变更 | 作者 |
|------|------|------|
| 2026-08-14 | 由 `test-spec-alignment` Skill 依据 STORY-GOLDEN-001 + DD-STORY-2026-S01-001 §9 生成范本 | test-spec-alignment |
