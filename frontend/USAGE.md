# AI Native 使用手册（C 端小程序）

> **模板版说明**：本文档自源项目（C 端微信小程序）抽取为通用模板。文中项目专属值（`booking-*`、`booking-bff-app.yaml`、页面/组件名、Story 号）均为**示例**，接入时按根 [MIGRATION.md](../MIGRATION.md) 清单替换；「本仓库」指接入后的前端项目。


> 本手册说明在已落地的源项目前端仓中如何用三个 AI Skill 完成 **需求拆解 → 详细设计 → 编码** 全流程，并给出可直接复制的提示词 Demo。
>
> 配套：[frontend/README.md](README.md) · [docs/methodology/readme.md](docs/methodology/readme.md) · [architecture/system-landscape.md](architecture/system-landscape.md)

---

## 一、总览：三段流水线 + 审查门禁

```text
Epic/PRD/原型 + 后端 OpenAPI handoff
        ↓
frontend-story-splitting   →  STORY-FE-*.md（AC + 本卡 operationId 范围）
        ↓
frontend-detail-design      →  DD-FE-*.md（页面状态机、组件树、AC→operationId 映射）
        ↓
frontend-feature-coding     →  pages/ components/ services/ + 测试
        ↓
代码审查（rules/code-review.md）→ REVIEW-CODE-FE-*（联调/提测前）
```

| Skill | 做什么 | 产出 | 不做什么 |
|-------|--------|------|----------|
| `frontend-story-splitting` | 把需求拆成可验收的前端 Story | `docs/requirements/{迭代}/STORY-FE-*.md` | 详设、代码、改 OpenAPI |
| `frontend-detail-design` | 把 Story 转成页面详设 | `docs/design/{迭代}/DD-FE-*.md` | 改 Story、写代码 |
| `frontend-feature-coding` | TDD 实现页面/组件 | `pages/`/`components/`/`services/` + 测试 | 拆卡、详设、改 OpenAPI |

**核心原则**：

1. **接口语义只认 OpenAPI**（`docs/handoff/openapi/booking-bff-app.yaml`）；前端不得发明字段/错误码
2. **每张前端 Story 必须点名本卡 `operationId`**，不能只丢整份 YAML
3. **只调 BFF**（`/api/v1/booking/app/`）；业务成败看 `body.code === 200`
4. **性能**：setData 合并低频、`onUnload` 解绑监听/清定时器（见 `rules/miniprogram-performance.md`）

### 三段输入一览

| Skill | 关键输入 | 产出 |
|-------|----------|------|
| story-splitting | 后端 OpenAPI + 契约版本 + Epic/PRD/原型 + **后端 Story 摘要** | STORY-FE-*.md |
| detail-design | 前端 Story + 后端 OpenAPI + 原型 + Rule | DD-FE-*.md |
| feature-coding | 前端 Story + 前端详设 + 后端 OpenAPI + Rule | pages/components/services + 测试 |

> 详设输入 = 上一段产出 + OpenAPI；编码输入 = 上两段产出 + OpenAPI。OpenAPI 贯穿三段。

---

## 二、前置准备（每次开工前确认）

```text
1. 当前迭代：config/current-sprint（如 2026-S01）
2. 后端契约：docs/handoff/openapi/booking-bff-app.yaml
3. 契约版本：docs/handoff/VERSION（tag 或 commit SHA）
4. 原型：后端仓 docs/prototype/（或 handoff）
```

若 `docs/handoff/VERSION` 为 `TBD`，先从后端仓同步 OpenAPI 再开工。

---

## 三、Skill 1：需求拆解（frontend-story-splitting）

### 何时用

- 新 Epic / 迭代规划 / 从 PRD 或后端 Story 拆前端卡
- 需要写 `docs/requirements/{迭代}/STORY-FE-*.md`

### 输入

| 输入 | 必须？ | 来源 | 说明 |
|------|--------|------|------|
| **后端 OpenAPI** | ✅ 必须 | `docs/handoff/openapi/booking-bff-app.yaml` | 接口字段/错误码/examples 唯一真相；拆卡时检索本页 `operationId` |
| **契约版本** | ✅ 必须 | `docs/handoff/VERSION` | tag 或 commit SHA；联调对齐 |
| **Epic / PRD / 原型** | ✅ 必须有（至少其一） | 后端仓 `docs/requirements/epics/`、`docs/prototype/` | 用户价值与页面范围 |
| **后端 Story 摘要** | ⭐ 强烈推荐 | 后端 `STORY-*` 的 §1 用户故事 + §2.3 前端职责 + 相关 AC/BR | 范围、职责边界、业务规则；**默认只读摘要，整卡作链接** |
| **完整后端详设（DD）** | ◯ 可选 | 后端 `DD-STORY-*` §5 摘录 | OpenAPI 不足时只发 §5；**不必默认发整卡** |
| **领域词表** | ◯ 降级 | `glossary/domain-glossary.md` | 术语一致 |
| **Rule** | ✅ 必读 | `rules/miniprogram-project.md`、`rules/api-client-conventions.md` | 目录/命名/请求层约束 |

**输入获取方式**：

- 后端 Story 摘要：打开后端 `STORY-*`，复制 §1 + §2.3 + 相关 AC/BR 到提示词；或 `@` 后端 Story 路径让 AI 自取摘要
- OpenAPI：本仓 `docs/handoff/openapi/` 已同步副本；提示词里 `@` 该文件
- 原型：后端仓 `docs/prototype/源项目原型 demo/*.html`；可 `@` 或描述文件名

### 产出格式

每张 `STORY-FE-*` 必含三节：

```markdown
## 契约
| 项 | 值 |
|----|-----|
| OpenAPI 文件 | docs/handoff/openapi/booking-bff-app.yaml |
| 契约版本 | 9f3673b（或 tag 2026-S01-rc1） |
| baseUrl | /api/v1/booking/app |

## 本卡 API 范围
| AC | operationId | Method | Path | 说明 |
|----|-------------|--------|------|------|

## 不在本卡范围
- 列出其它 operationId，防止编码越界
```

### 提示词 Demo

#### Demo 1：从后端 Story 拆前端卡（契约驱动）

```text
/frontend-story-splitting

后端 Story：STORY-2026-S01-002（首页进行中预约）
后端 Story 摘要：
- §1 用户故事：车主打开小程序首页，知道是否有进行中预约单，看到进度摘要
- §2.3 前端职责：根据 hasActiveReservation 切换首页分支；跳转目的地/我的订单/导航到梯
- 相关 AC：AC-01～04、AC-06

契约：docs/handoff/openapi/booking-bff-app.yaml @ 9f3673b
本卡涉及的 operationId：getActiveReservation（GET /reservations/active）

请拆出前端 Story STORY-FE-2026-S01-002，AC 用 Given/When/Then，字段认 OpenAPI examples。
纯 UI（底 Tab、地图背景）标 UI: TBD。
```

#### Demo 2：从 PRD + 原型拆卡（产品驱动）

```text
/frontend-story-splitting

输入：
- Epic：EPIC-{项目} §4.1
- 原型：docs/prototype/源项目原型 demo/目的地.html
- 契约：docs/handoff/openapi/booking-bff-app.yaml @ 9f3673b

请拆「目的地搜索 + 车场列表」前端 Story。
在 openapi.yaml 中检索 /lots 相关 operation，列出本卡 operationId 范围。
后端 Story 尚未拆，标注「后端Story: TBD」。
```

#### Demo 3：增量补卡

```text
/frontend-story-splitting

已有 STORY-FE-2026-S01-002（首页）。现需补「订单详情页」前端卡。
契约：docs/handoff/openapi/booking-bff-app.yaml @ 9f3673b
本卡 operationId：getOrderDetail（若 OpenAPI 已有）/ 否则标「待后端补 OpenAPI」
```

---

## 四、Skill 2：详细设计（frontend-detail-design）

### 何时用

- `STORY-FE-*` 已定稿，需出页面详设
- 需要写 `docs/design/{迭代}/DD-FE-*.md`

### 输入

| 输入 | 必须？ | 来源 | 说明 |
|------|--------|------|------|
| **前端 Story** | ✅ 必须 | `docs/requirements/{迭代}/STORY-FE-*.md` | 上一段 story-splitting 产出；含本卡 operationId 范围 |
| **后端 OpenAPI** | ✅ 必须 | `docs/handoff/openapi/booking-bff-app.yaml` | 读 schema/examples 设计状态机与字段展示 |
| **契约版本** | ✅ 必须 | `docs/handoff/VERSION` | 与 Story 一致 |
| **原型** | ◯ 可选 | 后端仓 `docs/prototype/*.html` | 视觉参考；无则标 `TBD` |
| **系统画像** | ✅ 必读 | `architecture/system-landscape.md` | 路由/分包/集成边界 |
| **领域词表** | ◯ 降级 | `glossary/domain-glossary.md` | 术语一致 |
| **Rule** | ✅ 必读 | `rules/miniprogram-project.md`、`rules/api-client-conventions.md`、`rules/error-display-conventions.md`、`rules/miniprogram-performance.md` | 分层/请求/错误/性能约束 |

**输入获取方式**：

- Story：`@docs/requirements/{迭代}/STORY-FE-*.md`
- OpenAPI：`@docs/handoff/openapi/booking-bff-app.yaml`
- 原型：`@docs/prototype/.../*.html`（后端仓）或描述文件名

### 产出必含

1. 路由与页面（路径、分包、tabBar、跳转关系）
2. 组件树与 props（用到的 `components/`）
3. 页面状态机（加载/空/错/成功 + setData 关系）
4. **AC → operationId 映射表**（核心）
5. 错误展示（`code !== 200` 的 Toast/Modal）
6. 性能关注（倒计时/长列表/分包）
7. 原型追溯

### 提示词 Demo

#### Demo 4：首页详设

```text
/frontend-detail-design

Story：@docs/requirements/2026-S01/STORY-FE-2026-S01-002-active-booking-home.md
契约：docs/handoff/openapi/booking-bff-app.yaml @ 9f3673b
原型：docs/prototype/源项目原型 demo/存在进行中的预约单.html

请出 DD-FE-2026-S01-002，含：
- 页面状态机（loading / empty / error / hasActive / noActive）
- AC→operationId 映射表（getActiveReservation）
- 错误展示（401 由 http.js 处理；其它 code Toast message）
- 性能：onShow 拉取，下拉刷新；无倒计时
- 组件：进度卡片是否抽 components/reservation-card（跨页复用）
```

#### Demo 5：含倒计时页面的详设

```text
/frontend-detail-design

Story：@docs/requirements/2026-S01/STORY-FE-2026-S01-007-payment-countdown.md
契约：docs/handoff/openapi/booking-bff-app.yaml @ 9f3673b

待支付页有 5 分钟倒计时。请重点说明：
- 倒计时实现方式（用 setTimeout 递归 + 服务端 payDeadline 时间差，不用 setInterval + 高频 setData）
- setData 频率控制（≤ 1 次/秒，合并字段）
- onUnload 清理定时器
```

---

## 五、Skill 3：编码（frontend-feature-coding）

### 何时用

- Story + 详设就绪，开始写代码
- 需求变更后同步实现

### 输入

| 输入 | 必须？ | 来源 | 说明 |
|------|--------|------|------|
| **前端 Story** | ✅ 必须 | `docs/requirements/{迭代}/STORY-FE-*.md` | AC + 本卡 operationId 范围 |
| **前端详设** | ✅ 必须 | `docs/design/{迭代}/DD-FE-*.md` | 页面状态机、组件树、AC→operationId 映射 |
| **后端 OpenAPI** | ✅ 必须 | `docs/handoff/openapi/booking-bff-app.yaml` | 字段/错误码/examples；**不发明字段** |
| **契约版本** | ✅ 必须 | `docs/handoff/VERSION` | 与 Story/详设一致 |
| **系统画像** | ✅ 必读 | `architecture/system-landscape.md` | 分层/集成边界 |
| **Rule** | ✅ 必读 | `rules/miniprogram-project.md`、`rules/miniprogram-performance.md`、`rules/api-client-conventions.md`、`rules/error-display-conventions.md` | 目录/性能/请求/错误 |
| **代码审查规则** | ✅ 必读 | `rules/code-review.md` | 步骤 7 的档位/分级/报告 |
| **实现范围** | ◯ 可选 | 提示词指定 | 全 Story / 指定页 / 指定层 / 指定 AC |
| **领域词表** | ◯ 降级 | `glossary/domain-glossary.md` | 术语一致 |

**输入获取方式**：

- Story + 详设：`@docs/requirements/...` + `@docs/design/...`
- OpenAPI：`@docs/handoff/openapi/booking-bff-app.yaml`
- 变更场景：先确认 `docs/handoff/VERSION` 已更新到新 tag/commit

### 流程

```text
1. 加载 STORY-FE + DD-FE + OpenAPI + Rule
2. 契约对齐：确认本卡 operationId，读 schema/examples
3. TDD：先写 services/utils 单测，再写页面/组件
4. 实现：pages 调 services，不直接 wx.request
5. 性能自检：setData 合并、onUnload 清理
6. 验证：npm test 全绿 + 开发者工具预览 + AC 逐条对照
7. 代码审查：按 rules/code-review.md 审 diff + STORY-FE/DD-FE/OpenAPI；报告 docs/reviews/{迭代}/REVIEW-CODE-FE-*；L0 跳过并说明
```

### 提示词 Demo

#### Demo 6：实现首页（全 Story）

```text
/frontend-feature-coding 实现 STORY-FE-2026-S01-002

@docs/requirements/2026-S01/STORY-FE-2026-S01-002-active-booking-home.md
@docs/design/2026-S01/DD-FE-2026-S01-002-active-booking-home.md
契约：docs/handoff/openapi/booking-bff-app.yaml @ 9f3673b

本卡仅使用 operationId：getActiveReservation
成功判据：response.code === 200
- hasActiveReservation=false → 展示「目的地预约」入口
- hasActiveReservation=true → 展示进度卡片（字段见 ActiveReservationResponse examples）
- 401 → http.js 统一处理，页面静默
不要实现：searchLots、createBookingOrder 等其它 operationId。
```

#### Demo 7：只实现某一层

```text
/frontend-feature-coding 实现 STORY-FE-2026-S01-002
范围：仅 services/reservation.js + 单测，不写页面
@docs/requirements/2026-S01/STORY-FE-2026-S01-002-active-booking-home.md
```

#### Demo 8：需求变更后同步

```text
/frontend-feature-coding 按变更记录重新实现 STORY-FE-2026-S01-002

后端 OpenAPI 已更新：getActiveReservation 新增 spaceId 字段。
契约：docs/handoff/openapi/booking-bff-app.yaml @ 2026-S01-rc2
请先读 Story 变更记录，改测试，再改实现。
```

#### Demo 9：实现带倒计时页面

```text
/frontend-feature-coding 实现 STORY-FE-2026-S01-007-payment-countdown

@docs/requirements/2026-S01/STORY-FE-2026-S01-007-payment-countdown.md
@docs/design/2026-S01/DD-FE-2026-S01-007-payment-countdown.md

重点遵守 rules/miniprogram-performance.md：
- 倒计时用 setTimeout 递归，不用 setInterval + 每秒 setData
- onUnload 必须 clearTimeout
- 单次 setData 数据 < 256KB
```

---

## 六、端到端 Demo（一张卡走完三段）

以「首页进行中预约」为例，完整三段提示词：

### 第 1 段：拆卡

```text
/frontend-story-splitting

后端 Story：STORY-2026-S01-002（摘要：车主首页判断进行中预约，hasActiveReservation 切分支）
契约：docs/handoff/openapi/booking-bff-app.yaml @ 9f3673b
operationId：getActiveReservation（GET /reservations/active）

拆 STORY-FE-2026-S01-002，AC 用 Given/When/Then，字段认 OpenAPI examples。
```

### 第 2 段：详设

```text
/frontend-detail-design

Story：@docs/requirements/2026-S01/STORY-FE-2026-S01-002-active-booking-home.md
契约：docs/handoff/openapi/booking-bff-app.yaml @ 9f3673b
原型：docs/prototype/源项目原型 demo/存在进行中的预约单.html

出 DD-FE-2026-S01-002，含页面状态机 + AC→operationId 映射表 + 错误展示 + 性能关注。
```

### 第 3 段：编码

```text
/frontend-feature-coding 实现 STORY-FE-2026-S01-002

@docs/requirements/2026-S01/STORY-FE-2026-S01-002-active-booking-home.md
@docs/design/2026-S01/DD-FE-2026-S01-002-active-booking-home.md
契约：docs/handoff/openapi/booking-bff-app.yaml @ 9f3673b

仅用 getActiveReservation。401 由 http.js 处理。不引入其它 operationId。
```

---

## 七、提示词通用模板

无论哪段，建议都包含：

```text
{skill 名} {动作} {Story 编号}

@{Story 路径}
@{详设路径}            ← 编码段必填
契约：docs/handoff/openapi/booking-bff-app.yaml @ {版本}

本卡 operationId：{列出}
成功判据：response.code === 200
{特殊约束：性能/UI TBD/范围限制}
不要实现：{排除的 operationId}
```

---

## 八、常见反模式（避免）

| 反模式 | 正确做法 |
|--------|----------|
| 只丢整份 openapi.yaml、不点名 operationId | Story/提示词里明确本卡 operationId |
| 前端 AC 重新定义后端字段名 | 字段只认 OpenAPI schema |
| 页面直接 `wx.request` | 经 `api/http.js` 或 `services/` |
| `setInterval` 倒计时 + 每秒 `setData` | `setTimeout` 递归 + 时间差 |
| `onUnload` 不解绑 `wx.on*`/不清定时器 | onUnload 清理清单 |
| 跨段越界（编码时改 Story/OpenAPI） | 先回 story-splitting/detail-design |
| 401 在页面处理 | 401 统一在 `http.js` |

---

## 九、文件落点速查

| 工件 | 路径 |
|------|------|
| 前端 Story | `docs/requirements/{迭代}/STORY-FE-{迭代}-{序号}-{slug}.md` |
| 前端详设 | `docs/design/{迭代}/DD-FE-{迭代}-{序号}-{slug}.md` |
| 后端 OpenAPI 副本 | `docs/handoff/openapi/booking-bff-app.yaml` |
| 契约版本 | `docs/handoff/VERSION` |
| 代码审查报告 | `docs/reviews/{迭代}/REVIEW-CODE-FE-STORY-FE-{迭代}-{序号}-{slug}.md` |
| 页面代码 | `pages/{page}/{page}.{js,wxml,wxss,json}` |
| 组件代码 | `components/{comp}/{comp}.{js,wxml,wxss,json}` |
| 业务封装 | `services/{domain}.js` |
| 请求层 | `api/http.js` |
| 单测 | `{file}.test.js`（同目录或 `__tests__/`） |

---

## 十、延伸阅读

| 主题 | 文档 |
|------|------|
| AI 入口 | [frontend/README.md](README.md) |
| 方法论总览 | [docs/methodology/readme.md](docs/methodology/readme.md) |
| 系统画像 | [architecture/system-landscape.md](architecture/system-landscape.md) |
| 目录与命名 | [rules/miniprogram-project.md](./rules/miniprogram-project.md) |
| 性能与内存 | [rules/miniprogram-performance.md](./rules/miniprogram-performance.md) |
| 请求层 | [rules/api-client-conventions.md](./rules/api-client-conventions.md) |
| 错误展示 | [rules/error-display-conventions.md](./rules/error-display-conventions.md) |
| Skill：拆卡 | [skills/frontend-story-splitting/SKILL.md](./skills/frontend-story-splitting/SKILL.md) |
| Skill：详设 | [skills/frontend-detail-design/SKILL.md](./skills/frontend-detail-design/SKILL.md) |
| Skill：编码 | [skills/frontend-feature-coding/SKILL.md](./skills/frontend-feature-coding/SKILL.md) |

---

## 变更记录

| 日期 | 变更 |
|------|------|
| 2026-08-01 | 初版：三段 Skill 使用手册 + 提示词 Demo |
| 2026-08-01 | 补充：各 Skill 明确「输入」表（来源/必须性/获取方式）+ 三段输入一览 |
