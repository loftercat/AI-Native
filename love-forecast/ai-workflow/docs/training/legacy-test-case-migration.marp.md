---
marp: true
theme: default
paginate: true
size: 16:9
header: 'AI Native 测试线 · 存量用例改造'
footer: '分层执行 · 分工存放 · 黑盒筛选取自 blackbox-test-case-selection'
style: |
  section { font-size: 18px; padding: 16px 34px 10px; }
  h1 { color: #1E3A8A; font-size: 32px; margin: 0 0 4px; line-height: 1.1; }
  h2 { color: #1E40AF; font-size: 20px; margin: 6px 0 3px; border-bottom: 1px solid #E2E8F0; padding-bottom: 2px; }
  table { font-size: 15px; line-height: 1.32; margin: 3px 0; width: 100%; }
  th, td { padding: 4px 8px; }
  th { background: #F1F5F9; }
  code { background: #F1F5F9; font-size: 13px; padding: 0 3px; }
  p, li { line-height: 1.38; margin: 3px 0; }
  .funnel { font-size: 15px; line-height: 1.4; background: #F8FAFC; border-left: 3px solid #1E3A8A; padding: 6px 12px; margin: 4px 0; }
  .warn { background: #FEF3C7; border-left: 3px solid #D97706; padding: 6px 12px; margin: 4px 0; font-size: 15px; }
---

<!-- _class: lead -->

# 存量用例改造：2000 条怎么处理

**无 Story/AC、只有用例、没有自动化脚本 → 先分级，再落自动化**

---

## 1. 背景

| 现状 | 后果 |
|------|------|
| 数百～数千条用例，无需求卡、无 AC | 需求变更时无法判断「改测试还是改产品」 |
| 用例留在测试平台，**黑盒/白盒自动化尚未建设** | 提测靠人工回归，撑不住频繁发版 |
| 同一能力在 UI / 接口 / 步骤里**重复描述** | 若按条数 1:1 补脚本，先重复再烂尾 |
| 提测要求「P0/P1/P2 全跑过」 | 用例条数成唯一指标，与质量脱钩 |

<div class="warn">

**核心矛盾**：用例 **条目数** ≠ **可执行的自动化覆盖**；不宜把 2000 条全做成黑盒。

</div>

**改造目标**：分层执行（PR 白盒 / 发版黑盒 / 手工 UAT）+ 分工存放（禅道管流程、Git 管规格与代码）+ 条数收敛（方法数 ≪ 条目数）。

---

## 2. 2000 条如何分级处理

### 2.1 先盘点 → 一张矩阵定归属

每行一个 TC，标注：**业务域 · 优先级(P0/P1/P2) · 是否重复 · 是否有效 · 归属层 · status · 覆盖方法**。

```text
盘点 → 分层 → 去重 → 定维护边界 → 落盘 → 门禁
```

### 2.2 分层归属

| 验证目标 | 归属层 | 执行时机 |
|----------|--------|----------|
| 分支、状态机、事务、契约、DB 断言 | **白盒**（`*ServiceTest` / `*ControllerTest` / `*IT`） | PR |
| 部署态：网关、证书、配置、外部集成 | **黑盒**（pytest） | 发版 |
| 视觉、流程体验、UAT | **手工 / E2E**（少量） | 提测/发版 |
| 已下线 / 重复 / 无产品确认 | **废弃** | 不执行 |

### 2.3 去重合并（条数收敛的关键）

| 手法 | 效果 |
|------|------|
| **参数化** | 同接口 10 种非法参数 → 1 个 `@ParameterizedTest` |
| **单层实现** | 同逻辑只在一层自动化，其余标「已由 xxx 覆盖」 |
| **代表用例** | 多条同场景 → 1 条代表 + 矩阵 `merged` |

> 30%～50% 条目「可下沉」白盒，合并后常为**数百个测试方法**，非千级 `@Test`。

### 2.4 白盒落盘：按契约条件选路径

| 路径 | 适用 | 产出 |
|------|------|------|
| **A 契约锚定** | 有可信 OpenAPI / 接口文档 | `*ControllerTest`：参数、401、错误码 |
| **B 表征测试** | 契约缺失/失真；即将重构 | `*IT`：固定种子 + 锁定当前行为，注释 `TC-xxxx` |
| **C 遗留 TS** | 用例量大；需对齐范围 | 矩阵 / `TS-LEGACY-*.md` |

**选择**：有契约 → A；无契约怕改坏 → B；规模大先治理 → 先 C。

---

## 3. 黑盒怎么选（收敛，不做全量）

> 筛选方法见 [blackbox-test-case-selection.marp.md](blackbox-test-case-selection.marp.md)。

<div class="funnel">

**① 全量候选** = 本迭代 AC + Epic 主路径 + 历史缺陷复现  
**② 剔除** → 白盒已细测、黑盒无部署态增量 → **不进黑盒**  
**③ 黑盒候选** → 真实 HTTP / 跨进程服务 / 真实第三方 / 用户可见 / 历史缺陷  
**④ 冒烟 5～15 条** → P0 主路径 + 横切检查（健康检查 + 各 BFF 未授权拦截），&lt; 2 min  
**⑤ 回归** → 其余黑盒候选，**按本次变更影响面选集**

</div>

| 场景 | 归属 |
|------|------|
| 参数校验全分支、401/403 分支、状态机、事务、DB 断言 | 不进黑盒（PR 白盒已覆盖） |
| 仅 Mock 第三方的超时/异常 | 不进黑盒（`*IT` + `@MockBean` 即可） |
| 真实 HTTP（网关、Filter、TLS）、跨进程串联 | 黑盒候选（部署态独有） |
| 真实第三方联调（支付沙箱、iam）、用户可见主路径 | 黑盒候选 |
| 线上曾出过缺陷的路径 | 回归必留 |

<div class="warn">

**反模式**：黑盒复刻白盒全分支断言 → CI 慢、flaky 高、维护倍增。冒烟集保持 5～15 条。

</div>

---

## 4. 落地：分工存放 + 门禁 + 路线

### 4.1 分工存放（互链，不两处抄正文）

| 内容 | 维护位置 |
|------|----------|
| 用例正文（步骤、预期、P0/P1/P2） | 测试平台（禅道） |
| 追溯矩阵（TC ↔ 方法 ↔ 层 ↔ status） | Git：`docs/qa/{迭代}/tc-traceability-*.csv` |
| Story / TS / 代码 / 自动化 | Git |
| 执行证据 | CI Pipeline + 平台手工记录 |

### 4.2 提测门禁（按矩阵 `status`）

```text
∀ TC where priority ∈ {P0,P1,P2} and status ≠ obsolete:
  automated → CI Pipeline 通过
  manual    → 测试平台执行记录
  merged    → 代表用例已执行
```

### 4.3 实施路线

| 阶段 | 动作 |
|------|------|
| **Phase 0** | 盘点 → 矩阵 → 产品确认废弃 → 定 P0 黑盒清单 |
| **Phase 1** | 集成测试基座 + Top3 链路表征测试 + P0 黑盒冒烟 |
| **Phase 2** | 触达模块补白盒；**新需求强制 Story → TS → TDD** |
| **终态** | 矩阵 legacy 行归零，STORY / TS 为测试设计主文档 |
