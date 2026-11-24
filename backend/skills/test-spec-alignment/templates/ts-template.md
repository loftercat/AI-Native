# TS-STORY-{迭代}-{序号}-{slug}

| 字段 | 值 |
|------|-----|
| 迭代 | {迭代} |
| 状态 | 草稿 / 评审中 / 已确认 |
| 来源 | `STORY-{迭代}-{序号}-{slug}.md` · `DD-STORY-{迭代}-{序号}-{slug}.md` §9 · OpenAPI |
| 服务/模块 | {如 booking-bff-app / booking-inventory / booking-order} |
| 复杂度 | 简单 / 中等 / 高复杂 |

> **模板说明**：由 `test-spec-alignment` Skill 在编码前根据 Story + 详设 §9 生成。删除本说明块。命名与落盘：`docs/test-spec/{迭代}/TS-STORY-{迭代}-{序号}-{slug}.md`（见 [card-naming-conventions.md](../../../docs/agile/card-naming-conventions.md)）。

## 1. 定位

一句话：本 Story 要测哪些行为、分几层、Mock 边界是什么、AC 是否都有测试计划。

## 2. AC → 用例追溯表

> 每条 AC（含成功与失败）至少一行。失败 AC 断言须写具体 `code` / `message`，与 Story/详设一致，禁止「提示错误」这类空话。

| AC | 用例（测试类#方法） | 层 | 成败 | 断言（`code` / `message` / 关键字段） | 备注 |
|----|--------------------|----|------|---------------------------------------|------|
| AC-01 | | | 成功 | | |
| AC-02 | | | 失败 | | |

## 3. 分层测试矩阵

> 对齐 `../../feature-coding/references/test-quality.md`。标注 Mock 什么 / 不 Mock 什么。

| 层 | 测试类 | 覆盖 AC / BR | Mock 什么 | 不 Mock 什么 | 备注 |
|----|--------|--------------|-----------|--------------|------|
| 单元 | `XxxServiceTest` | | 持久化层 / 下游远程客户端 / 外部 Client | 被测 Service 自身逻辑 | 无 DB |
| 入口 API | `XxxControllerTest`（`@WebMvcTest`） | | 下游远程客户端或 Service | Controller 守卫与序列化 | 无 DB |
| 持久化（按需） | `XxxMapperTest` / `XxxRepositoryTest` | | 无 | 本服务 Testcontainers MySQL + 种子 | 按画像 §5.4 P-3 ORM 选型 |
| 单服务集成 | `*IT`（`@SpringBootTest`） | | **进程外下游微服务（按 P-2 用 WireMock/Stub）** + 外部系统（支付/车场/iam） | 本服务入口 + 业务 + 真实容器 DB | 归 `integration-test-design` 消费 |
| 跨服务主链路 | 部署后黑盒用例（按需） | | 仅外部环境沙箱 | 多微服务真实联调 | 归 `api-blackbox-test`（及可选 E-5 契约测试） |

## 4. Fixture / 种子数据设计

> 给定什么输入、DB/Mapper Mock 返回什么、边界值（空串 vs `null`、等距、临界阈值等）。

| 场景 | 输入 | Mock / 种子返回 | 边界值 |
|------|------|----------------|--------|
| 主成功路径 | | | |
| 失败路径 | | | |

## 5. 前端-only / N/A 标注

> 后端不测的 AC 在此标注，避免 `feature-coding` 误写。

| AC | 标注 | 原因 |
|----|------|------|
| AC-xx | 前端-only / N/A | |

## 6. 缺口与阻断项

> 阻断项解除前不得进入 `feature-coding`。

| 类别 | 内容 | 动作 |
|------|------|------|
| AC 无测试计划 | | 补用例或标 N/A |
| 详设 §9 与 OpenAPI 错误码不一致 | | 回溯 `detail-design` |
| 失败 AC 缺断言文案 | | 补 Story |

## 7. 变更记录

| 日期 | 变更 | 作者 |
|------|------|------|
| | | |
