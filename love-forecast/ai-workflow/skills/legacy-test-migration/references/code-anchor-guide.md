# 代码锚定指引（code-anchor-guide）

> 配套 [legacy-test-migration SKILL](../SKILL.md) Step 4。
> 目标：把归一化后的用例，锚定到**真实代码符号**（`coverage`），锚不到就记 `blocker`，不猜。
> 语言无关流程 + 语言适配（`adapters/{lang}.md`）。

## 1. 锚定顺序（命中即停）

```text
用例业务对象/动作
  → OpenAPI operationId / 路径
  → Controller 方法
  → Api 接口 / DTO 字段
  → 错误码枚举
  → DDL 表名 / 字段
  → Service 方法
```

- 命中前者即可填 `coverage`；全部落空 → `blocker=无法锚定`（→ `gate=G4`，BR-15）。
- 多候选（同名多接口）→ 记候选清单，标 `待人工确认`，不强行选。

## 2. `coverage` 写法

| 层 | `coverage` 示例 |
|----|-----------------|
| W1 | `SpaceQueryService#query` |
| W2 | `SpaceQueryController#query` |
| W3/W4 | `SpaceQueryIT#searchAndAllocate` |
| W5 | `SpaceMapper#selectAvailable` |
| B1/B3 | `/api/v1/love/app/spaces` |
| B5 | `SettlementJob#run` |

> `coverage` 是**占位**，最终测试方法名由下游生成 Skill 决定；本 Skill 只给锚点，不建文件。

## 3. 锚定信号提取

从用例文字提取：
- 业务名词（车位/订单/支付/结算）→ 对应 DTO / 表
- 动词（查询/预约/退款/回调）→ 对应 Controller/Service 方法
- 数值/文案（错误码、提示语）→ 对应错误码枚举 / OpenAPI

## 4. 断言一致性检查（BR-16）

锚定后比对「用例预期」与「OpenAPI/错误码/现网」：

| 结果 | 处理 |
|------|------|
| 一致 | `coverage` 正常填写 |
| 不一致 | `blocker=断言待确认（用例期望 {A}，契约/现网为 {B}）`，**不改断言/用例**，提示切 `bugfix` |
| 无法比对（缺 OpenAPI） | `blocker=缺 OpenAPI`，B1/B3 行 `coverage=—` |

## 5. 语言适配

| 语言 | adapter | 说明 |
|------|---------|------|
| Java | `adapters/java.md` | 命名/目录/Mock/DB/锚点 |
| Python | `adapters/python.md` | 同上（首版仅文档） |

- 目标语言 adapter 缺失 → `gate=G4` + `blocker=缺 {lang} adapter`（AC-10）。

## 6. 反模式（禁止）

- ❌ 锚不到就猜一个「差不多的方法名」
- ❌ 同时锚到多个接口时不标注直接选一个
- ❌ 断言不一致时自行「修正」用例预期
- ❌ 在锚定阶段创建测试文件（只填 `coverage` 占位）
