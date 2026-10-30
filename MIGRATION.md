# MIGRATION：把本模板接入你的项目

模板自已落地的源项目（Java 21 + Spring Boot 3.2 + Maven 多模块 + 双 BFF）抽取。接入 = **替换项目锚点 + 填写画像 + 按需裁剪**。判定不变式（继承自 journey-scenario-design）：**凡「追问怎么问、分几条、何时阻断」是通用层，不用改；凡出现具体文件名、系统名、路径、号段的是项目层，须替换。**

## 一、接入步骤

### 1. 填写项目画像（必做，最重要）

`backend/architecture/system-landscape.md` 是模板中唯一必须逐节填写的文件——12 个 Skill 的项目层判断（模块归属、号段路由、测试账号、外部系统 Mock 边界）全部读它。逐节按注释替换示例值，**保留被 Skill 引用的小节编号**（§3.7 错误码号段、§4.3.4 测试账号约定、§4.7 责任域定位——锚点断了 Skill 引用就漂了）。

`backend/glossary/domain-glossary.md` 按业务域重建词表（缺失时 Skill 降级运行，不阻断）。

### 2. 全局替换项目锚点

backend 的 skills/ 与 rules/ 中以下示例值需替换（均在画像或真实模块中应有对应物）：

| 类别 | 示例值（源项目） | 替换为 |
|------|------------------|--------|
| 模块名 | `booking-app`、`booking-bff-app`、`booking-bff-admin`、`booking-{order,payment,inventory,push,iot}`、`booking-common`、`booking-parking-adapter` | 目标项目模块清单（须与画像 §二 一致） |
| 包名 | `com.hema.booking.*` | 目标项目 groupId 路径 |
| 公共库 | `hema-common`（`Result`/`BizException`/`ErrorCode`） | 本项目公共库；**若无公司级公共库**，先在 `backend/rules/exception-and-result.md` 定义本项目统一响应与异常 |
| 错误码号段 | 1500-1549 order / 1550-1599 payment / 1600-1699 inventory / 1700-1799 adapter / 1800-1899 push / 1900-1999 iot | 目标项目分域号段表（画像 §3.7 + bugfix 责任域定位依赖） |
| URL 前缀 | `/api/v1/booking/app|admin/` | 目标项目前缀 |
| 迭代号 | `2026-S01`、`2026-S02`（`{年}-S{序号}`） | 目标迭代约定（`backend/config/current-sprint` 同步改） |
| 技术栈 | Java 21 / Spring Boot 3.2 / Maven / MyBatis / MySQL / Redis | 目标栈；**换栈时** `rules/java-project.md`、`mybatis-conventions.md`、`tdd-project-conventions.md`、`integration-test-conventions.md`（Testcontainers/RANDOM_PORT 决策）须重写 |
| 测试基建 | `booking-app` 下 `*IT`、Testcontainers MySQL、`mvn -pl <module> test` | 目标项目集成测试落点与命令 |

自查命令：

```bash
# 在模板根目录执行（范围含 .sh/.py，排除 _golden 样例目录）
grep -rn --include="*.md" --include="*.sh" --include="*.py" "停车预订\|parking-booking\|华智\|河玛" backend/ frontend/ | grep -v "_golden"
# 预期：无输出（golden 样例保留源项目业务名，属豁免）

grep -rn "booking\|hema\|2026-S" backend/skills/ backend/rules/
# 预期：输出应全部是上表已声明的示例值；出现表外形态才需处理。
# 注意 "schema" 含 "hema" 子串属误报，可加 grep -v schema 排除。
```

### 3. 重写 Golden（不是拷贝 Golden）

`docs/**/_golden/` 下 12 个样例全部是源项目业务（query-allocate-space 一族）。**接入后按源项目同族场景（查询-分配类用例）用本项目真实业务重写一遍**——Golden 的价值是「标准长什么样」，不是「别人的业务长什么样」。重写时保持文件名模式与结构。

### 4. 分发到 Agent

- Cursor：对应线 `skills/` → `.cursor/skills/`，`rules/*.md` → `.cursor/rules/*.mdc`（加回 frontmatter：description + globs/alwaysApply）
- Claude Code / 其他 Agent：放到对应技能/规则目录
- **不要用 symlink 做多 Agent 镜像**：Windows 无特权检出时 symlink 物化成路径文本文件，镜像静默失效（源项目实测教训）。多 Agent 用 CI 拷贝同步。
- hooks 按 [backend/hooks/README.md](backend/hooks/README.md) 注册，先改 `PROTECTED` 保护路径。

### 5. 裁剪（按需）

- **无 QA 团队**：可去掉 QA 专线 4 个 skill（qa-acceptance-case-design / api-blackbox-test / test-data-design / legacy-test-migration 的黑盒部分）——黑盒冒烟由集成测试取代（见 [backend/docs/methodology/test-line.md](backend/docs/methodology/test-line.md) §4.2）。
- **无独立前端仓**：忽略前端协作章节。
- **存量项目无历史用例**：去掉 legacy-test-migration。
- 裁剪后跑对应线 `bash scripts/validate-skills.sh`，清掉对被裁 skill 的引用。

## 二、与源项目的差异（刻意为之）

| 差异 | 原因 |
|------|------|
| 无 `.cursor/.claude` symlink 镜像 | Windows 检出下 symlink 失效（实测），改为 CI 拷贝建议 |
| `validate-skills.sh` 链接 FAIL / tick WARN 分级 | 源版因字符集 bug 所有带扩展名引用静默跳过；模板版明确化：显式链接缺失才 FAIL，tick 提及降 WARN |
| rules 从 `.mdc` 改为纯 `.md` | 去除 Cursor frontmatter 依赖，跨 Agent 中立；Cursor 接入时加回 |
| `.cursor/current-sprint` → `backend/config/current-sprint` | 同上，路径中立 |
| 根级 `AI-NATIVE-*.md` 治理文档未随附 | 那是源项目的迁移历史记录；通用思想已并入各线 `docs/methodology/` 与本文件 |
| `docs/reference/hema-common-api.md` 未随附 | 公司级公共库专属速查；等价物 = `backend/rules/exception-and-result.md` |
| 前端线无 symlink 镜像、无 hooks | 源项目前端仓未铺 hooks；机制可复用 backend 的（改 PROTECTED 路径为前端公共组件目录） |
| 新增 Story 审查最小闭环（源项目没有） | 为治理纪律滑坡（源项目 TS 采用率仅约 7% 的教训）：拆卡后独立审查、报告落 `backend/docs/reviews/`、状态「已确认」由校验器强制对应报告。刻意只做单点门禁，未引入四门/轮次上限/成本度量 |
| 前端线未含 e2e / frontend-test-spec-alignment | 源项目此两项尚在规划测试中（设计师自述未闭环）；定型后可补抽 |

## 三、前端线接入（frontend/，可选）

只用后端线可跳过本节。前端线自源项目 C 端小程序仓抽取，接入步骤：

1. **画像**：填 `frontend/architecture/system-landscape.md`——重点 §四（契约文件/鉴权/错误码对齐）与 §六（与后端流水线的协作机制）；词表 `frontend/glossary/` 与后端仓对齐。
2. **handoff 包**：从后端团队拿 OpenAPI 快照 + 版本 pin，放入 `frontend/docs/handoff/openapi/{后端服务标识}.yaml` 与 `VERSION`（机制见 `frontend/docs/handoff/README.md`）。**前端永远不直接改契约**。
3. **替换前端锚点**（示例值 → 本项目）：

| 类别 | 示例值 | 替换为 |
|------|--------|--------|
| 契约文件 | `docs/handoff/openapi/booking-bff-app.yaml` | 你的后端服务契约快照 |
| 技术栈 | 微信小程序原生（`wx.*`、`pages/`、分包） | 你的前端框架（Vue/React/uni-app 等；`rules/miniprogram-*` 两条按栈重写或裁剪） |
| 页面/组件名 | `pages/destination-search/` 等 | 本项目页面结构（画像 §3.2） |
| 迭代号 | `2026-S01/S02` | 与后端线一致的迭代约定（`frontend/config/current-sprint`） |

自查：`grep -rn "booking\|hema\|2026-S" frontend/skills/ frontend/rules/`，预期全部为上表已声明示例。

4. **Golden 重写**：`frontend/docs/**/_golden/` 的 STORY-FE / DD-FE 样例（destination-search-allocate 一族）用本项目真实页面需求重写。

## 四、接入后验收

1. 两个校验器均 **PASSED**：`bash backend/scripts/validate-skills.sh`、`bash frontend/scripts/validate-skills.sh`（WARN 逐条确认是「提及目标项目文件」而非真断链）。
2. 后端线挑一个真实小需求走通：journey-scenario-design（或直接 story-splitting）→ detail-design → feature-coding，产出路径与命名符合 `backend/docs/agile/card-naming-conventions.md`。
3. 前端线拿到一次真实 handoff 包走通：frontend-story-splitting → frontend-detail-design → frontend-feature-coding。
4. 后端画像 §4.3.4 测试账号表填写后，test-data-design 造一次数验证对齐规则可执行。
