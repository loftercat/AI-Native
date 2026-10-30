# 分类指引（classification-guide）

> 配套 [legacy-test-migration SKILL](../SKILL.md) Step 2/3/5。
> 两段式：**门禁（前置）→ 分层**。门禁未过不落层。

## 1. 总览

```text
gate ∈ {ok, G1, G2, G3, G4}        # 门禁（前置）
  gate≠ok ⇒ layer=—
layer ∈ {W1..W6, B1..B5, —}        # 分层（仅 gate=ok 且 status≠merged）
strategy ∈ {smoke, regression, contract, perf, uat, —}   # 横切标签
```

## 2. 门禁判定（Step 2）

判定顺序（首个命中即停；tie-break 按 G3→G1→G4→G2，`[AI推断]`）：

| 优先级 | gate | 判定 | status | 依据 |
|--------|------|------|--------|------|
| 1 | `G3` | 功能已下线**且有证据**（代码删除/接口下线/产品确认） | `obsolete`（候选） | BR-12 |
| 2 | `G1` | 预期缺失 / 预期矛盾 / 无法判定期望 | `needs_revision` | BR-03 |
| 3 | `G4` | 代码不可访问 / 缺 adapter / 无法锚定 | `blocked` | BR-15 |
| 4 | `G2` | 探索性 / 环境不可复现 / 无后端稳定断言点 | `manual` | BR-14 |
| 5 | `ok` | 以上均不命中 | `automated`（或 `merged`） | — |

> **G3 只标候选**：未确认前不删用例、不剔提测分母（BR-12/AC-12）。
> **G1 不生成候选断言**（BR-03）。

## 3. 分层判定（Step 3，仅 `gate=ok` 且 `status≠merged`）

### 3.1 白盒 W1~W6

| layer | 判定（命中即停） | 落点 |
|-------|------------------|------|
| W1 | 断言点在单类/方法内，无 Spring 上下文 | `*ServiceTest` → feature-coding |
| W2 | 断言点在 BFF HTTP 入口（状态码/JSON/鉴权） | `*ControllerTest` → feature-coding |
| W3 | 跨模块/跨域，真实 Spring + DB，单链路 | `*IT` → integration-test-design |
| W4 | 多步骤业务场景端到端（进程内） | `*ScenarioIT` → integration-test-design |
| W5 | 仅验证 Mapper SQL / 持久层切片 | Mapper 测试 → feature-coding |
| W6 | 前端组件（另仓） | frontend-feature-coding |

### 3.2 黑盒 B1~B5

| layer | 判定 | 落点 |
|-------|------|------|
| B1 | 真实部署 HTTP API（网关/鉴权链/契约） | api-blackbox-test |
| B2 | UI 端到端 | 前端另仓 e2e-test |
| B3 | 真实第三方联调（IAM/支付/车场） | api-blackbox-test |
| B4 | 性能/压力 | performance-test（规划） |
| B5 | 数据批处理/定时/对账 | integration-test-design + test-data-design |

### 3.3 白/黑裁决（ADR-7，仅 W vs B1/B3）

```text
部署态是否有增量？（网关 / 证书 / 配置 / 外部集成 / 多进程）
├─ 无增量（进程内可完整覆盖） → W 层
└─ 有增量                    → B1 / B3
B2（UI E2E）按用例形态；B4（性能）/B5（数据批处理）按场景属性直接成桶
```

## 4. 去重判定（Step 5，ADR-6）

```text
同锚点 + 同分支？
├─ 否 → 不合并
└─ 是 → 断言集合等价？
        ├─ 是 → 合并（保留代表，其余 status=merged + merged_into）
        └─ 否/存疑 → 两条都保留 + 待人工确认
```

跨层重复（UI/接口/集成同一能力）→ 只在最贴近实现的一层落自动化，其余标「已由 {代表编号} 覆盖」。

## 5. 层码顺序说明（与培训材料的差异）

`whitebox-layers-qa-boundary.marp.md` 列举顺序为「单元/BFF/集成/场景集成/**前端组件**/**持久层切片**」，本指引取 **W5=持久层切片、W6=前端组件**。
层义一致，仅编号顺序为 `[AI推断]`（Story §8）；对照培训材料时以层义为准。

## 6. strategy 映射

| strategy | 含义 | 来源 |
|----------|------|------|
| `smoke` | 核心主路径 | 用例自带 P0 / 人工指定 |
| `regression` | 回归 | 用例自带 P1/P2 |
| `contract` | 契约/鉴权链 | 接口契约类用例 |
| `perf` | 性能 | B4 |
| `uat` | 人工验收 | G2 / 不可自动化 |
| `—` | 未知 | 待人工确认（开放问题 #4） |

## 7. 反模式（禁止）

- ❌ 门禁未过就落层（违反不变式 1）
- ❌ `merged` 行仍填 `layer`（违反不变式 2）
- ❌ 把 G2/G3 判为 W/B 层
- ❌ 因「宁可多测」把部署态无增量用例也塞 B1（黑盒不过度设计）
- ❌ 断言集合存疑时强行合并
