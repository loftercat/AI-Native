# Skill 清单与栈依赖

> 本表只列后端线 13 个 Skill；前端 3 个见 [frontend/README.md](../frontend/README.md)。
> 「栈依赖」列决定迁移到异构技术栈时需要改写的范围。

## 快速导航

| 我想… | 看 |
|--------|----|
| 查主线 7 环 | [主线 7 环](#主线-7-环) |
| 查 QA 专线 | [QA 专线](#qa-专线) |
| 查交接（前端 handoff） | [交接](#交接) |
| 查旁路 | [旁路](#旁路) |
| 看流水线位置 | [流水线位置](#流水线位置) |
| 看裁剪建议 | [裁剪建议](#裁剪建议) |

---

## 主线 7 环

新需求、改需求的主路径。

| # | Skill | 触发时机 | 用途 | 主输入 | 主产出 | 栈依赖 |
|---|-------|----------|------|--------|--------|--------|
| 1 | `journey-scenario-design` | 原始需求尚无结构化输入 | 原始需求 → 用户旅程与业务场景 | PRD 草稿 / 口头需求 / 原型 | JSD（Persona、旅程图、场景矩阵） | 通用 |
| 2 | `high-level-design` | Epic/PRD 定稿 | Epic/PRD → 概要设计 | Epic / PRD + 系统画像（含 §5.4 选型） | HLD（微服务边界、通信矩阵、数据归属、粗契约、ADR、建议 Story） | 通用（示例为 Java 微服务） |
| 3 | `story-splitting` | HLD 完成要拆卡 | Epic/PRD/HLD → Story | Epic / PRD / HLD（+ JSD） | Story（AC/BR + 跨服务依赖波次） | 通用 |
| 4 | `detail-design` | Story 定稿要写方案 | Story → 详细设计 | Story + 原型 + 画像 §5.4 | DD、对外/对内接口契约、schema/DDL、代码骨架、测试策略 | Java / Spring（ORM 与调用协议读画像 §5.4） |
| 5 | `test-spec-alignment` | DD 完成、编码前 | 编码前把 AC 拆成测试规格 | Story + DD §9 | TS（AC 追溯、分层矩阵、Fixture、阻断） | Java / JUnit |
| 6 | `feature-coding` | TS 就绪要写代码 | 按 TDD 实现单服务功能 | Story + DD + TS | 目标服务 `*-api` / `*-impl` / BFF 代码 + 单元/入口 API/持久化单测 | Java / Spring（ORM 与调用协议读画像 §5.4） |
| 7 | `integration-test-design` | 单服务功能实现后 | 单服务白盒集成/场景测试 | 已实现 Story + DD（+ TS） | 本服务 `*IT` / `*ScenarioIT`（独立容器 DB，下游微服务与外部系统模拟隔离） | Java / Spring / Testcontainers / WireMock |

---

## QA 专线

提测、发版验收时使用。无 QA 团队可裁验收用例与造数；微服务下建议保留 `api-blackbox-test`。

| # | Skill | 触发时机 | 用途 | 主输入 | 主产出 | 栈依赖 |
|---|-------|----------|------|--------|--------|--------|
| 8 | `qa-acceptance-case-design` | QA 消费 Story + OpenAPI | 面向人执行的验收用例 | Story + OpenAPI | AC-STORY（GWT，标注 execution / suite） | 通用 |
| 9 | `api-blackbox-test` | 验收用例含 blackbox 行 | 部署后 API 黑盒 | AC-STORY 的 `blackbox` 行 + OpenAPI | pytest 脚本（`tests/blackbox/`） | Python / pytest |
| 10 | `test-data-design` | blackbox 需环境造数 | 环境级造数与清理 | AC-STORY + OpenAPI | 数据画像 DP + 造数/清理脚本 | SQL / Python |

---

## 交接

前后端分离时使用；同仓全栈或纯后端项目可整体裁掉。

| # | Skill | 触发时机 | 用途 | 主输入 | 主产出 | 栈依赖 |
|---|-------|----------|------|--------|--------|--------|
| 13 | `api-handoff` | 前端要开工 / operation 语义变更后 | OpenAPI 契约 → 前端 handoff 包 | `docs/api/{服务}/openapi.yaml` + 版本标签 | `docs/handoff/` 三件套（快照 + VERSION + 索引） | 通用（bash + Python） |

---

## 旁路

按需触发，不占主链。

| # | Skill | 触发时机 | 用途 | 主输入 | 主产出 | 栈依赖 |
|---|-------|----------|------|--------|--------|--------|
| 11 | `legacy-test-migration` | 存量用例批量改造 | 存量文字用例归一化 | 存量用例导出 | GWT + G1–G4 分类矩阵 + TS-LEGACY | 通用（Java/Python adapters） |
| 12 | `bugfix` | 线上/联调缺陷 | 缺陷七步闭环 | Bug 任务 | 复现测试（Red）+ 根因 + 最小修复 + 报告 | 通用（Hook 需按 Agent 适配） |

---

## 流水线位置

```text
主线
  journey-scenario-design → high-level-design → story-splitting → detail-design
  → test-spec-alignment → feature-coding → 代码审查
  → integration-test-design（研发侧）

QA 专线
  qa-acceptance-case-design → api-blackbox-test / test-data-design

交接（前后端分离时）
  api-handoff → frontend-story-splitting → frontend-detail-design → frontend-feature-coding

旁路
  legacy-test-migration / bugfix
```

---

## 裁剪建议

| 场景 | 保留 | 裁剪 / 改写 |
|------|------|-------------|
| 纯前端项目 | 本线可不接入 | 全部；前端线见 `../frontend/README.md` |
| 非 Java 后端 | 1–3、8、12、13 | 4–7 是 Variant，按目标栈改写；9–11 可保留（Python 栈反而更贴合） |
| 只做测试自动化 | 5、7、8、9、10、11、12 | 需求侧 Skill 可不装 |
| 纯后端、无前端线 | 1–12 | 13（交接）可裁掉 |
| 无 QA 团队 | 1–7、9、12 | 可裁 8、10；**微服务下建议保留 9（`api-blackbox-test`）用于部署后跨服务主链路验证** |

> 裁剪后必须重跑本线校验器；Skill 之间仍有引用，删文件不等于清引用。
