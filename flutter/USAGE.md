# AI Native 使用手册（Flutter Android / iOS）

本手册沿用前端的章节组织和九个调用示例。示例预约业务、契约版本和目录在接入时按 [MIGRATION.md](MIGRATION.md) 处理。示例开头的 /flutter-… 表示调用该 Skill；工具未注册该命令时，从项目根指定 AI-Native/flutter/skills 下的对应 SKILL.md 即可。

> 配套：[flutter/README.md](README.md) · [docs/methodology/readme.md](docs/methodology/readme.md) · [architecture/system-landscape.md](architecture/system-landscape.md)

---

## 快速导航

| 我想… | 看 |
|--------|----|
| 接入或升级 | [MIGRATION.md](MIGRATION.md) |
| 看总览 | [总览](#总览) |
| 确认开工前提 | [前置准备](#前置准备) |
| 拆卡 / 详设 / 编码 | [需求拆解](#需求拆解) · [详细设计](#详细设计) · [编码](#编码) |
| 修复已有功能的 Bug | [故障反馈示例](#修复已有功能的-bug) |
| 看调用示例 | [端到端 Demo](#端到端-demo) · [提示词通用模板](#提示词通用模板) |
| 配置环境或打包 | [打包配置](rules/testing-release.md#打包配置) |
| 查反模式与落点 | [常见反模式](#常见反模式) · [文件落点速查](#文件落点速查) |
| 延伸阅读 | [延伸阅读](#延伸阅读) |

---

## 总览

```text
Epic/PRD/原型 + 适用的后端 OpenAPI handoff
        ↓
flutter-story-splitting   →  STORY-Flutter-*.md（AC + 本卡 operationId 范围）
        ↓
flutter-detail-design      →  DD-Flutter-*.md（页面状态机、组件树、AC→operationId 映射）
        ↓
flutter-feature-coding     →  Widget / ViewModel / Repository + 测试
        ↓
代码审查（rules/code-review.md）→ REVIEW-CODE-Flutter-*（联调/提测前）
```

| Skill | 做什么 | 产出 | 不做什么 |
|-------|--------|------|----------|
| `flutter-story-splitting` | 把需求拆成可验收的 Flutter Story | `docs/requirements/{迭代}/STORY-Flutter-*.md` | 详设、代码、改 OpenAPI |
| `flutter-detail-design` | 把 Story 转成页面详设 | `docs/design/{迭代}/DD-Flutter-*.md` | 改 Story、写代码 |
| `flutter-feature-coding` | TDD 实现页面/组件 | `lib/` 及本卡的原生适配 + 测试 | 拆卡、详设、改 OpenAPI |

**核心原则**：

1. **接口语义只认 OpenAPI**（`docs/handoff/openapi/booking-bff-app.yaml`）；客户端不得发明字段/错误码
2. **调用后端的 Flutter Story 必须点名本卡 `operationId`**，不能只丢整份 YAML
3. **契约边界**：示例只调 booking BFF，成功判据取自 handoff。纯 UI、本地或仅原生 SDK 功能的 API 范围填 N/A
4. **性能**：限制 Widget 重建范围，dispose 时释放监听与 Timer（见 `rules/flutter-performance.md`）
5. **设计稿登记**：视觉项在 STORY-Flutter「设计稿」节登记稿件位置与状态；无稿才标 `UI: TBD`，不允许整卡视觉项全留空

### 三段输入一览

| Skill | 关键输入 | 产出 |
|-------|----------|------|
| story-splitting | 适用的后端交接包 + Epic/PRD/原型 + **后端 Story 摘要** | STORY-Flutter-*.md（含「设计稿」节） |
| detail-design | Flutter Story + 适用的后端 OpenAPI + 设计稿（按卡登记） + Rule | DD-Flutter-*.md |
| feature-coding | Flutter Story + Flutter 详设 + 适用的后端 OpenAPI + Rule | Flutter 页面、Widget 和数据层 + 测试 |

> 进入详设前核对每条 AC 的验收依据。进入编码前核对本次 AC 的状态、失败分支、平台差异和验证方式。网络 AC 在三段引用同一契约版本。

---

## 前置准备

### 接入与升级

首次接入按 [MIGRATION.md](MIGRATION.md) 完成 handoff、画像、锚点、Golden、分发与裁剪；旧布局迁移和模板升级也由该指南维护。

开工前读取 `config/current-sprint` 和画像。网络卡须取得同版交接包（OpenAPI、VERSION、stories-index.md），并核对本卡 operationId；VERSION 缺失、为空或 `TBD` 时阻断相关网络卡，按接入指南补齐。纯 UI、本地或仅原生 SDK 且无后端调用的卡填 `N/A`，仍需明确交互、数据或 SDK 验收依据。

**路径怎么读**

| 文档中的路径 | 接入后的基准目录 |
|---|---|
| `docs/handoff/`、Golden、方法论、原型资料、`skills/`、`rules/`、`templates/`、`config/`、`architecture/`、`glossary/` | 工作流线根 `AI-Native/flutter/` |
| 迭代 Story、DD、审查报告（`docs/{requirements,design,reviews}/{迭代}/`）、`lib/`、`test/`、`integration_test/`、`android/`、`ios/`、Dart 和 Flutter 命令 | 画像 §3.2 的应用根，单应用通常就是项目根 |

后续调用示例按应用就在项目根编写；多包仓从项目根调用时，给应用工件加上画像 §3.2 的应用根前缀。示例中，文件名和版本替换为本卡实际值。文档内的 Markdown 链接按所在文件解析。

---

## 需求拆解

### 何时用

- 新 Epic / 迭代规划 / 从 PRD 或后端 Story 拆 Flutter 卡
- 需要写 `docs/requirements/{迭代}/STORY-Flutter-*.md`

### 输入

| 输入 | 必须？ | 来源 | 说明 |
|------|--------|------|------|
| **后端 OpenAPI** | 网络 AC 必备 | `docs/handoff/openapi/booking-bff-app.yaml` | 接口字段/错误码/examples 唯一真相；拆卡时检索本页 `operationId` |
| **契约版本** | 网络 AC 必备 | `docs/handoff/VERSION` | tag 或 commit SHA；联调对齐 |
| **Epic / PRD / 原型** | ✅ 必须有（至少其一） | 后端仓 `docs/requirements/epics/`、`docs/prototype/` | 用户价值与页面范围 |
| **后端 Story 索引** | 网络 AC 必备 | `docs/handoff/stories-index.md` | 按服务和后端 Story 定位 operationId，只读 |
| **后端 Story 摘要** | ⭐ 强烈推荐 | 后端 `STORY-*` 的 §1 用户故事 + §2.3 客户端职责 + 相关 AC/BR | 范围、职责边界、业务规则；**默认只读摘要，整卡作链接** |
| **完整后端详设（DD）** | ◯ 可选 | 后端 `DD-STORY-*` §5 摘录 | OpenAPI 不足时只发 §5；**不必默认发整卡** |
| **领域词表** | ◯ 降级 | `glossary/domain-glossary.md` | 术语一致 |
| **Rule** | ✅ 必读 | `rules/flutter-project.md`、`rules/api-client-conventions.md` | 目录/命名/请求层约束 |

**输入获取方式**：

- 后端 Story 摘要：打开后端 `STORY-*`，复制 §1 + §2.3 + 相关 AC/BR 到提示词；或 `@` 后端 Story 路径让 AI 自取摘要
- OpenAPI：本仓 `docs/handoff/openapi/` 已同步副本；提示词里 `@` 该文件
- 原型（交互稿，拆卡输入）：后端仓 `docs/prototype/源项目原型 demo/*.html`；可 `@` 或描述文件名；拆卡时登记进 STORY-Flutter「设计稿」节，之后按设计稿管理

### 产出格式

每张 `STORY-Flutter-*` 必含四节：

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

## 设计稿
| 页面/组件 | 稿件位置 | 状态 |
|-----------|---------|------|
| 首页-框架 | docs/prototype/home-frame.png | 已定稿 |

- 有稿登记位置与状态；无稿写 `无 → UI: TBD`；纯 UI 卡本节是主要验收依据

## 不在本卡范围
- 列出其它 operationId，防止编码越界
```

### 提示词 Demo

#### Demo 1：从后端 Story 拆 Flutter 卡（契约驱动）

```text
/flutter-story-splitting

后端 Story：STORY-2026-S01-002（首页进行中预约）
后端 Story 摘要：
- §1 用户故事：车主打开 App 首页，知道是否有进行中预约单，看到进度摘要
- §2.3 客户端职责：根据 hasActiveReservation 切换首页分支；跳转目的地/我的订单/导航到梯
- 相关 AC：AC-01～04、AC-06

契约：AI-Native/flutter/docs/handoff/openapi/booking-bff-app.yaml @ 9f3673b
本卡涉及的 operationId：getActiveReservation（GET /reservations/active）

请拆出 Flutter Story STORY-Flutter-2026-S01-002，AC 用 Given/When/Then，字段认 OpenAPI examples。
视觉项（底 Tab、地图背景）在「设计稿」节登记稿件位置；无稿才标 UI: TBD。
```

#### Demo 2：从 PRD + 原型拆卡（产品驱动）

```text
/flutter-story-splitting

输入：
- Epic：EPIC-{项目} §4.1
- 原型（交互稿）：AI-Native/flutter/docs/prototype/源项目原型 demo/目的地.html
- 契约：AI-Native/flutter/docs/handoff/openapi/booking-bff-app.yaml @ 9f3673b

请拆「目的地搜索 + 车场列表」Flutter Story。
在 openapi.yaml 中检索 /lots 相关 operation，列出本卡 operationId 范围。
设计稿（目的地.html）已定稿，登记到「设计稿」节。
后端 Story 尚未拆，标注「后端Story: TBD」。
```

#### Demo 3：增量补卡

```text
/flutter-story-splitting

已有 STORY-Flutter-2026-S01-002（首页）。现需补「订单详情页」客户端卡。
契约：AI-Native/flutter/docs/handoff/openapi/booking-bff-app.yaml @ 9f3673b
本卡 operationId：getOrderDetail（若 OpenAPI 已有）/ 否则标「待后端补 OpenAPI」
```

---

## 详细设计

### 何时用

- `STORY-Flutter-*` 已定稿，需出页面详设
- 需要写 `docs/design/{迭代}/DD-Flutter-*.md`

### 输入

| 输入 | 必须？ | 来源 | 说明 |
|------|--------|------|------|
| **Flutter Story** | ✅ 必须 | `docs/requirements/{迭代}/STORY-Flutter-*.md` | 上一段 story-splitting 产出；含本卡 operationId 范围 |
| **后端 OpenAPI** | 网络 AC 必备 | `docs/handoff/openapi/booking-bff-app.yaml` | 读 schema/examples 设计状态机与字段展示 |
| **契约版本** | 网络 AC 必备 | `docs/handoff/VERSION` | 与 Story 一致 |
| **设计稿** | ◯ 按 Story 卡登记 | Figma Frame、交付截图或交互稿（位置见 STORY-Flutter「设计稿」节） | 视觉参考；卡上 `UI: TBD` 项不可猜样式 |
| **系统画像** | ✅ 必读 | `architecture/system-landscape.md` | 路由/模块/平台边界 |
| **领域词表** | ◯ 降级 | `glossary/domain-glossary.md` | 术语一致 |
| **Rule** | ✅ 必读 | `rules/flutter-project.md`、`rules/api-client-conventions.md`、`rules/error-display-conventions.md`、`rules/flutter-performance.md` | 分层/请求/错误/性能约束 |

**输入获取方式**：

- Story：`@docs/requirements/{迭代}/STORY-Flutter-*.md`
- OpenAPI：`@AI-Native/flutter/docs/handoff/openapi/booking-bff-app.yaml`
- 设计稿：按 STORY-Flutter「设计稿」节登记的位置 `@` 对应稿件；位置或状态冲突时确认采用的稿件；卡未登记且有稿时在 DD 注明「详设补登」

### 产出必含

1. 路由与页面（路由参数、模块、Tab 返回栈、深链）
2. Widget 树、构造参数与回调
3. 页面状态机（加载/空/错/成功及关联的状态所有者）
4. **AC → operationId 映射表**（核心）
5. 错误展示（按契约映射到字段提示、SnackBar、Dialog 或登录恢复）
6. 性能关注（倒计时/长列表/资源释放）
7. 设计稿追溯（沿用 Story 卡「设计稿」节登记并逐条核对）

### 提示词 Demo

#### Demo 4：首页详设

```text
/flutter-detail-design

Story：@docs/requirements/2026-S01/STORY-Flutter-2026-S01-002-active-booking-home.md
契约：AI-Native/flutter/docs/handoff/openapi/booking-bff-app.yaml @ 9f3673b
设计稿：@AI-Native/flutter/docs/prototype/源项目原型 demo/存在进行中的预约单.html（按 STORY-Flutter「设计稿」节登记）

请出 DD-Flutter-2026-S01-002，含：
- 页面状态机（loading / empty / error / hasActive / noActive）
- AC→operationId 映射表（getActiveReservation）
- 错误展示（鉴权失效由会话层处理，其他错误按 AC 提示）
- 性能：首次进入或恢复后按数据新鲜度刷新，支持下拉刷新；无倒计时
- 组件：进度卡片是否抽 ReservationCard Widget（跨页复用）
```

#### Demo 5：含倒计时页面的详设

```text
/flutter-detail-design

Story：@docs/requirements/2026-S01/STORY-Flutter-2026-S01-007-payment-countdown.md
契约：AI-Native/flutter/docs/handoff/openapi/booking-bff-app.yaml @ 9f3673b

待支付页有 5 分钟倒计时。请重点说明：
- 倒计时实现方式（根据服务端 payDeadline 与当前时间差计算，恢复前台时重算）
- 限制重建范围，只更新倒计时文本
- dispose 取消 Timer
```

---

## 编码

### 何时用

- Story + 详设就绪，开始写代码
- 需求变更后同步实现
- 已有功能与原验收条件不符，需要复现和修复

### 输入

| 输入 | 必须？ | 来源 | 说明 |
|------|--------|------|------|
| **Flutter Story** | ✅ 必须 | `docs/requirements/{迭代}/STORY-Flutter-*.md` | AC + 本卡 operationId 范围 |
| **Flutter 详设** | ✅ 必须 | `docs/design/{迭代}/DD-Flutter-*.md` | 页面状态机、组件树、AC→operationId 映射 |
| **后端 OpenAPI** | 网络 AC 必备 | `docs/handoff/openapi/booking-bff-app.yaml` | 字段/错误码/examples；**不发明字段** |
| **契约版本** | 网络 AC 必备 | `docs/handoff/VERSION` | 与 Story/详设一致 |
| **系统画像** | ✅ 必读 | `architecture/system-landscape.md` | 分层/集成边界 |
| **Rule** | ✅ 必读 | `rules/flutter-project.md`、`rules/flutter-performance.md`、`rules/api-client-conventions.md`、`rules/error-display-conventions.md` | 目录/性能/请求/错误 |
| **代码审查规则** | ✅ 必读 | `rules/code-review.md` | 步骤 7 的档位/分级/报告 |
| **实现范围** | ◯ 可选 | 提示词指定 | 全 Story / 指定页 / 指定层 / 指定 AC |
| **领域词表** | ◯ 降级 | `glossary/domain-glossary.md` | 术语一致 |

**输入获取方式**：

- Story + 详设：`@docs/requirements/...` + `@docs/design/...`
- OpenAPI：`@AI-Native/flutter/docs/handoff/openapi/booking-bff-app.yaml`
- 变更场景：先确认 `docs/handoff/VERSION` 已更新到新 tag/commit

### 流程

```text
1. 加载 STORY-Flutter + DD-Flutter + OpenAPI + Rule；按 Story「设计稿」节对照稿件（`UI: TBD` 项向用户要稿，不猜样式）
2. 契约对齐：确认本卡 operationId，读 schema/examples
3. TDD：先写 ViewModel/Repository 单测和 Widget 测试，再实现对应行为
4. 实现：Widget 将事件交给 ViewModel，由 ViewModel 经 Repository 访问业务数据。按工程规则「中文业务注释写法」标明页面与组件对应的 UI、工具的输入输出、ViewModel 各字段的用途，并核对接口与 Bean 的契约注释。
5. 性能自检：局部重建、dispose 与前台恢复
6. 验证：格式检查、flutter analyze、flutter test 通过 + 本卡设备验证 + AC 逐条对照
7. 代码审查：按 rules/code-review.md 审 diff + STORY-Flutter/DD-Flutter/OpenAPI（含设计稿还原）；报告 docs/reviews/{迭代}/REVIEW-CODE-Flutter-*；L0 跳过并说明
```

### 提示词 Demo

#### 修复已有功能的 Bug

可以直接描述问题，由 AI 查找原卡和详设。手头已有设备、版本或复现步骤时，一并提供即可。处理流程见[编码 Skill 的缺陷修复入口](skills/flutter-feature-coding/SKILL.md#修复已有功能的-bug)。

```text
/flutter-feature-coding 修复支付返回后订单状态没有刷新的问题。
在 Android 测试机上，从订单详情付款后自动返回，页面仍显示“待支付”；
手动刷新后显示“已支付”。预期返回时就能看到服务端确认的状态。
```

#### Demo 6：实现首页（全 Story）

```text
/flutter-feature-coding 实现 STORY-Flutter-2026-S01-002

@docs/requirements/2026-S01/STORY-Flutter-2026-S01-002-active-booking-home.md
@docs/design/2026-S01/DD-Flutter-2026-S01-002-active-booking-home.md
契约：AI-Native/flutter/docs/handoff/openapi/booking-bff-app.yaml @ 9f3673b

本卡仅使用 operationId：getActiveReservation
成功判据：response.code == 200
- hasActiveReservation=false → 展示「目的地预约」入口
- hasActiveReservation=true → 展示进度卡片（字段见 ActiveReservationResponse examples）
- 401 → 会话层统一处理，页面静默
不要实现：searchLots、createBookingOrder 等其它 operationId。
```

#### Demo 7：只实现某一层

```text
/flutter-feature-coding 实现 STORY-Flutter-2026-S01-002
范围：仅预约模块的 reservation_repository.dart 和单测
详设：@docs/design/2026-S01/DD-Flutter-2026-S01-002-active-booking-home.md
@docs/requirements/2026-S01/STORY-Flutter-2026-S01-002-active-booking-home.md
```

#### Demo 8：需求变更后同步

```text
/flutter-feature-coding 按变更记录重新实现 STORY-Flutter-2026-S01-002

后端 OpenAPI 已更新：getActiveReservation 新增 spaceId 字段。
契约：AI-Native/flutter/docs/handoff/openapi/booking-bff-app.yaml @ 2026-S01-rc2
请先读 Story 变更记录，改测试，再改实现。
```

#### Demo 9：实现带倒计时页面

```text
/flutter-feature-coding 实现 STORY-Flutter-2026-S01-007-payment-countdown

@docs/requirements/2026-S01/STORY-Flutter-2026-S01-007-payment-countdown.md
@docs/design/2026-S01/DD-Flutter-2026-S01-007-payment-countdown.md

重点遵守 AI-Native/flutter/rules/flutter-performance.md：
- 倒计时按截止时间计算，恢复前台时重算
- dispose 时取消 Timer 和订阅
- 用局部监听更新倒计时文本
```

---

## 端到端 Demo

以「首页进行中预约」为例，完整三段提示词：

### 第 1 段：拆卡

```text
/flutter-story-splitting

后端 Story：STORY-2026-S01-002（摘要：车主首页判断进行中预约，hasActiveReservation 切分支）
契约：AI-Native/flutter/docs/handoff/openapi/booking-bff-app.yaml @ 9f3673b
operationId：getActiveReservation（GET /reservations/active）

拆 STORY-Flutter-2026-S01-002，AC 用 Given/When/Then，字段认 OpenAPI examples。
```

### 第 2 段：详设

```text
/flutter-detail-design

Story：@docs/requirements/2026-S01/STORY-Flutter-2026-S01-002-active-booking-home.md
契约：AI-Native/flutter/docs/handoff/openapi/booking-bff-app.yaml @ 9f3673b
设计稿：@AI-Native/flutter/docs/prototype/源项目原型 demo/存在进行中的预约单.html（按 STORY-Flutter「设计稿」节登记）

出 DD-Flutter-2026-S01-002，含页面状态机 + AC→operationId 映射表 + 错误展示 + 性能关注。
```

### 第 3 段：编码

```text
/flutter-feature-coding 实现 STORY-Flutter-2026-S01-002

@docs/requirements/2026-S01/STORY-Flutter-2026-S01-002-active-booking-home.md
@docs/design/2026-S01/DD-Flutter-2026-S01-002-active-booking-home.md
契约：AI-Native/flutter/docs/handoff/openapi/booking-bff-app.yaml @ 9f3673b

仅用 getActiveReservation。401 由会话层处理。不引入其它 operationId。
```

---

## 提示词通用模板

无论哪段，建议都包含：

```text
{skill 名} {动作} {Story 编号}

@{Story 路径}
@{详设路径}            ← 编码段必填
契约：AI-Native/flutter/docs/handoff/openapi/booking-bff-app.yaml @ {版本}

本卡 operationId：{列出}
设计稿：@{稿件路径}（无稿写 `无 → UI: TBD`）
成功判据：{以本卡契约为准，本地功能写可观察行为}
{特殊约束：性能/范围限制}
不要实现：{排除的 operationId}
```

---

| 任务 | 输入与输出调整 |
|---|---|
| 从后端 Story 拆卡 | 给用户故事、客户端职责、相关 AC/BR 和契约版本，只选当前操作 |
| 仅设置页主题切换 | 契约写“本地，N/A”；给出持久化、重启恢复和深浅主题 AC |
| 支付回调或地图选点 | 提供 SDK 版本、入口、回调和能力矩阵；DD 定义桥接与异常恢复 |
| 只交付某一层 | 指定 AC 和层，附 Story + DD，在验证结果注明未覆盖的端到端行为 |
| 倒计时页面 | 给截止时间来源，测试挂起后恢复、到期和页面释放 |
| 增量或需求变更 | 给旧卡、差异、契约新版本；顺序更新 AC、DD、失败测试和实现 |

## 常见反模式

| 反模式 | 正确做法 |
|--------|----------|
| 只丢整份 openapi.yaml、不点名 operationId | Story/提示词里明确本卡 operationId |
| 客户端 AC 重新定义后端字段名 | 字段只认 OpenAPI schema |
| Widget 直接发 HTTP | 经 ViewModel、Repository 和统一 HTTP 客户端 |
| 定时器按 tick 次数推算剩余时间 | 按截止时间计算，恢复前台时重新校准 |
| 页面退出仍监听原生事件 | 由订阅所有者取消监听并释放资源 |
| 跨段越界（编码时改 Story/OpenAPI） | 先回 story-splitting/detail-design |
| 401 在页面处理 | 会话层统一恢复认证 |
| 视觉 AC 一律标 `UI: TBD`、不登记设计稿 | 有稿登记 STORY-Flutter「设计稿」节；无稿才标 TBD |

---

## 文件落点速查

| 工件 | 路径 |
|------|------|
| Flutter Story | `docs/requirements/{迭代}/STORY-Flutter-{迭代}-{序号}-{slug}.md` |
| Flutter 详设 | `docs/design/{迭代}/DD-Flutter-{迭代}-{序号}-{slug}.md` |
| 后端 OpenAPI 副本 | `docs/handoff/openapi/booking-bff-app.yaml` |
| 契约版本 | `docs/handoff/VERSION` |
| 设计稿 | `docs/prototype/…`（位置登记在 STORY-Flutter「设计稿」节） |
| 代码审查报告 | `docs/reviews/{迭代}/REVIEW-CODE-Flutter-STORY-Flutter-{迭代}-{序号}-{slug}.md` |
| 页面代码 | `lib/features/{feature}/presentation/{page}_page.dart` |
| 模块内 UI 组件 | `lib/features/{feature}/presentation/widgets/{name}.dart` |
| ViewModel | `lib/features/{feature}/presentation/view_models/{name}_view_model.dart` |
| 模块内展示工具 | `lib/features/{feature}/presentation/utils/{name}.dart` |
| 跨模块公共 UI 组件 | `lib/common_widgets/{name}.dart` |
| 跨模块工具 | `lib/utils/{name}.dart` |
| 数据 Bean | `lib/features/{feature}/data/{name}_bean.dart` |
| Repository | `lib/features/{feature}/request/{name}_repository.dart` |
| Service 与业务网络接口 | `lib/features/{feature}/request/{name}_service.dart` |
| HTTP 客户端配置 | `lib/core/network/` |
| 单测 | `test/{feature}/{name}_test.dart` |

---

## 延伸阅读

| 主题 | 文档 |
|------|------|
| AI 入口 | [flutter/README.md](README.md) |
| 方法论总览 | [docs/methodology/readme.md](docs/methodology/readme.md) |
| 系统画像 | [architecture/system-landscape.md](architecture/system-landscape.md) |
| 目录与命名 | [rules/flutter-project.md](./rules/flutter-project.md) |
| 性能与内存 | [rules/flutter-performance.md](./rules/flutter-performance.md) |
| 请求层 | [rules/api-client-conventions.md](./rules/api-client-conventions.md) |
| 错误展示 | [rules/error-display-conventions.md](./rules/error-display-conventions.md) |
| Skill：拆卡 | [skills/flutter-story-splitting/SKILL.md](./skills/flutter-story-splitting/SKILL.md) |
| Skill：详设 | [skills/flutter-detail-design/SKILL.md](./skills/flutter-detail-design/SKILL.md) |
| Skill：编码 | [skills/flutter-feature-coding/SKILL.md](./skills/flutter-feature-coding/SKILL.md) |

---

Flutter 规则按本卡范围取用：[共享状态、存储与事件](rules/state-storage-events.md)、[Android/iOS 原生桥接](rules/platform-bridge.md)、[设计交接](rules/ui-design.md)、[测试与发布](rules/testing-release.md)。这些规则服务于上述三个阶段。

## 变更记录

| 日期 | 变更 |
|------|------|
| 2026-11-20 | 对齐新版前端导航；接入、升级与验收统一由 MIGRATION 维护，明确 handoff 待补门槛。 |
| 2026-11-17 | 对齐前端三段手册、九个场景示例和设计稿登记约定，替换为 Flutter 实现及双端验证。 |
