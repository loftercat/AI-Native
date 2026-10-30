# STORY-FE-GOLDEN-001-destination-search-allocate（范本，非真实卡片，自已落地的源项目抽取）

| 字段 | 值 |
|------|-----|
| 迭代 | 2026-S01 |
| 状态 | 草稿 |
| 来源 | 蓝湖 0810：首页搜索入口（首页默认/首页1/无预约车位系列）→ 车场匹配 → 确认页前分配；后端 STORY-2026-S01-001 |
| 复杂度 | 中等 |
| 页面/路由 | `pages/home/home` 搜索入口 → `pages/destination` / `pages/lot-detail`（路由名可微调） |
| 依赖后端 Story | STORY-2026-S01-001 |

## 1. 用户故事

作为 **车主**，我想 **在目的地 Tab 搜索大厦/车场、查看收费并获得推荐车位，并在进入下单前完成车牌录入或选择（无车牌可输入、有车牌用默认、多车牌下方可选）**，以便 **带着车位与车牌进入确认下单页**。

## 2. 范围

### 2.1 目标

- 首页搜索栏（含语音入口，语音识别实现可 UI: TBD / 微信能力）发起关键词搜索
- `searchLots` → 列表选车场 → `getLotDetail` 收费说明 → 选时段 `getAvailableSpaces` → `allocateSpace` 推荐
- **车牌三态（本卡负责，对齐蓝湖「车位预约」车牌行 +「我的车辆/添加车辆」）**——在分配结果/预约准备页完成，再进 FE-003：
  - **无已保存车牌**：展示**输入车牌**（本页车牌键盘录入，或跳转 FE-012「添加车辆」后回填）；**未完成不可进入预缴定金/创建单**
  - **仅 1 个车牌**：展示该车牌为**默认车牌**
  - **多个车牌**：主行展示**当前默认车牌**；**下方分别列出车牌**供点选（样式参考「我的车辆」列表/默认标）；点选写入本流程草稿 `plateNo`
- 亦可先在「我的 → 我的车辆」新增（FE-012），本卡进入时自动带出默认车牌
- `allocateSpace` 请求体中 `plateNo` 为可选（OpenAPI：供后续下单预填）；有已选车牌时应带上
- 分配成功且车牌就绪后，带着 `spaceId`/`plateNo` 等进入 FE-003 确认创建

### 2.2 非目标

- `createBookingOrder` / 支付 / 导航（FE-003/004/005）
- 车辆库 CRUD 实现（FE-012；本卡只消费列表/默认/添加回填，**车辆 API 未 handoff / API TBD**）
- 图层切换实现细节；反馈页（FE-016）

## 3. 契约

| 项 | 值 |
|----|-----|
| OpenAPI 文件 | `docs/handoff/openapi/booking-bff-app.yaml` |
| 契约版本 | `9f3673b`（待 tag `2026-S01-rc1`） |
| baseUrl | `/api/v1/booking/app` |

## 4. 本卡 API 范围

| AC | operationId | Method | Path | 说明 |
|----|-------------|--------|------|------|
| AC-01/02/10/11 | `searchLots` | GET | `/lots` | 关键词搜车场 |
| AC-03/08/09 | `getLotDetail` | GET | `/lots/{lotId}` | 详情收费 |
| AC-04/07/08/09/12 | `getAvailableSpaces` | GET | `/lots/{lotId}/spaces/available` | 可售概况 |
| AC-05/06/07/08/12 | `allocateSpace` | POST | `/reservations/allocate` | 自动推荐不落单 |

## 5. 不在本卡范围

- `createBookingOrder` `getActiveReservation`
- 支付/导航等未 handoff 接口

## 6. 业务规则（前端）

| 编号 | 规则 |
|------|------|
| BR-FE-01 | 字段只认 OpenAPI DTO（`ParkingLotSummary` 等） |
| BR-FE-02 | 失败 Toast 用后端 `message` |
| BR-FE-03 | `allocateSpace` 成功不创建预约单、不本地伪造锁定态 |
| BR-FE-04 | 语音搜索：将识别文本填入 keyword 后再调 `searchLots` |
| BR-FE-05 | 车牌数据源：用户车辆列表（**API TBD**，归 FE-012）；本卡不发明车辆字段名；分配可选带 `AllocateSpaceRequest.plateNo` |
| BR-FE-06 | **默认车牌**：多车时优先「默认」标记；无默认取列表第一项，允许改选 |
| BR-FE-07 | **首次无车牌**：本页输入或跳转 FE-012 添加；成功后进入有车牌态 |
| BR-FE-08 | 无车牌/未选车牌时，不可带着空 `plateNo` 进入 FE-003 创建（阻断并提示） |
| BR-FE-09 | 进入 FE-003 的草稿必须含已选 `plateNo`（及分配结果字段） |

## 7. 验收标准（AC）

### AC-01：搜索成功

- **后端 Story**：STORY-2026-S01-001（AC-01）
- **OpenAPI**：operationId `searchLots`（GET `/api/v1/booking/app/lots`）
- **契约版本**：booking-bff-app @ `9f3673b`
- **蓝湖**：首页搜索入口
- **Given/When/Then**：**Given** keyword 合法 **When** `code===200` **Then** 列表展示 `name`/`address`

### AC-02：无匹配 1604

- **后端 Story**：STORY-2026-S01-001（AC-02）
- **OpenAPI**：operationId `searchLots`
- **契约版本**：booking-bff-app @ `9f3673b`
- **Given/When/Then**：**Given** `code=1604` **When** 搜索 **Then** 展示「很抱歉，此大厦暂无车位预约服务」

### AC-03：详情收费

- **后端 Story**：STORY-2026-S01-001（AC-03）
- **OpenAPI**：operationId `getLotDetail`
- **契约版本**：booking-bff-app @ `9f3673b`
- **Given/When/Then**：**Given** `code===200` **When** 进详情 **Then** 展示 `parkingFeeDescription` / `bookingServiceFeeDescription`

### AC-04：可售数量

- **后端 Story**：STORY-2026-S01-001（AC-04）
- **OpenAPI**：operationId `getAvailableSpaces`
- **契约版本**：booking-bff-app @ `9f3673b`
- **Given/When/Then**：**Given** 已选时段 **When** `code===200` **Then** 展示 `availableCount`

### AC-05：分配成功

- **后端 Story**：STORY-2026-S01-001（AC-05）
- **OpenAPI**：operationId `allocateSpace`
- **契约版本**：booking-bff-app @ `9f3673b`
- **Given/When/Then**：**Given** `code===200` **When** 自动分配 **Then** 展示 `spaceNo`/`zoneName`/`walkDistanceToElevatorMeters`；在车牌就绪后进入确认创建（FE-003）

### AC-05a：无车牌 → 输入车牌

- **OpenAPI**：车辆列表 **未 handoff / API TBD**；`allocateSpace.plateNo` 可选
- **蓝湖**：车位预约（车牌行）· 添加车辆
- **Given/When/Then**：**Given** 用户车辆列表为空（首次预约） **When** 进入分配结果/预约准备（车牌区） **Then** 展示**输入车牌**态（本页录入或跳转 FE-012）；未完成不可进入 FE-003 创建

### AC-05b：单车牌 → 展示默认

- **OpenAPI**：—（车辆 API TBD）
- **蓝湖**：车位预约
- **Given/When/Then**：**Given** 仅 1 个已保存车牌 **When** 渲染车牌区 **Then** 直接展示该默认车牌

### AC-05c：多车牌 → 默认 + 下方分别展示可选

- **OpenAPI**：—（车辆 API TBD）
- **蓝湖**：车位预约 · 我的车辆（列表样式参考）
- **Given/When/Then**：**Given** ≥2 个已保存车牌 **When** 渲染车牌区 **Then** 主行展示默认车牌，**下方分别展示车牌列表**供点选；选中结果写入草稿 `plateNo`（分配请求可带该字段）

### AC-06：无车位 1601

- **后端 Story**：STORY-2026-S01-001（AC-06）
- **OpenAPI**：operationId `allocateSpace`
- **契约版本**：booking-bff-app @ `9f3673b`
- **Given/When/Then**：**Given** `code=1601` **When** 分配 **Then** 「无可预约的车位」

### AC-07：时段非法 400

- **后端 Story**：STORY-2026-S01-001（AC-07）
- **OpenAPI**：`getAvailableSpaces` / `allocateSpace`
- **契约版本**：booking-bff-app @ `9f3673b`
- **Given/When/Then**：**Given** end≤start **When** 请求 **Then** 「预约结束时间须晚于开始时间」

### AC-08：不支持预约 1602

- **后端 Story**：STORY-2026-S01-001（AC-08）
- **OpenAPI**：相关三接口
- **契约版本**：booking-bff-app @ `9f3673b`
- **Given/When/Then**：**Given** `code=1602` **When** 失败 **Then** 「该车场暂不支持预约」

### AC-09：车场不存在 1603

- **后端 Story**：STORY-2026-S01-001（AC-09）
- **OpenAPI**：`getLotDetail` / `getAvailableSpaces`
- **契约版本**：booking-bff-app @ `9f3673b`
- **Given/When/Then**：**Given** `code=1603` **When** 失败 **Then** 「车场不存在」

### AC-10：关键词非法

- **后端 Story**：STORY-2026-S01-001（AC-10）
- **OpenAPI**：operationId `searchLots`
- **契约版本**：booking-bff-app @ `9f3673b`
- **Given/When/Then**：**Given** 空关键词 **When** 搜索 **Then** 「请输入目的地或大厦名称」

### AC-11：空格规范化

- **后端 Story**：STORY-2026-S01-001（AC-11）
- **OpenAPI**：operationId `searchLots`
- **契约版本**：booking-bff-app @ `9f3673b`
- **Given/When/Then**：**Given** 含连续空格 keyword **When** `code===200` **Then** 仍可匹配

### AC-12：时段窗外 1605

- **后端 Story**：STORY-2026-S01-001（AC-12）
- **OpenAPI**：`getAvailableSpaces` / `allocateSpace`
- **契约版本**：booking-bff-app @ `9f3673b`
- **Given/When/Then**：**Given** `code=1605` **When** 失败 **Then** 「预约时段不在车场可预约时间内」

### AC-13：语音入口可触发搜索

- **OpenAPI**：operationId `searchLots`（识别后）
- **契约版本**：booking-bff-app @ `9f3673b`
- **蓝湖**：首页搜索栏麦克风
- **Given/When/Then**：**Given** 用户点语音并得到文本 **When** 填入搜索 **Then** 走与键盘搜索同一 `searchLots` 路径（语音 SDK 细节 UI: TBD）

## 8. 依赖与追溯

| 类型 | 引用 |
|------|------|
| 后端 | STORY-2026-S01-001 |
| 蓝湖 0810 | 首页默认/首页1/无预约车位（搜索）；车位预约（**车牌三态**） |
| 车辆 | FE-012 |
| 下游 | FE-003（消费草稿 `plateNo` + 分配结果） |

## 9. 测试关注点

- 搜索防抖；分配结果刷新；错误码文案；无/单/多车牌三态；无车牌阻断进 FE-003

## 10. 变更记录

| 日期 | 变更 | 作者 |
|------|------|------|
| 2026-08-10 | 按蓝湖华智项目 0810 UI 全量重拆覆盖（源项目原文） | frontend-story-splitting |
| 2026-08-10 | 按主流程重排 Story 编号（旧 003 → 新 002） | frontend-story-splitting |
| 2026-08-10 | **车牌三态归属本卡（002）**；与 FE-012/FE-003 分工 | 产品确认后修订 |
