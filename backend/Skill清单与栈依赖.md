# Skill 清单与栈依赖

> 本表只列后端线 12 个 Skill；前端 3 个见 [frontend/README.md](../frontend/README.md)。
> 触发时机、输入/产出、栈依赖以本表为准；「栈依赖」列决定迁移到异构技术栈时需要改写的范围。

| # | Skill | 触发时机 | 用途 | 主输入 | 主产出 | 栈依赖 |
|---|-------|----------|------|--------|--------|--------|
| 1 | `journey-scenario-design` | 原始需求尚无结构化输入 | 原始需求 → 用户旅程与业务场景 | PRD 草稿 / 口头需求 / 原型 | JSD（Persona、旅程图、场景矩阵） | 通用 |
| 2 | `high-level-design` | Epic/PRD 定稿 | Epic/PRD → 概要设计 | Epic / PRD + 系统画像 | HLD（边界、集成矩阵、粗 API、ADR、建议 Story） | 通用（示例为 Java 单体） |
| 3 | `story-splitting` | HLD 完成要拆卡 | Epic/PRD/HLD → Story | Epic / PRD / HLD（+ JSD） | Story（AC/BR） | 通用 |
| 4 | `detail-design` | Story 定稿要写方案 | Story → 详细设计 | Story + 原型 | DD、OpenAPI、schema、Java 骨架 | Java / Spring / MyBatis |
| 5 | `test-spec-alignment` | DD 完成、编码前 | 编码前把 AC 拆成测试规格 | Story + DD §9 | TS（AC 追溯、分层矩阵、Fixture、阻断） | Java / JUnit |
| 6 | `feature-coding` | TS 就绪要写代码 | 按 TDD 实现功能 | Story + DD + TS | `*-api` / `*-impl` / BFF 代码 + 单元/BFF/Mapper 测试 | Java / Spring / MyBatis |
| 7 | `integration-test-design` | 跨模块/外部链路实现后 | 白盒集成/场景测试 | 已实现 Story + DD（+ TS） | `*IT` / `*ScenarioIT`（真实 HTTP，只 Mock 外部系统） | Java / Spring / Testcontainers |
| 8 | `qa-acceptance-case-design` | QA 消费 Story + OpenAPI | 面向人执行的验收用例 | Story + OpenAPI | AC-STORY（GWT，标注 execution / suite） | 通用 |
| 9 | `api-blackbox-test` | 验收用例含 blackbox 行 | 部署后 API 黑盒 | AC-STORY 的 `blackbox` 行 + OpenAPI | pytest 脚本（`tests/blackbox/`） | Python / pytest |
| 10 | `test-data-design` | blackbox 需环境造数 | 环境级造数与清理 | AC-STORY + OpenAPI | 数据画像 DP + 造数/清理脚本 | SQL / Python |
| 11 | `legacy-test-migration` | 存量用例批量改造（旁路） | 存量文字用例归一化 | 存量用例导出 | GWT + G1–G4 分类矩阵 + TS-LEGACY | 通用（Java/Python adapters） |
| 12 | `bugfix` | 线上/联调缺陷（旁路） | 缺陷七步闭环 | Bug 任务 | 复现测试（Red）+ 根因 + 最小修复 + 报告 | 通用（Hook 需按 Agent 适配） |

## 流水线位置

```text
journey-scenario-design → high-level-design → story-splitting → detail-design
        → test-spec-alignment → feature-coding → 代码审查
        → integration-test-design（研发侧）
        → qa-acceptance-case-design → api-blackbox-test / test-data-design（QA 侧）
legacy-test-migration / bugfix：按需触发，不占主链
```

## 裁剪建议

- **纯前端项目**：本线可不接入；前端线见 `../frontend/README.md`。
- **非 Java 后端**：保留 1–3、8、12；4–7 是 Variant，按目标栈改写；9–11 可保留（Python 栈反而更贴合）。
- **只做测试自动化**：保留 5、7、8、9、10、11、12；需求侧 Skill 可不装。
- **无 QA 团队**：裁掉 8–10，黑盒冒烟由 `integration-test-design` 承担；裁剪后跑 `bash scripts/validate-skills.sh` 清引用。

> 裁剪后必须重跑本线校验器；Skill 之间仍有引用，删文件不等于清引用。
