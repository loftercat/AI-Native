# 修复报告模板（fix-report-template）

> bugfix Skill Step 7 使用。
> 设计依据：DD-STORY-2026-S01-093（源项目 bugfix Skill 设计卡） §6、ADR-4

## 模板

```markdown
## 修复报告 — {Bug 编号/标题}

| 字段 | 值 |
|------|-----|
| Bug | {bugId / 标题} |
| 根因 | {一句话} |
| 修复 | {一句话} |
| 改动文件 | {清单} |
| 复现测试 | {测试方法名}（RED→GREEN） |
| 影响范围 | {Step 5"影响范围"摘要} |
| 验证 | {Step 6 测试命令与结果} |
| 未覆盖风险 | {Step 5"未覆盖风险"，无则"无"} |
| 建议跟进 | {是否需补测试/补 OpenAPI/补文档} |
| 循环轮次 | {Step 6 实际循环轮次} |
```

## 落盘规则

| 场景 | 落盘 | 路径 |
|------|------|------|
| 日常修 bug | 否，仅对话输出 | — |
| 试点 | 是 | `docs/qa/{迭代}/FIX-{迭代}-{序号}-{slug}.md` |
| 线上 bug | 是 | 同上 |
| 公共代码 bug（人确认后修） | 是 | 同上 |

## 命名规范

- 复现测试：`test_bugfix_{bugId}_{现象}`
- 修复报告：`FIX-{迭代}-{序号}-{slug}.md`（与 AC/DP 同目录 `docs/qa/{迭代}/`）

## 示例

```markdown
## 修复报告 — BUG-2026-001 车位搜索返回空

| 字段 | 值 |
|------|-----|
| Bug | BUG-2026-001 车位搜索返回空 |
| 根因 | ParkingLotQueryService.searchByKeyword 未过滤 status=ENABLED，DISABLED 车场也被返回导致前端过滤后空 |
| 修复 | 在 searchByKeyword 的 SQL where 加 status = 'ENABLED' |
| 改动文件 | inventory-impl/.../ParkingLotQueryService.java:45 |
| 复现测试 | test_bugfix_bug_2026_001_search_return_empty（RED→GREEN） |
| 影响范围 | 直接影响：App 车位搜索接口；间接影响：预约流程首步；已有测试覆盖：ParkingLotQueryServiceTest 5 条；未覆盖风险：无 |
| 验证 | mvn -pl booking-inventory-service/inventory-impl -am test → 通过（12 条） |
| 未覆盖风险 | 无 |
| 建议跟进 | 无 |
| 循环轮次 | 1 |
```
