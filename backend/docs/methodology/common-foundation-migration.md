# 公共基础库替换：AI 任务书

> **定位**：一次性接入任务。用户提供目标公共库源码/文档/坐标后，AI 先读画像、构建文件和源码自动提取，再按本任务书完成替换；人只在四个人工介入点确认映射、契约、语义改写与验收报告。
> **前置**：`backend/MIGRATION.md` §一.2 画像已填写；本任务书只处理公共基础库及连带锚点。
> **路径**：本文按模板仓书写；接入目标项目后加 `AI-Native/` 前缀（如 `AI-Native/backend/skills/...`）。
> **不适用**：新项目继续使用模板同款公共库时，只需在画像/`AGENTS.md` 确认坐标，不需要批量替换。
> **执行方式**：接入引导读到 `MIGRATION.md` §一.3b 后，按本任务书直接执行；用户只需提供公共库源码/文档路径。

---

## 一、AI 先自己找，不要求用户一次填全

数据来源优先级：

1. `backend/architecture/system-landscape.md`：§二模块/公共库模块、§3.7 公共基础库锚点与错误码号段、§4.3.4 测试账号。
2. 目标项目构建文件：`pom.xml` / parent POM → Maven 坐标、版本属性、模块路径。
3. 公共库源码 / API 文档 / jar：`Result`、`PageQuery`、`PageResult`、`BizException`、`GlobalExceptionHandler` 的实际方法签名。
4. 用户补充：画像和代码里没有的决策值（如新号段分配、成功码选择）。

AI 不猜公共库 API；能从上述来源确定的先填，剩余项列成问题，不一次性要求用户填全部。

| 信息 | 优先来源 | 缺失时 |
|------|----------|--------|
| 公共库 Maven 坐标与版本属性 | 画像 §3.7 → `pom.xml` / parent POM | 阻断：不知道 import/依赖怎么改 |
| 包根 / 公共库模块名 | 画像 §二 / §3.7 → 源码 import | 阻断：无法替换 import |
| `Result<T>` 成功/失败 API 与成功码 | 画像 §3.7 → 公共库源码 | 阻断：无法判断 `code === ?` 和 `isSuccess()` |
| `ErrorCode` 系统码枚举、`BizErrorCode` 接口 | 公共库源码 / 文档 | 阻断：错误码/异常无法对齐 |
| `BizException` 构造器 | 公共库源码 / 文档 | 阻断：生成代码会编译失败 |
| `PageQuery` 默认值与 `PageResult` API | 公共库源码 / 文档 | 阻断：分页代码会写错 |
| ID 生成器类名/方法/是否可注入 | 画像 §3.7 → 源码 | 阻断：写路径无法生成主键 |
| 各域错误码号段 | 画像 §3.7 | 阻断：号段表、OpenAPI examples、bugfix 定位全错 |
| `GlobalExceptionHandler` 行为 | 公共库源码 / 文档 | 阻断：异常契约无法确认 |
| 测试基类、测试 JWT、Token 环境变量 | 画像 §4.3.4 → 测试源码 | 记录待补；不阻断替换，但相关 Skill 降级 |
| OpenAPI `Result` / `BusinessErrorBody` / examples | `openapi-conventions.md` + 现有 OpenAPI | 记录待补；detail-design/黑盒可能降级 |

> 用户只需提供公共库源码路径/文档/坐标；其余由 AI 从画像、构建文件和源码中提取。

---

## 二、AI 执行顺序

### 步骤 0：判定是否需要替换

| 情况 | 动作 |
|------|------|
| 目标项目仍用同一公共库 | 只填画像与 `templates/AGENTS.template.md` 占位符，跳过后面的批量替换 |
| 包根/坐标变了，API 形状不变 | 机械替换为主，语义检查为辅 |
| API 形状也变（成功码、分页、异常构造器） | 必须重写 Rule 与 Skill 示例，不能只替换字符串 |

### 步骤 1：产出映射表 → 人工介入点 1

AI 先读画像 §二/§3.7/§4.3.4、`pom.xml` / parent POM 和公共库源码，产出一张「源值 → 目标值」表。每行注明来源（画像 / 构建文件 / 源码 / 用户），无法确定的标「待确认」。**确认前不改文件。**

| 类别 | 模板旧值（搜索用） | 目标值 | 方式 |
|------|-------------------|--------|------|
| 公共库坐标 | `com.hema:common-core`、`com.hema:common-web` | | 机械 |
| 版本属性 | `${hema-common.version}` | | 机械 |
| 包根 | `com.hema.common` | | 机械 |
| 项目 common 模块 | `booking-common` | | 机械/语义 |
| 成功码 | `200` | | 语义 |
| 错误码号段 | 1500–1999 | | 语义（人确认） |
| ID 生成器 | `SnowflakeIdGenerator.nextId()` | | 语义 |
| 分页 | `PageQuery` / `PageResult.of(...)` | | 语义 |
| 异常 | `BizException` / `GlobalExceptionHandler` | | 语义 |
| 测试基类 | `AbstractIntegrationTest` / 测试 JWT | | 语义 |
| 鉴权 Token | `ADMIN_TOKEN` / `APP_TOKEN` 等 | | 语义 |

**人确认**：模块映射、成功码、号段、API 是否同形。确认后 AI 才进入步骤 2。

### 步骤 2：先写目标契约 → 人工介入点 2

先把目标 API 写进单一事实源，再改调用方：

1. `backend/rules/exception-and-result.md`：更新「Maven 依赖」「API 速查」为目标公共库；若目标库没有公司级实现，在这里定义本项目统一响应/异常契约。
2. `backend/architecture/system-landscape.md`：更新 §3.7 公共基础库锚点与错误码号段、§4.3.4 测试账号约定、模块表里的 common 模块。
3. `templates/AGENTS.template.md`：确认「统一响应」「错误码号段」指向画像 §3.7，不再另填一套值。
4. `backend/reference/exception-and-result.md`：改成目标项目说明，或明确标注「模板旧值，仅作对照」。

**人确认**：API 速查、成功码、号段、测试账号约定与目标公共库一致。确认前不批量改 Skill。

### 步骤 3：机械替换

仅替换「可执行锚点」，按长前缀优先：

1. `com.hema:common-core` / `com.hema:common-web`
2. `${hema-common.version}`
3. `com.hema.common.*`
4. `SnowflakeIdGenerator`（若类名不同）
5. `booking-common`（若模块改名）

范围：

```text
backend/skills/**        （含 templates/、references/）
backend/rules/**
backend/reference/**
backend/architecture/**
backend/glossary/**
backend/templates/**
templates/AGENTS.template.md
frontend/rules/**
frontend/architecture/**
```

**排除**：

- `frontend/MIGRATION.md` 源值清单
- `**/_golden/**`
- `backend/docs/training/**`
- `backend/docs/methodology/` 中的历史对比/方法论说明
- 明确标注「示例」「源项目」的业务样例

> 判据：**这段内容是让人照着执行，还是举例说明来源？** 前者替换，后者保留并确保标注清楚。

### 步骤 4：语义重写 → 人工介入点 3

机械替换解决不了的部分，逐项重写：

- `Result` 成功码/`isSuccess()`/`fail` 方法
- `PageQuery` 默认值、`PageResult.of` 签名
- `BizException` 构造器
- `GlobalExceptionHandler` 对校验/业务/系统异常的处理
- `SnowflakeIdGenerator` 是否同步、是否可注入
- 测试基类、测试 JWT、Token 环境变量
- OpenAPI `Result` / `BusinessErrorBody` / 失败 examples
- 错误码号段在 `system-landscape` §3.7、`AGENTS.md`、OpenAPI examples、bugfix 责任域表中的一致性

重点文件：

```text
backend/skills/detail-design/SKILL.md
backend/skills/detail-design/templates/design-template.md
backend/skills/detail-design/references/code-skeleton-guide.md
backend/skills/detail-design/references/schema-conventions.md
backend/skills/detail-design/references/openapi-conventions.md
backend/skills/feature-coding/SKILL.md
backend/skills/feature-coding/references/implementation-checklist.md
backend/skills/feature-coding/references/layer-guides.md
backend/skills/integration-test-design/references/seeding-guide.md
backend/skills/bugfix/references/impact-scope-guide.md
frontend/rules/error-display-conventions.md
```

**人确认**：API 示例、错误码、测试/鉴权约定与实际公共库一致。

### 步骤 5：验证并出报告 → 人工介入点 4

必须跑：

```bash
# 1) 可执行锚点残留（应为 0；排除 _golden）
grep -rn -E 'hema-common|com\.hema\.common|common-core|common-web|SnowflakeIdGenerator' \
  backend/skills backend/rules backend/reference backend/architecture backend/glossary backend/templates \
  | grep -v '_golden'

# 2) 旧业务/包名残留（只允许明确标注的示例）
grep -rn -E 'booking-bff|booking-common|com\.hema' backend frontend templates \
  | grep -v '_golden'

# 3) 结构门禁
bash backend/scripts/validate-skills.sh --quiet-tick
bash frontend/scripts/validate-skills.sh --quiet-tick
git diff --check
```

> 如果目标仍沿用 `com.hema` / `booking-common` 等同名值，按映射表把它们从基线剔除；残留检查只查**未被目标选用**的旧值。

业务验证：

1. `mvn test` 或最小 `@SpringBootTest` 通过。
2. 跑一张真实 Story：`detail-design → test-spec-alignment → feature-coding`，确认 import、`Result.code`、`PageQuery`、ID 生成器能编译运行。
3. 抽查一个失败 AC：OpenAPI example 的 `code` 与 `system-landscape` §3.7 号段一致。
4. 涉及权限的 AC：seed 身份列与 §4.3.4 测试账号约定一致。

报告至少包含：

- 映射表（源值 → 目标值）
- 改动文件清单
- 残留命中与豁免理由
- 验证命令输出
- 未解决阻断/待补项

**人确认**报告后才算接入完成。

---

## 三、AI 不得做的事

- ❌ 猜公共库 API、成功码、错误码号段
- ❌ 改 `_golden/`、培训课件、历史对比段里的源项目示例
- ❌ 只换包名、不检查方法签名/成功码/分页默认值
- ❌ 跳过测试基类、鉴权 Token、OpenAPI 公共组件，只改 Java 示例
- ❌ 在未确认映射/契约前批量落盘

---

## 四、最短路径

```text
用户给公共库信息
  → AI 出映射表（人确认）
  → AI 写 rules/exception-and-result + 画像 §3.7/§4.3.4 + AGENTS 占位符（人确认）
  → AI 机械替换
  → AI 语义重写（人确认）
  → AI 跑 grep + validate-skills + mvn test + 一张 Story
  → AI 出报告（人确认完成）
```
