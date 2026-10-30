# DD-FE-GOLDEN-001-destination-search-allocate（范本，非真实卡片，自已落地的源项目抽取）

## 1. 元信息

| 字段 | 值 |
|------|-----|
| 迭代 | 2026-S01 |
| 状态 | 草稿 |
| 对应 Story | [STORY-FE-GOLDEN-001-destination-search-allocate](../../requirements/_golden/STORY-FE-GOLDEN-001-destination-search-allocate.md) |
| 契约 | `docs/handoff/openapi/booking-bff-app.yaml` @ `9f3673b` |
| baseUrl | `/api/v1/booking/app` |
| 复杂度 | 中等 |
| 本卡 API | `searchLots` · `getLotDetail` · `getAvailableSpaces` · `allocateSpace`；车辆列表 **OpenAPI 未 handoff / API TBD** |

## 2. 路由与页面

| 页面 | 路径 | 分包建议 | tabBar |
|------|------|----------|--------|
| 目的地首页（搜索入口） | `pages/home/home` | 主包 | **目的地**（蓝湖 0810 四 Tab：目的地 \| 导航到梯 \| 代客预约 \| 我的） |
| 目的地搜索/结果 | `pages/destination/destination` | 主包或 `packageBooking` | 非 Tab |
| 车场详情 | `pages/lot-detail/lot-detail` | `packageBooking` 建议 | 非 Tab |
| 分配结果/预约准备（含车牌三态） | `pages/booking-prepare/booking-prepare`（或复用 lot-detail 下半区；命名可微调） | `packageBooking` | 非 Tab |

> 未登录仅可访问首页搜索壳（FE-001）；点搜索进结果/详情/分配前须已登录（门禁归 FE-001）。

### 跳转关系

```text
pages/home/home（搜索栏 / 语音）
  → pages/destination/destination（searchLots 列表）
    → pages/lot-detail/lot-detail（getLotDetail + 选时段 getAvailableSpaces）
      → allocateSpace
        → 预约准备页（车牌三态 AC-05a/b/c）
          → 车牌就绪后 navigateTo pages/booking-create（FE-003）
```

草稿（内存或 storage）：`lotId`、`spaceId`、`spaceNo`、`zoneName`、`lotName`、`startTime`、`endTime`、`walkDistanceToElevatorMeters`、`plateNo` —— 字段名只认 OpenAPI / 本流程已约定的分配结果字段；**不发明**车辆库字段名。

## 3. 组件树与 props/事件

```text
pages/home/home
└─ search-bar（keyword + 麦克风）【复用】

pages/destination/destination
└─ lot-list
   └─ lot-list-item（name / address）

pages/lot-detail/lot-detail
├─ lot-fee-block（parkingFeeDescription / bookingServiceFeeDescription）
├─ time-range-picker（startTime / endTime）
├─ available-count-badge（availableCount）
└─ allocate-cta

pages/booking-prepare/…（或详情页扩展）
├─ allocate-result-card（spaceNo / zoneName / walkDistanceToElevatorMeters）
└─ plate-selector                     【本卡车牌三态 · 可复用至 FE-012 样式】
   ├─ plate-input（无车牌）
   ├─ plate-default-row（单/多 · 主行）
   └─ plate-option-list（多车牌下方列表）
```

| 组件 | props | 事件 | 复用 |
|------|-------|------|------|
| `search-bar` | `value`、`placeholder` | `search`、`voice` | 首页 / 目的地页 |
| `lot-list-item` | `name`、`address`、`lotId` | `tap` | 搜索结果 |
| `lot-fee-block` | `parkingFeeDescription`、`bookingServiceFeeDescription` | — | 详情 |
| `time-range-picker` | `startTime`、`endTime` | `change` | 详情 |
| `allocate-result-card` | `spaceNo`、`zoneName`、`walkDistanceToElevatorMeters`、`lotName` | — | 准备页 / 可给 FE-003 只读复用样式 |
| `plate-selector` | `mode: empty\|single\|multi`、`selectedPlateNo`、`plates`（数据源 API TBD，结构待 handoff） | `input`、`select`、`gotoAdd` | **FE-002 主责**；FE-003 若改选须复用本组件 |

## 4. 页面状态机

| 状态 | 页面 | 触发 | 展示 | setData 要点 |
|------|------|------|------|--------------|
| `idle` | home | 进入 | 搜索壳 | 低频 |
| `searching` | destination | 提交 keyword | loading | `{ loading: true }` |
| `searchEmpty1604` | destination | `code=1604` | 空态文案 | `{ loading: false, lots: [], errorCode: 1604, emptyTip }` 一次合并 |
| `searchOk` | destination | `code===200` | 列表 `name`/`address` | `{ loading: false, lots }` |
| `detailLoading` | lot-detail | 进页 | skeleton | `{ detailLoading: true }` |
| `detailOk` | lot-detail | `getLotDetail` 200 | 收费说明 | 合并 detail 字段 |
| `availOk` | lot-detail | 选时段 + 200 | `availableCount` | 只更新 count/时段 |
| `allocating` | lot-detail | 点分配 | CTA loading | `{ allocBusy: true }` |
| `allocOk` | prepare | `allocateSpace` 200 | 车位信息 + 车牌区 | 合并分配结果；**不**伪造锁定 |
| `plateEmpty` | prepare | 车辆列表空（API TBD） | 输入车牌态 | `plateMode: 'empty'` |
| `plateSingle` | prepare | 仅 1 牌 | 默认车牌 | `plateMode: 'single'` + `plateNo` |
| `plateMulti` | prepare | ≥2 牌 | 主行默认 + 下方列表 | `plateMode: 'multi'` |
| `blockedNoPlate` | prepare | 无 `plateNo` 点去确认 | Toast 阻断，不进 FE-003 | 不改分配结果 |
| `errorToast` | 各页 | 业务码失败 | Toast `message` | 清 busy，保留可重试表单 |

搜索防抖：输入侧 debounce 后再请求；结果一次 `setData`。

## 5. AC → operationId 映射表

| AC | operationId | Method | Path | 成功展示 | 失败展示 |
|----|-------------|--------|------|----------|----------|
| AC-01 搜索成功 | `searchLots` | GET | `/lots` | 列表展示 `name`/`address`（`ParkingLotSummary`） | — |
| AC-02 无匹配 1604 | `searchLots` | GET | `/lots` | — | Toast/空态：「很抱歉，此大厦暂无车位预约服务」（`message`） |
| AC-03 详情收费 | `getLotDetail` | GET | `/lots/{lotId}` | `parkingFeeDescription` / `bookingServiceFeeDescription` | 见 AC-08/09 |
| AC-04 可售数量 | `getAvailableSpaces` | GET | `/lots/{lotId}/spaces/available` | 展示 `availableCount` | 见 AC-07/08/09/12 |
| AC-05 分配成功 | `allocateSpace` | POST | `/reservations/allocate` | `spaceNo`/`zoneName`/`walkDistanceToElevatorMeters`；车牌就绪后进 FE-003 | 见 AC-06 等 |
| AC-05a 无车牌输入 | —（车辆 **API TBD**）；分配可选带 `AllocateSpaceRequest.plateNo` | — | — | 输入车牌或跳转 FE-012 回填；未完成不可进 FE-003 | Toast 阻断空车牌 |
| AC-05b 单车牌默认 | —（车辆 API TBD） | — | — | 主行展示该默认车牌写入草稿 `plateNo` | — |
| AC-05c 多车牌可选 | —（车辆 API TBD） | — | — | 主行默认 + 下方列表点选 → 草稿 `plateNo`；分配请求可带该字段 | — |
| AC-06 无车位 1601 | `allocateSpace` | POST | `/reservations/allocate` | — | Toast：「无可预约的车位」 |
| AC-07 时段非法 400 | `getAvailableSpaces` / `allocateSpace` | GET / POST | 见上 | — | Toast：「预约结束时间须晚于开始时间」 |
| AC-08 不支持预约 1602 | `getLotDetail` / `getAvailableSpaces` / `allocateSpace` | GET / POST | 见上 | — | Toast：「该车场暂不支持预约」 |
| AC-09 车场不存在 1603 | `getLotDetail` / `getAvailableSpaces`（及 allocate 同类） | GET / POST | 见上 | — | Toast：「车场不存在」 |
| AC-10 关键词非法 | `searchLots`（前端先拦空 keyword；后端亦可 400） | GET | `/lots` | — | Toast：「请输入目的地或大厦名称」 |
| AC-11 空格规范化 | `searchLots` | GET | `/lots` | `code===200` 仍可匹配（BFF trim/空白合并） | — |
| AC-12 时段窗外 1605 | `getAvailableSpaces` / `allocateSpace` | GET / POST | 见上 | — | Toast：「预约时段不在车场可预约时间内」 |
| AC-13 语音搜索 | `searchLots`（识别后）+ 微信/语音能力 UI: TBD | GET | `/lots` | 同 AC-01 路径 | 同搜索失败 |

**请求体要点（只认 OpenAPI）**

- `allocateSpace`：`lotId`、`startTime`、`endTime` 必填；`plateNo` 可选（有已选车牌时应带上）
- 成功不创建预约单、不本地伪造锁定（BR-FE-03）

## 6. 错误展示

| code | 场景 | 方式 | 文案 |
|------|------|------|------|
| 1604 | 搜索无匹配 | 空态 + 可选 Toast | 后端 `message` |
| 1601 | 分配无车位 | Toast | 无可预约的车位 |
| 1602 | 不支持预约 | Toast | 该车场暂不支持预约 |
| 1603 | 车场不存在 | Toast | 车场不存在 |
| 1605 | 时段窗外 | Toast | 预约时段不在车场可预约时间内 |
| 400 | 时段非法 / 关键词非法 | Toast | 后端 `message`（如「预约结束时间须晚于开始时间」/「请输入目的地或大厦名称」） |
| 空车牌进 FE-003 | 前端阻断 | Toast | 请先录入或选择车牌（前端校验，非业务码） |
| 401 | 需登录接口 | `http.js` 静默 | 页面不感知 |
| -1 | 网络 | Toast + 重试 | 网络异常 |

关键操作（分配）失败默认 Toast；若产品升级为强阻断可用 Modal，仍展示后端 `message`。

## 7. 性能关注

- 搜索 debounce（建议 300ms+），避免连打 `searchLots`
- 列表仅 `setData` 变更的 `lots` 数组，控制单次 < 256KB
- 分配 busy 用组件级 `setData`（CTA），勿整页重刷
- 车牌列表不在分配轮询中重复全量拉取；进入准备页拉一次（车辆 API TBD）
- 分包：`lot-detail` / 准备页进 `packageBooking`，主包保留 home 搜索入口

## 8. 原型追溯

| 来源 | 引用 |
|------|------|
| 蓝湖 0810 | 首页默认 / 首页1 / 首页无预约车位1~4（搜索入口）；**车位预约**（车牌三态）；添加车辆 / 我的车辆（样式参考，CRUD 归 FE-012） |
| `docs/prototype/` | **TBD**（以蓝湖 0810 为准） |
| 对照表 | lanhu-0810-screens.md（源项目文件，模板未随附） |

## 9. 变更记录

| 日期 | 变更 | 作者 |
|------|------|------|
| 2026-08-10 | 初稿：搜索→详情→可售→分配 + 车牌三态；映射已 handoff 四接口 | frontend-detail-design |
