# DD-Flutter-GOLDEN-001-destination-search-allocate（范本，非真实卡片，自已落地的源项目抽取）

## 1. 元信息

| 字段 | 值 |
|------|-----|
| 迭代 | 2026-S01 |
| 状态 | 草稿 |
| 对应 Story | [STORY-Flutter-GOLDEN-001-destination-search-allocate](../../requirements/_golden/STORY-Flutter-GOLDEN-001-destination-search-allocate.md) |
| 契约 | `docs/handoff/openapi/booking-bff-app.yaml` @ `9f3673b` |
| baseUrl | `/api/v1/booking/app` |
| 复杂度 | 中等 |
| 本卡 API | `searchLots` · `getLotDetail` · `getAvailableSpaces` · `allocateSpace`；车辆列表 **OpenAPI 未 handoff / API TBD** |

## 2. 路由与页面

目的地 Tab（/home）→ /destination/search → /lots/:lotId → /booking/prepare。结果页返回时恢复关键词和列表位置。登录路由保留待访问的 lotId，恢复时重新验证账号和资源。准备页需要当前会话的分配草稿，冷启动缺草稿则回到详情重新查询。车牌就绪后进入下一卡确认页。

### 跳转关系

```text
/home → /destination/search → /lots/:lotId → /booking/prepare
                                          → 车牌就绪后进入 Flutter-003
```

## 3. Widget 树、参数与回调

```text
DestinationSearchPage
  ├─ SearchField
  └─ LotList → LotListItem
LotDetailPage
  ├─ FeePanel
  ├─ TimeRangePicker
  └─ AllocateButton
BookingPreparePage
  ├─ AllocationCard
  └─ PlateSelector
```

| 页面 | Widget、输入和回调 | 状态归属 |
|---|---|---|
| DestinationSearchPage | SearchField 调用 onQueryChanged / onVoice；LotList 按 lotId 选择 | 搜索 Controller 拥有 keyword、请求序号、结果 |
| LotDetailPage | FeePanel 展示费用，TimeRangePicker 回传时段，AllocateButton 显示提交中 | Controller 通过 Repository 读取详情与可售量 |
| BookingPreparePage | AllocationCard 展示分配结果，PlateSelector 回传选择 | 会话内 BookingDraft 存 spaceId 和 plateNo，离开流程或换号释放 |

## 4. 页面状态机

搜索 idle → loading → results / empty / error。只接收当前关键词的最新请求，空态保留输入，失败可重试。详情加载成功后才可选时段；切换时段忽略上一请求的可售量。提交时禁用分配按钮，成功进入准备页，业务失败保留表单，网络结果未知时先确认资源状态。

准备页区分输入车牌、显示唯一车牌及多车牌选择。车辆来源未交接时用测试替身验证三种 UI，真实联调标待验。未选车牌在字段旁提示；选好后一次导航到确认页。切号清理草稿，过期回调不得更新新会话。

## 5. AC → operationId 映射表

| AC | operationId | Method | Path | 成功展示 | 失败展示 |
|----|-------------|--------|------|----------|----------|
| AC-01 搜索成功 | `searchLots` | GET | `/lots` | 列表展示 `name`/`address`（`ParkingLotSummary`） | — |
| AC-02 无匹配 1604 | `searchLots` | GET | `/lots` | — | 空态：「很抱歉，此大厦暂无车位预约服务」（`message`） |
| AC-03 详情收费 | `getLotDetail` | GET | `/lots/{lotId}` | `parkingFeeDescription` / `bookingServiceFeeDescription` | 见 AC-08/09 |
| AC-04 可售数量 | `getAvailableSpaces` | GET | `/lots/{lotId}/spaces/available` | 展示 `availableCount` | 见 AC-07/08/09/12 |
| AC-05 分配成功 | `allocateSpace` | POST | `/reservations/allocate` | `spaceNo`/`zoneName`/`walkDistanceToElevatorMeters`；车牌就绪后进 Flutter-003 | 见 AC-06 等 |
| AC-05a 无车牌输入 | —（车辆 **API TBD**）；分配可选带 `AllocateSpaceRequest.plateNo` | — | — | 输入车牌或跳转 Flutter-012 回填；未完成不可进 Flutter-003 | 车牌字段提示 |
| AC-05b 单车牌默认 | —（车辆 API TBD） | — | — | 主行展示该默认车牌写入草稿 `plateNo` | — |
| AC-05c 多车牌可选 | —（车辆 API TBD） | — | — | 主行默认 + 下方列表点选 → 草稿 `plateNo`；分配请求可带该字段 | — |
| AC-06 无车位 1601 | `allocateSpace` | POST | `/reservations/allocate` | — | 局部提示：「无可预约的车位」 |
| AC-07 时段非法 400 | `getAvailableSpaces` / `allocateSpace` | GET / POST | 见上 | — | 局部提示：「预约结束时间须晚于开始时间」 |
| AC-08 不支持预约 1602 | `getLotDetail` / `getAvailableSpaces` / `allocateSpace` | GET / POST | 见上 | — | 局部提示：「该车场暂不支持预约」 |
| AC-09 车场不存在 1603 | `getLotDetail` / `getAvailableSpaces`（及 allocate 同类） | GET / POST | 见上 | — | 局部提示：「车场不存在」 |
| AC-10 关键词非法 | `searchLots`（前端先拦空 keyword；后端亦可 400） | GET | `/lots` | — | 局部提示：「请输入目的地或大厦名称」 |
| AC-11 空格规范化 | `searchLots` | GET | `/lots` | `code == 200` 仍可匹配（BFF trim/空白合并） | — |
| AC-12 时段窗外 1605 | `getAvailableSpaces` / `allocateSpace` | GET / POST | 见上 | — | 局部提示：「预约时段不在车场可预约时间内」 |
| AC-13 语音搜索 | `searchLots`（识别后）+ 平台语音适配器 | GET | `/lots` | 同 AC-01 路径 | 同搜索失败 |

**字段说明示例。** 依据本卡登记的契约版本，下面两项可直接用于响应模型的中文注释。类型、可空性及其他字段仍按对应 schema 核实。

| operationId / 响应字段 | 中文业务含义 | 使用位置 |
|---|---|---|
| getLotDetail / parkingFeeDescription | 车场停车费用的说明文案 | 车场详情费用区 |
| getLotDetail / bookingServiceFeeDescription | 预约服务费的说明文案 | 车场详情费用区，与停车费用分别展示 |

**请求体要点（只认 OpenAPI）**

- `allocateSpace`：`lotId`、`startTime`、`endTime` 必填；`plateNo` 可选（有已选车牌时应带上）
- 成功不创建预约单、不本地伪造锁定（BR-Flutter-03）

## 6. 错误展示

无匹配展示空态，非法关键词/时段在对应字段提示，分配被拒以局部提示呈现，认证过期由会话层处理。只展示契约允许的用户文案。语音适配器返回识别文本、取消、无权限或不可用；拒绝后保留键盘搜索，页面关闭时停止识别并丢弃迟到的回调。

## 7. 性能关注

单测模拟两次搜索逆序返回、时段切换和换号；Widget 测试覆盖 AC-01～13 的状态、车牌三态及重复提交。列表按需构建，仅搜索区监听查询状态。Android 与 iOS 分别验证麦克风允许/拒绝、系统设置返回、键盘遮挡和从详情返回；排查原生能力时记录系统与插件版本。

## 8. 设计稿追溯

| Story 登记项 | 详设核对与验证 |
|---|---|
| 首页搜索栏、目的地入口 | 按蓝湖 0810 对照 SearchField 与列表。定稿状态待确认。 |
| 预约准备页车牌区 | 按同版车位预约、我的车辆、添加车辆核对三态及回填。定稿状态待确认。 |
| 麦克风权限拒绝后的页面提示 | 无 → UI: TBD。按 AC 验证保留键盘搜索，提示样式等稿件或用户确认。 |

本范本沿用蓝湖 0810 首页搜索入口、车位预约和我的车辆三组设计。首页搜索栏映射到 SearchField；分配中映射到禁用的主按钮；三种车牌态映射到 PlateSelector。使用项目主题的输入框、错误色与正文字体。在设计基准尺寸和较小屏幕上检查键盘、长文案和底部安全区。本模板未附原设计快照，接入时补真实 Frame、快照版本、实现截图及差异记录。

## 9. 变更记录

Flutter 版保留四个已交接 operation 的范围，新增两端语音降级、搜索乱序与会话草稿的验证。
