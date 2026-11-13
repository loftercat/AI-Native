# AC-STORY-GOLDEN-001-query-allocate-space

| 字段 | 值 |
|------|-----|
| 迭代 | GOLDEN（范本） |
| 状态 | 已确认（范本） |
| 来源 | STORY-GOLDEN-001-query-allocate-space.md（AC-01~09） · App OpenAPI `docs/api/booking-bff-app/openapi.yaml` · 可选 TS-STORY-GOLDEN-001（只读对齐） |
| 服务/模块 | booking-bff-app、booking-inventory |
| 复杂度 | 中等 |

> **范本说明**：演示 QA 验收清单结构与粒度（Story/AC 追溯 + GWT 用例 + 外部用例系统导出映射 + 与 TS 对齐 + 回归库追溯 + 冒烟集）。由 `qa-acceptance-case-design` Skill 依据 STORY-GOLDEN-001 + App OpenAPI 生成。勿将 `_golden` 路径当作真实迭代落盘位置。

## 1. 定位

验证「按目的地查车场 → 查详情（含收费说明）→ 查可售概况 → 自动推荐车位」**准备阶段**的用户可见断言：BFF 层经真实 HTTP + App 鉴权 Filter；inventory 域逻辑由白盒覆盖。冒烟集覆盖主路径 + 横切（健康检查 + 各 BFF 未授权拦截）。

## 2. Story/AC 追溯表

> 每条 AC 至少一行。失败 AC 的 Then 含 Story 具体文案。

| AC | 验收用例 ID | priority | execution | suite | blackbox_rationale | 备注 |
|----|------------|----------|-----------|-------|--------------------|------|
| AC-01 列表查询 | AC-GOLDEN-001-01 | P0 | blackbox | smoke | 真实 App Filter + 鉴权，部署态独有 | BR-03 |
| AC-02 无匹配 | AC-GOLDEN-001-02 | P1 | ci_covered | N/A | — | BFF 单元已覆盖文案，无部署态增量 |
| AC-03 车场详情含收费 | AC-GOLDEN-001-03 | P0 | blackbox | smoke | 用户可见主路径，UAT 粗断言 | BR-05 |
| AC-04 可售概况 | AC-GOLDEN-001-04 | P1 | ci_covered | N/A | — | 状态过滤白盒已覆盖 |
| AC-05 自动推荐 | AC-GOLDEN-001-05 | P0 | ci_covered | N/A | — | TS 标 BFF+IT 全覆盖且无部署态独有；Then 写「以 MR mvn test 通过为准」 |
| AC-06 无可预约车位 | AC-GOLDEN-001-06 | P1 | ci_covered | N/A | — | 错误码 1601 白盒已覆盖 |
| AC-07 时段不合法 | AC-GOLDEN-001-07 | P1 | ci_covered | N/A | — | BFF 守卫白盒已覆盖 |
| AC-08 车场未开放预约 | AC-GOLDEN-001-08 | P1 | ci_covered | N/A | — | 错误码 1602 白盒已覆盖 |
| AC-09 车场不存在 | AC-GOLDEN-001-09 | P1 | ci_covered | N/A | — | 错误码 1604 白盒已覆盖 |

## 3. GWT 用例表

> Then 不断言 Mapper 内部状态或 Mock 边界；允许 `code=200`、列表字段可见、业务失败 `message` 与 Story 一致（AC-04）。

| 用例 ID | AC | Given | When | Then（用户可见） | execution | suite | blackbox_rationale |
|---------|----|-------|------|------------------|-----------|-------|--------------------|
| AC-GOLDEN-001-01 | AC-01 | L1 `bookingEnabled=true` 且名称含「万象城」 | `GET /api/v1/booking/app/lots?keyword=万象城` | `code=200`；列表含 `lotId`、名称、地址、`bookingEnabled=true` | blackbox | smoke | 真实 App Filter + 鉴权，部署态独有 |
| AC-GOLDEN-001-02 | AC-02 | 无匹配车场 | `GET /lots?keyword=不存在的大厦XYZ` | `message`=「很抱歉，此大厦暂无车位预约服务」，返回空列表 | ci_covered | N/A | — |
| AC-GOLDEN-001-03 | AC-03 | L1 已配置两段收费说明 | `GET /api/v1/booking/app/lots/{lotId}`，`lotId=L1` | `code=200`；含 `parkingFeeDescription`（「首小时」「24小时最高」）+ `bookingServiceFeeDescription`（「首2小时」「超时」）；**不**含订金/支付字段 | blackbox | smoke | 用户可见主路径，UAT 粗断言 |
| AC-GOLDEN-001-04 | AC-04 | L1 在 2026-08-01 10:00–12:00 有 3 空闲 + 1 占用 | `GET /lots/{lotId}/spaces/available`，传入 `lotId=L1`、`startTime`、`endTime` | `availableCount=3`；占用不计入 | ci_covered | N/A | — |
| AC-GOLDEN-001-05 | AC-05 | L1 时段内多空闲，S-101 距电梯最近且满足 BR-02 | `POST /api/v1/booking/app/reservations/allocate`，传入 `lotId`、时段、车牌（可选） | `spaceId=S-101`、车位编号、区域、车场、时段、`walkDistanceToElevatorMeters`（正整数）；**不**创建预约单、**不**锁定；以 MR 流水线 `mvn test` 通过为准 | ci_covered | N/A | — |
| AC-GOLDEN-001-06 | AC-06 | L1 时段内空闲数为 0 | `POST /reservations/allocate` | `message`=「无可预约的车位」 | ci_covered | N/A | — |
| AC-GOLDEN-001-07 | AC-07 | 车主已登录 | 可售查询或自动分配，`endTime <= startTime` | `message`=「预约结束时间须晚于开始时间」 | ci_covered | N/A | — |
| AC-GOLDEN-001-08 | AC-08 | L2 `bookingEnabled=false` | L2 详情/可售/分配 | `message`=「该车场暂不支持预约」 | ci_covered | N/A | — |
| AC-GOLDEN-001-09 | AC-09 | 不存在 `lotId=999999` | `GET /lots/999999` 或可售查询 | `message`=「车场不存在」 | ci_covered | N/A | — |

## 4. 外部用例系统导出映射

- **正文**：本 GWT 表为草稿
- **链接字段**：`story_id`=STORY-GOLDEN-001 / `ts_id`=TS-STORY-GOLDEN-001 / `mr_pipeline`=mr!123
- **不复制** TS 正文步骤（BR-04）

## 5. 与 TS 对齐节

> TS 是只读对齐参考（非输入真源）。`ci_covered` 双条件判定结果如下。

| AC | TS 覆盖（单元/BFF/IT） | 部署态独有验证点 | execution 判定 | 说明 |
|----|------------------------|------------------|----------------|------|
| AC-01 | BFF + IT 全覆盖 | **有**：真实 App `AppAuthFilter` + 鉴权链路 | `blackbox` | BFF `@WebMvcTest` 不经真实 Filter；属 marp §3 第 3 类「真实 HTTP（网关、Filter、TLS）」 |
| AC-02 | 单元 + BFF 全覆盖 | 无 | `ci_covered` | 文案断言白盒已覆盖，无部署态增量 |
| AC-03 | 单元 + BFF 全覆盖 | **有**：用户可见主路径，UAT 粗断言 | `blackbox` | marp §3 第 6 类「用户可见主路径、导出、列表」 |
| AC-04 | 单元 + BFF 全覆盖 | 无 | `ci_covered` | 状态过滤白盒已覆盖 |
| AC-05 | 单元 + BFF + IT 全覆盖 | 无 | `ci_covered` | 双条件全满足；Then 写「以 MR mvn test 通过为准」 |
| AC-06 | 单元 + BFF 全覆盖 | 无 | `ci_covered` | 错误码 1601 白盒已覆盖 |
| AC-07 | BFF 全覆盖 | 无 | `ci_covered` | BFF 守卫白盒已覆盖 |
| AC-08 | 单元 + BFF 全覆盖 | 无 | `ci_covered` | 错误码 1602 白盒已覆盖 |
| AC-09 | 单元 + BFF 全覆盖 | 无 | `ci_covered` | 错误码 1604 白盒已覆盖 |

> **AC-06 演示说明**：本 Golden 演示 `ci_covered` 双条件两类情形——AC-05（双条件全满足 → `ci_covered`）与 AC-01（TS 全覆盖但有部署态独有 → `blackbox`，对应 Story AC-06/AC-11 的反例）。若 `TS-STORY-GOLDEN-001` 未落盘，本节 `ci_covered` 判定标 `[AI推断]` 并降级为仅 Story+OpenAPI 推断。

## 6. 回归库追溯

- 本 Golden 为新建，无 `legacy_tc_id`
- 后续 Story 沉淀路径须可追溯 `Story / OpenAPI operation / 矩阵行`
- 无孤儿回归用例

| 验收用例 ID | legacy_tc_id | status | 追溯说明 |
|------------|--------------|--------|----------|
| AC-GOLDEN-001-01~09 | — | automated | 新建，追溯 STORY-GOLDEN-001 AC-01~09 + App OpenAPI |

## 7. 冒烟集（suite=smoke，共 6 条，区间 5~15）

> 含 ≥1 健康检查 + 各 BFF 未授权拦截探测（Admin/App 各 ≤1）；每条 <2 min（AC-12/BR-11）。

| # | 验收用例 ID | AC | 类型 | 预计耗时 |
|---|------------|----|------|----------|
| 1 | AC-GOLDEN-001-01 | AC-01 | 主路径（列表查询） | <2 min |
| 2 | AC-GOLDEN-001-03 | AC-03 | 主路径（车场详情含收费） | <2 min |
| 3 | AC-GOLDEN-001-05 | AC-05 | 主路径（自动推荐，ci_covered，Pipeline 引用） | <2 min |
| 4 | HEALTH-001 | — | 横切：`GET /actuator/health` | <30 s |
| 5 | AUTH-APP-001 | — | 横切：App BFF 未授权拦截（无 Token 调 `/reservations/allocate` 期 401） | <30 s |
| 6 | AUTH-ADMIN-001 | — | 横切：Admin BFF 未授权拦截（无 Token 调 `/admin/...` 期 401） | <30 s |

## 8. 缺口与阻断项

| 类别 | 内容 | 动作 |
|------|------|------|
| 无匹配错误码 1603 / 不存在错误码 1604 | TS §6 已标 `[AI推断]`；详设错误码表未明确「无匹配」与「不存在」码值 | 回溯 `detail-design` 明确码值或复用 1602；本范本暂以 1603/1604 为推断 |
| Golden TS 可选 | `TS-STORY-GOLDEN-001` 若未落盘，§5 `ci_covered` 判定降级为 `[AI推断]` | 落地 TS 后回填本节 |

## 9. 变更记录

| 日期 | 变更 | 作者 |
|------|------|------|
| 2026-10-03 | 初版：`qa-acceptance-case-design` Skill 依据 STORY-GOLDEN-001 + App OpenAPI（可选 TS 对齐）生成范本 | qa-acceptance-case-design |
