---
name: bugfix
description: >-
  从 bug 任务出发（含前置输入清晰度检查），按「复现测试（Red）→ 根因 → 最小修复 →
  自述影响 → 验证 → 报告」七步闭环修复。强制 TDD-Red 先行，禁止改测试断言来让测试通过，
  禁止大范围重构式修 bug，循环超 3 轮自动交还人工。用于 bug 修复、回归修复、线上 hotfix 等场景。
---

> **模板版说明**：本 Skill 自已落地的源项目抽取为通用模板。文中项目专属值（模块名 `booking-*`、包名 `com.hema`、错误码号段、具体路径与 Story 号）均为**示例**，接入项目时按 [MIGRATION.md](../../../MIGRATION.md) 清单替换；「本仓库」指接入后的目标项目。


# bugfix Skill — AI 修 bug 闭环

> 核心原则：**先澄清，再复现，再修复；最小改动；自述影响；测试兜底；超限交还人工。**
> 不靠 AI 自觉，靠流程约束 AI 行为边界。
> 设计依据：DD-STORY-2026-S01-093（源项目 bugfix Skill 设计卡）

## 定位与边界

- **做什么**：从 bug 任务出发（经前置判断澄清复现步骤后），按七步闭环修复，约束 AI 最小化改动、不引入新 bug
- **不做**：新功能开发（归 `feature-coding`）、重构（另开 Story 走 `high-level-design`）、接口变更（切 `detail-design`）、进程内/部署环境测试体系设计（归 `integration-test-design` / `api-blackbox-test`）、造数（切 `test-data-design`）
- **不做**：写 Java 业务代码（仅写复现测试 + 修复 diff）、改 Story/TS/OpenAPI/Rule 正文
- **不做**：实现 Hook 脚本（仅建议，落地用 `create-hook` Skill 另卡）
- **不做**：定义 GitLab CI job

## 何时触发

- 收到 bug 修复任务（输入可能不完整，经前置判断澄清后进入 Step 1）
- 回归修复、线上 hotfix
- **不触发**：新功能开发（用 `feature-coding`）、性能优化（另开 Story）、重构（另开 Story）

## 前置判断（输入清晰度检查，动手前强制）

> **核心原则**：不清晰的输入是 bug 引入新 bug 的第一大根因。AI 凭模糊输入"猜"修复，等于盲改。
> 收到 bug 任务后，**先做输入清晰度检查，不清晰就停下来用 AskQuestion 澄清，不进 Step 1**。

### 输入五要素清晰度清单

| # | 要素 | 清晰标准 | 不清晰示例 |
|---|------|---------|-----------|
| 1 | 现象 | 可观察的具体行为 | "系统不工作"/"页面坏了"（太泛） |
| 2 | 预期 | 明确的期望行为 | "应该正常"（没说具体什么） |
| 3 | 实际 | 与预期对比的具体差异 | 只说"报错"没说错什么 |
| 4 | 复现步骤 | 可稳定重复的操作路径 | "偶尔出现"/"特定数据才触发"（偶发） |
| 5 | 上下文 | 环境/版本/用户/数据状态 | 缺失（不知道在哪个环境复现） |

### 澄清触发条件（命中任一即停下来用 AskQuestion）

| 条件 | 澄清问题 |
|------|---------|
| 五要素任一缺失 | "请补充：{缺失要素}" |
| 现象太泛（"不工作"/"坏了"/"异常"） | "请描述具体可观察现象：返回了什么？界面显示什么？HTTP 状态码？" |
| 预期与实际未区分 | "请明确：预期是什么？实际是什么？两者差异在哪？" |
| 复现步骤模糊（"偶尔"/"特定数据"/"概率性"） | "请提供可稳定重复的复现路径；若是偶发，请提供触发条件与频率" |
| 现象与复现步骤矛盾（说 A 但步骤指向 B） | "现象描述与复现步骤不一致，请确认实际是哪个现象" |
| 缺关键上下文（环境/版本/用户/数据） | "请补充：在哪个环境（dev/test/prod）？哪个版本？哪个用户/数据状态？" |

### 澄清后处理

- 用户补全 → 重新过五要素清单，全清晰才进 Step 1
- 用户仍模糊 → **再次 AskQuestion**，最多 2 轮；超过 2 轮仍不清晰 → **阻断**，输出「输入不清晰，无法可靠修复，请提供完整 bug 描述后重试」
- **禁止**在五要素不清晰时进入 Step 1（硬性禁令）

## 跨服务/用户视角 bug 的复现策略

> 用户反馈常是"下单失败报 xxx"这种端到端视角，但 bugfix Skill 在某个域仓内执行（如 `order-impl`）。
> 本节规定如何把**用户视角**下沉到**本域可复现的契约**，避免 AI 硬在本域改而引入新 bug。

### 责任域定位（前置判断补充）

五要素澄清后，多一步**定位责任域**，判断根因是否在本域：

| 判定依据 | 责任域 | 处理 |
|----------|--------|------|
| 失败接口路径 `/api/v1/booking/app/...` + 错误码归属 `OrderErrorCode`（1500-1599） | 订单域 | 在 `order-impl` 跑 bugfix |
| 错误码归属 `InventoryErrorCode`（1600-1699） | 库存域 | 提示到 `inventory-impl` 跑 bugfix |
| 错误码归属 `BookingErrorCode`（400 段，BFF 守卫） | BFF 层 | 在 `booking-bff-app`/`booking-bff-admin` 跑 bugfix |
| HTTP 401/403（系统级，鉴权） | C 端车主鉴权 Filter 在本仓 `booking-bff-app`；B 端经 iam auth Gateway（另仓） | 先看接口路径：`/api/v1/booking/app/*` → 在 `booking-bff-app` 跑 bugfix；`/api/v1/booking/admin/*` → 怀疑 iam，停下来跟人确认 |
| HTTP 500 + 堆栈指向某域 | 堆栈所在域 | 按堆栈定位 |
| 在本域尝试复现后，单域内复现不出来（按域入口测仍 GREEN/无法触发） | 怀疑跨域编排 | 停下来，提示走 `integration-test-design` 或 `api-blackbox-test`，不在本域硬改 |

**根因不在本域** → 停下来用 AskQuestion 跟人确认换仓，**禁止**硬在本域改代码（BR-15）

### 复现层级选择（Step 1 补充）

在本域跑 Step 1 时，复现测试测**域入口**，不测内部分支：

| 域 | 域入口（复现测试测这里） | 不测 |
|----|------------------------|------|
| order | `OrderApi`（ApiImpl）/ `*Facade` | 内部 `*Service` 私有分支（靠已有单测覆盖） |
| inventory | `InventoryApi` / `*Facade` | 同上 |
| BFF | `@WebMvcTest` + MockMvc 打 Controller | Service 内部 |

> 复现测试测域入口 = 用与"BFF 会传下来的 DTO + 域内状态"等价的输入，在域入口触发与用户一致的失败。

### 跨服务依赖处理（Step 1 补充）

复现测试里其他域 `XxxApi` 的处理方式（与现有 `*ServiceTest`/`*FacadeTest` 风格一致）：

| 依赖 | 处理 | 理由 |
|------|------|------|
| 其他域 `XxxApi`（inventory/payment/push 等） | **Mock**（Mockito `@Mock`） | V1 同 JVM，单测层不连真依赖；跨域编排归 IT |
| 外部系统（支付/车场/IoT） | **Mock Client** | 不连外网 |
| DB | **@Sql fixture 或 Mock Mapper** | 与 `integration-test-design` 一致 |

> 真要全链路真依赖 → 不在 Step 1，走 Step 6 切 `integration-test-design` 或 `api-blackbox-test`。

### 用户可见现象 ↔ 域内断言映射（Step 1 补充）

复现测试的断言必须对齐**用户看到的**，不是只断言异常类型：

| 用户看到 | 域内断言 |
|----------|---------|
| toast/页面文案「xxx」 | 对齐 `BizException` 的 `message`（与 OpenAPI/Story 一致） |
| 接口返回 `code=1501` | 断言 `BizException.code == OrderErrorCode.XXX.getCode()` |
| HTTP 200 但 `result.code != 200` | 断言 `result.code` + 关键 `data` 字段 |
| HTTP 4xx/5xx | 断言 HTTP 状态 + 响应体 |

**禁止**只断言 `assertThatThrownBy().isInstanceOf(BizException.class)` 而不断言 `code`/`message`（BR-16）——否则修了域内断言但用户问题没解。

### 全链路验证出口（Step 6 补充）

Step 6 默认跑 `mvn -pl` 单测；以下情况**必须**额外切 `api-blackbox-test` 跑 BFF 主路径（部署态）：

| 触发条件 | 为什么 |
|----------|--------|
| 改动影响用户可见契约（错误码语义/响应字段/HTTP 状态） | 单测 mock 了 api，测不到 BFF 聚合后的真实响应 |
| 改动是 BFF Controller / Filter / 守卫 | 单测覆盖不到 HTTP 层 |
| Step 5"未覆盖风险"含用户路径 | 显式补验证 |
| bug 本身是端到端才触发（单域复现不出来） | 责任域定位时已怀疑跨域编排 |

> 切 `api-blackbox-test` 时按 §「与其他 Skill 的关系」衔接契约：smoke manifest 标注本次回归用例。

## 前置加载（按序点名）

| # | 资产 | 路径 | 缺失时 |
|---|------|------|--------|
| 1 | 受影响测试范围指引 | `references/impact-scope-guide.md` | **阻断** |
| 2 | 修复报告模板 | `templates/fix-report-template.md` | **阻断** |
| 3 | 系统画像 | `architecture/system-landscape.md` | 降级 |
| 4 | 工程骨架 | `booking-app` 模块结构 | 降级 |
| 5 | 迭代 | `config/current-sprint` | — |

> **缺失阻断提示**：「缺受影响测试范围指引/修复报告模板，无法执行七步闭环」

## 输入

- **初始输入**：bug 任务（五要素可能不完整：现象/预期/实际/复现步骤/上下文）
- **经前置判断澄清后**：五要素齐全才进入 Step 1
- **可选**：影响范围、相关日志/堆栈

### 触发示例

```text
/bugfix BUG-2026-001
现象：车位搜索返回空
预期：返回可用车位
实际：HTTP 200 但 list 为空
复现：搜索关键词「万象城」，DB 有 ENABLED 车场 + AVAILABLE 车位
```

## 输出

- 复现测试（责任域对应测试目录：`*-impl/src/test` 或 `booking-bff-*/src/test`，命名 `test_bugfix_{bugId}_{现象}`）
- 修复 diff（最小修改）
- 自述影响三段（改了什么/为什么/影响范围）
- 修复报告（对话输出；试点 + 线上 bug 落盘 `docs/qa/{迭代}/FIX-{迭代}-{序号}-{slug}.md`）
- 代码审查报告（Step 6.5）：`docs/reviews/{迭代}/REVIEW-CODE-FIX-{Bug编号}-{slug}.md`（L0 除外）
- **不产生**：业务功能新增、Story/OpenAPI 正文改动、非最小修改的重构

## 标准流程（七步闭环）

### 步骤总览

| Step | 名称 | 输入 | 输出 | 失败回退 |
|------|------|------|------|----------|
| 1 | 写复现测试 | bug 描述 + 复现步骤 | RED 的复现测试 | GREEN/假 RED → 回 Step 1 重写 |
| 2 | 根因定位 | 复现测试 + 堆栈 | 根因假设 + 调用链 | 根因不清 → 回 Step 1；超 2 次 → AskQuestion |
| 3 | 最小修复方案 | 根因假设 + 调用链 | 文件清单 + 改动理由 | 触公共代码/根因不在本域 → 停；重构冲动 → 砍 |
| 4 | 实施修复 | 方案 | 修复 diff | 复现仍 RED → 回 Step 3，计数器 +1 |
| 5 | 自述 diff + 影响面 | diff | 三段自述 | 缺段 → 不得进 Step 6 |
| 6 | 验证 | diff + 分级规则 | 测试结果 | 失败 → 修代码，计数器 +1；>3 → 交还人工 |
| 7 | 修复报告 | 上述全部 | 修复报告 | — |

> **循环计数器（关键）**：覆盖所有"修代码→跑测试→失败"循环，不分步骤。Step 4 复现 RED 回 Step 3 算 1 次；Step 6 受影响测试 RED 修代码算 1 次。总计数器 > 3 → 交还人工。跨步骤回退不重置计数器。**Step 1 初次跑复现测试 RED 不计数**（未修代码）；只有修代码后跑测试仍失败才计数。
>
> **交付闸门**：Step 6.5「独立代码审查」是七步之外的交付闸门，见下文；不计入循环计数器。

### Step 1：写复现测试（Red，强制）

**动作**：
1. 在责任域对应测试目录（`*-impl/src/test/java/.../` 或 `booking-bff-*/src/test/java/.../`）下找到或新建测试类
2. 写复现测试，命名 `test_bugfix_{bugId}_{现象}`
3. 运行该测试

**已有测试可用**：若已有测试能复现该 bug（跑出 RED 且断言失败匹配 bug 现象），直接用作复现测试，不必新写。已有测试就是"不能引入新 bug"的规格说明。

**通过条件**：测试 **RED 且是断言失败匹配 bug 现象**（不是编译错误/setup 异常的"假 RED"）

**失败回退**：
- 跑出 GREEN → 回 Step 1 重写（复现路径不对）
- 跑出 RED 但是编译错误/测试 setup 异常 → 回 Step 1 重写（"假 RED"不算复现）
- 无复现步骤/复现步骤模糊 → **阻断**，输出「前置判断已澄清过；此处仍无法稳定复现 → 请人工介入」

**约束**：
- 禁止改已有测试断言制造失败（BR-02）
- 禁止 `@Disabled` 跳过已有测试（BR-11）
- 复现测试须稳定可复现（偶发不算）

### Step 2：根因定位

**动作**：
1. 从失败堆栈/断言定位到具体类/方法
2. 用 Grep 查该符号引用链（谁调用了它、它调了谁）
3. 读最近 git log/blame 了解这段代码为什么这么写
4. 形成根因假设（一句话能说清"为什么会出现这个 bug"）

**失败回退**：根因不清 → 回 Step 1 检查复现路径是否准确。**回 Step 1 超过 2 次仍根因不清** → 停下来用 AskQuestion 跟人确认根因方向，不无限循环

**约束**：根因在公共代码（booking-common / hema-common / *-api 接口）→ **停下来用 AskQuestion 跟人确认**（BR-05），不擅自改；根因不在本域（按错误码号段定位属其它域）→ **停下来跟人确认换仓**（BR-15），不在本域硬改

**停下来时输出格式**（供人决策）：
- 根因位置：`文件:行`
- 为什么是公共代码：说明该符号属于 common/api 层
- 建议修复方向：最小修复建议
- 改动风险提示：影响面（哪些模块依赖该公共代码）

### Step 3：最小修复方案

**动作**：
1. 基于"最小修改原则"产出修复方案
2. 明确：改哪些文件、每个文件改什么、为什么这么改
3. 自检（硬指标，任一项为否须显式说明理由，否则砍掉该改动）：
   - [ ] 改动行数 ≤ 30？
   - [ ] 不改方法签名？
   - [ ] 不新增方法/类（除非显式说明理由，如修复必须的私有辅助方法）？
   - [ ] 不改可见性（public→private 等）？

**失败回退**：
- 触碰公共代码 → 停，AskQuestion 跟人确认（BR-05）
- 顺手重构冲动 → 砍掉；确需重构 → 切 `high-level-design` 另开 Story（AC-07）

**约束（高危清单，命中必须同步检查）**：
- 改方法签名 → 确认所有调用方（含 Mapper XML 反射调用）
- 改 MyBatis XML → 同步检查对应 Mapper 方法（BR-06）
- 改错误码 → 同步 OpenAPI 文档（BR-07，切 detail-design）
- 改 DTO 字段 → 同步序列化测试（BR-06）
- 改 *-api 接口 → 确认所有 *-impl 的 provider 实现

### Step 4：实施修复

**动作**：
1. 按 Step 3 方案逐处修改
2. 改完立即跑 Step 1 的复现测试

**通过条件**：复现测试 **GREEN**

**失败回退**：
- 复现测试仍 RED → **计数器 +1**（在"跑测试仍失败"那一刻计数），然后回 Step 3 调整方案（不是硬改代码）
- 计数器 > 3 → 交还人工（AC-08）

> **两个独立计数器**：①循环计数器（修代码→跑测试→失败，Step 4/Step 6 共用，>3 交还人工）；②Step 2 根因不清回退计数器（回 Step 1 超 2 次 → AskQuestion）。两者独立，不混计。

**约束**：
- 禁止改测试断言让测试通过（BR-11）
- 禁止 `@Disabled` 跳过失败测试（BR-11）
- 禁止大范围重构（提取方法、改继承结构、换设计模式）（BR-03）

### Step 5：自述 diff 与影响面（强制）

**动作**：在回复中输出以下三段，缺一不可

```markdown
## 改了什么
- file:line — 改动内容 — 理由

## 为什么这么改
- 一句话根因 + 一句话修复逻辑

## 影响范围
- 直接影响：改动的符号被哪些地方调用
- 间接影响：可能波及的模块/接口/页面
- 已有测试覆盖：哪些已有测试能拦住回归
- 未覆盖风险：哪些路径没有测试兜底（标注"需人工确认"）
```

**约束**：缺任一段 → 视为未完成 Step 5，不得进入 Step 6

### Step 6：验证（受影响测试分级）

**动作**：按改动位置决定跑哪些测试（详见 `impact-scope-guide.md` 决策树）

**分级规则摘要**（分级看**改动符号**——改的是方法签名还是方法体内部逻辑，不是被测方法本身的可见性）：
- 改 private/本类内部符号 → 跑该模块 `mvn -pl <module>/<impl> -am test`
- 改 public 方法**体内部逻辑**（非签名，契约没变） → 跑该 impl 模块（跨模块方通过 api mock 调用，不受 impl 内部变化影响）
- 改 public 方法**签名** 或 *-api 接口/DTO（契约变） → 跑所有依赖该 api 的模块
- 改 booking-common → 跑全量 `mvn test`
- 改 hema-common → 停下来，不归本仓库，交还人工
- 改 MyBatis XML → 跑该模块 + 该 Mapper 所有测试方法
- 改 OpenAPI 文档 → 跑 `tests/blackbox` 相关黑盒脚本

**失败回退**：
- 测试失败 → 修代码（不是修测试），**计数器 +1**
- 计数器 > 3 → **停下来交还人工**，输出当前状态摘要（已尝试方案 + 失败点 + 根因假设）

**全链路验证出口**：改动影响用户可见契约（错误码语义/响应字段/HTTP 状态）/ BFF Controller/Filter/守卫 / Step 5"未覆盖风险"含用户路径 / bug 端到端才触发 → **必须**额外切 `api-blackbox-test` 跑 BFF 主路径（见 §「跨服务/用户视角 bug 的复现策略」）

**约束**：
- 禁止改测试断言让测试通过（BR-11）
- 禁止 `@Disabled` 跳过失败测试（BR-11）

### Step 6.5：独立代码审查（合并前）

> 本步是七步闭环之外的交付闸门，不改变 Step 1–7 的计数与回退规则。

**触发**：Step 6 验证通过后、Step 7 修复报告/合并前。规则见 [code-review.md](../../rules/code-review.md)，报告模板见 [code-review-report.md](../../templates/code-review-report.md)。

**动作**：

1. **定档**：按规则 §二（L0 机械改动不派；L1 ≤3 文件；L2 一般；L3 核心链路/DDL/跨模块契约；公共代码/契约变更不得 L1）。
2. **提交审查**：独立审查人（新开的 AI 会话 / 审查 agent / 人），按规则 §三给全——档位、Bug 五要素、审查范围（`git diff HEAD` + `git status` 本次相关新增文件）、相关 Story/DD/OpenAPI、Step 6 测试结果、关注点（最小 diff、根因、回归、公共代码）。
3. **落盘**：实现者（主流程）写 `docs/reviews/{迭代}/REVIEW-CODE-FIX-{Bug编号}-{slug}.md`。
4. **闭环**：L1=P0/P1；L2=P0/P1 + 正确性/安全 P2；L3=P0–P2；P3 记录；不默认复审，连续 2 轮不通过交还人工。
5. **放行**：结论「通过」才允许合并/提交；Step 7 修复报告须记录审查结论。

**约束**：

- 审查通过前禁止 commit/push。
- 审查人只读，不修代码；不得用审查替代 Step 6 测试。
- L0 改动（纯注释/格式化/重命名/日志文案）不送审，在修复报告注明跳过原因。

### Step 7：修复报告

**动作**：输出修复报告

**落盘规则**：
- 日常修 bug → 仅对话输出，不落盘
- 试点 + 线上 bug → 落盘 `docs/qa/{迭代}/FIX-{迭代}-{序号}-{slug}.md`
- 公共代码 bug（人确认后由本 Skill 修复）→ 落盘

**报告格式**（详见 `fix-report-template.md`）：

```markdown
## 修复报告 — {Bug 编号/标题}
- Bug：{bugId / 标题}
- 根因：{一句话}
- 修复：{一句话}
- 改动文件：{清单}
- 复现测试：{测试方法名}（RED→GREEN）
- 影响范围：{Step 5"影响范围"摘要}
- 验证：{Step 6 测试命令与结果}
- 代码审查：{报告路径} / {L1/L2/L3} / {通过/不通过}
- 未覆盖风险：{Step 5"未覆盖风险"，无则"无"}
- 建议跟进：{是否需补测试/补 OpenAPI/补文档}
- 循环轮次：{Step 6 实际循环轮次}
```

## 硬性禁令（违反即停）

1. **禁止**在输入五要素不清晰时进入 Step 1（必须先过前置判断；复现步骤不明确是五要素之一，禁令 1 已覆盖）
2. **禁止**前置判断 AskQuestion 超 2 轮仍不清晰时不阻断
3. **禁止**复现测试跑出 GREEN 就进入修复（必须 RED 且断言失败匹配 bug 现象）
4. **禁止**改测试断言来让测试通过
5. **禁止**`@Disabled` 跳过失败测试
6. **禁止**大范围重构式修 bug（提取方法、换模式、改继承）
7. **禁止**擅自改 `booking-common` / `hema-common` / `*-api` 接口（须停下来跟人确认）
8. **禁止**改 MyBatis XML 不同步检查 Mapper 方法
9. **禁止**改错误码不同步 OpenAPI
10. **禁止**改 DTO 字段不同步序列化测试
11. **禁止**循环计数器超过 3 还不交还人工
12. **禁止**Step 5 缺任一段就进入 Step 6
13. **禁止**Step 2 根因不清反复回 Step 1 超 2 次仍不 AskQuestion
14. **禁止**根因不在本域时硬在本域改代码（须停下来 AskQuestion 换仓，BR-15）
15. **禁止**复现测试只断言异常类型不断言 `code`/`message`（BR-16）

## 与其他 Skill 的关系

| 触发条件 | 切换到 | 衔接契约 |
|----------|--------|----------|
| Step 3 发现修复涉及 OpenAPI/schema 变更 | `detail-design` | 改动文件路径 + 变更字段清单 |
| Step 6 需要造测试数据 | `test-data-design` | `seed_key` 命名 + DP profile 引用 |
| Step 6 需要跑部署环境回归 | `api-blackbox-test` | smoke manifest 中标注本次回归用例 |
| 试点/修复中发现是需求理解错 | `story-splitting` | 原 Story 编号 + 错误点说明 |
| 修复涉及跨服务重构（非最小修改） | `high-level-design` | 重构范围说明 |
| bugfix 完成，需补单测防回归 | `feature-coding` TDD-Red | 复现测试方法名 + 覆盖路径 |

**不切换的边界**：
- bug 在公共代码，人未确认 → 不切 detail-design（先等人确认）
- bug 是数据问题 → 不切任何 Skill（走数据修复，DBA/造数脚本）
- bug 是性能问题 → 不切 bugfix（性能优化另开 Story）

## 降级策略

| 缺失资产 | 处理 | 严重度 |
|----------|------|--------|
| impact-scope-guide / fix-report-template | **阻断**，输出「缺受影响测试范围指引/修复报告模板」 | 致命 |
| bug 描述 / 复现步骤缺失 | 前置判断阶段 AskQuestion 澄清；2 轮仍不清 → 阻断 | 致命 |
| bug 描述本身模糊（"不工作"/"坏了"/预期与实际未区分） | 前置判断阶段 AskQuestion 澄清；2 轮仍不清 → 阻断 | 致命 |
| 现象与复现步骤矛盾 | 前置判断阶段 AskQuestion 确认实际现象 | 致命 |
| 复现步骤模糊（"偶尔"/"特定数据"） | 前置判断阶段 AskQuestion 索要可稳定复现路径 | 致命 |
| 缺关键上下文（环境/版本/用户/数据） | 前置判断阶段 AskQuestion 补全 | 高 |
| Step 2 根因不清反复回 Step 1 | 超 2 次仍不清 → AskQuestion 跟人确认根因方向 | 高 |
| 复现测试跑出 GREEN | 回 Step 1 重写 | 致命 |
| 复现测试"假 RED"（编译错误/setup 异常） | 回 Step 1 重写 | 致命 |
| 系统画像 / 工程骨架 | 降级，按现有模块结构推断 | 中 |

## 检查清单（自验）

修完 bug 后，AI 必须逐条自检：

- [ ] 前置判断：输入五要素已清晰（现象/预期/实际/复现步骤/上下文）
- [ ] 前置判断：AskQuestion 不超过 2 轮（或已阻断）
- [ ] 复现测试从 RED 变 GREEN，且 RED 是断言失败匹配 bug 现象
- [ ] 没有改任何已有测试的断言
- [ ] 没有 `@Disabled` 任何测试
- [ ] 改动范围最小（自检 4 项全过，或超项已显式说明理由）
- [ ] 已输出"改了什么/为什么/影响范围"三段
- [ ] 已按分级规则跑了受影响测试
- [ ] 循环计数器 ≤ 3
- [ ] Step 2 根因不清回 Step 1 不超过 2 次（或已 AskQuestion）
- [ ] 责任域已定位：根因在本域（错误码归属/堆栈确认），不在本域已 AskQuestion 换仓
- [ ] 复现测试测的是域入口（Api/Facade 或 Controller），不是内部分支
- [ ] 复现测试断言对齐用户可见的 code/message/HTTP 状态（不只断言异常类型）
- [ ] 跨服务依赖用 Mock（与现有 *ServiceTest 风格一致），真全链路走 Step 6 黑盒
- [ ] 改 MyBatis XML 已同步检查 Mapper 方法
- [ ] 改错误码已同步 OpenAPI
- [ ] 改 DTO 字段已同步序列化测试
- [ ] 代码审查报告存在且结论通过（`docs/reviews/{迭代}/REVIEW-CODE-FIX-*`；L0 除外，需说明跳过原因）
- [ ] 已输出修复报告

## 配套资产

- `references/impact-scope-guide.md` — 受影响测试范围分级规则（本 Story 产出物）
- `templates/fix-report-template.md` — 修复报告模板（本 Story 产出物）
- [rules/code-review.md](../../rules/code-review.md) — 代码审查规则（Step 6.5）
- [code-review-report.md](../../templates/code-review-report.md) — 代码审查报告模板
- `rules/bugfix-conventions.md` — 配套 Rule（建议，落地另卡）
- `hooks` on_agent_save 跑测试 + 循环上限 — 配套 Hook（建议，用 `create-hook` Skill 落地另卡）

## 延伸阅读

- DD-STORY-2026-S01-093（源项目 bugfix Skill 设计卡）（详设）
- STORY-2026-S01-093（源项目 bugfix Skill 需求卡）
- [test-line.md](../../docs/methodology/test-line.md) §4.2（设计源头）
- [feature-coding SKILL](../feature-coding/SKILL.md)（新功能 TDD，边界对照）
- [detail-design SKILL](../detail-design/SKILL.md)（接口变更切出）
- [test-data-design SKILL](../test-data-design/SKILL.md)（造数切出）
- [api-blackbox-test SKILL](../api-blackbox-test/SKILL.md)（部署回归切出）
