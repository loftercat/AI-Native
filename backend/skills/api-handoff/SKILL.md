---
name: api-handoff
description: >-
  把后端已定稿的 OpenAPI 契约打包发布为前端可离线消费的 handoff 包：
  契约快照 + VERSION 版本 pin + Story↔operationId 索引，并校验三件套一致性。
  用于前端开工前交付契约、契约变更后重新发布、前后端联调对不上版本、
  「发一版接口给前端」「handoff 包」「契约同步给前端」等场景。
  只发布不改契约——契约定义归 detail-design。
---

> **模板版说明**：本 Skill 自源项目抽取为通用模板。文中服务标识 `booking-bff-app`、路径、Story 号均为**示例**，接入项目时按 [MIGRATION.md](../../MIGRATION.md) 替换；「本仓库」指接入后的目标项目。

# API handoff 发布（OpenAPI → 前端交接包）

把后端**已定稿**的 OpenAPI 冻结成一份快照包，让前端在没有后端仓库访问权的情况下，
按一个确定版本开发。本质是「以文件为界，而不是以仓库为界」。

## 定位与边界

- **做什么**：契约预检 → 整文件复制快照 → 生成 Story↔operationId 索引 → 写 VERSION → 跑一致性校验
- **不做**：定义或修改契约（归 `detail-design`）；改前端代码；替前端拆卡
- **不做**：增量包（每次都是全量快照 + 全量索引，增量会让前端拼多文件才能理解契约）
- **不做**：打 tag / push（版本标签由用户提供；需要打 tag 时提示用户手动执行）

## 何时触发

- **前端要开工**：契约已定稿，需要交付 handoff 包
- **契约变更后**：`openapi.yaml` 的 operation 语义变了（新增端点/改字段/改错误码）→ 必须重新发布
- **联调对不上版本**：前后端对同一接口行为不一致，先核对双方 VERSION
- **不触发**：单张卡 DD 刚写完、契约还在改；前端是纯 UI 卡且不调接口

## 前置加载（按序点名）

| # | 资产 | 路径 | 缺失时 |
|---|------|------|--------|
| 1 | 契约 | `docs/api/{服务标识}/openapi.yaml` | **阻断** |
| 2 | 系统画像（服务标识、前端线位置） | `architecture/system-landscape.md` | **阻断**（不知道目标目录） |
| 3 | handoff 目录约定 | `{前端线根}/docs/handoff/README.md` | 降级（用本 Skill §产出 约定） |
| 4 | 版本标签 | 用户提供，或由步骤 5 从 git 推导 | **阻断**（契约有未提交改动 / git 不可用且未显式提供） |

## 输入

- **必备**：服务标识（如 `booking-bff-app`、`love-app`）
- **可选**：目标目录（默认从前端线根解析：`<项目根>/AI-Native/frontend/docs/handoff`）
- **可选**：版本标签（不提供时由步骤 5 从 git 推导；`TBD` 或推导失败时阻断）

### 触发示例

```text
/api-handoff 把 love-app 的契约发一版给前端，tag 用 2026-S01-rc1
前端说建议接口对不上，重新发个 handoff
/api-handoff booking-bff-app --target ../frontend/docs/handoff
```

---

## 流程

### 步骤 1：定位目标目录（阻断）

1. 读画像，确认前端线根；未配置则问用户要 `--target`
2. 目录不存在 → **阻断**，给出两个选项：
   - 建目录（按 §产出 的三件套约定初始化）
   - 显式指定跨仓路径（`--target`；提示：跨仓写入后需在前端仓自行提交）
3. 非标准布局（前端独立仓库、多前端线）用环境变量 `HANDOFF_DIR` 固定目录；
   **自检时必须指向同一目录**，否则门禁会按「未发布」跳过
4. 前端线根与后端仓不在同一 git 仓库时，**只写文件不提交**，并在报告里注明「跨仓，需前端仓提交」

### 步骤 2：契约预检（阻断）

逐项检查，任一失败即停，不要生成半成品包：

| 检查 | 判定 |
|------|------|
| 文件存在且 YAML 可解析 | `python -c "yaml.safe_load(...)"` 或等价 |
| 每个 operation 有 `operationId` 且**全局唯一** | 缺失/重复 → 阻断，提示回 `detail-design` 补 |
| 每个 operation 有 `x-stories` | 缺失 → 阻断（索引无法生成） |
| `info.description` 含全局约定 | 至少覆盖 Result 语义、对外 ID、幂等、额度、错误码分段；缺任一项 → 阻断 |

> 契约缺元数据时**不要**在本 Skill 里补写契约——那属于 `detail-design`。阻断并给出要补的清单。

### 步骤 3：生成快照

```bash
mkdir -p {target}/openapi
cp docs/api/{服务标识}/openapi.yaml {target}/openapi/{服务标识}.yaml
```

整文件复制，**不改任何内容**（换行符差异由门禁忽略，字段/描述一律不改）。

### 步骤 4：生成索引

```bash
# 单服务
bash scripts/gen-stories-index.sh {target}/stories-index.md {target}/openapi/{服务标识}.yaml
# 多服务一次生成（不要逐个生成再拼接——生成器整文件重写，后一个会清掉前一个）
bash scripts/gen-stories-index.sh {target}/stories-index.md {target}/openapi/*.yaml
```

脚本从 `x-stories` 反查，按服务分节、服务内按 Story 分组，输出：

```markdown
# Story ↔ operationId 索引

> 由 `scripts/gen-stories-index.sh` 从 OpenAPI 的 `x-stories` 自动生成，不要手工编辑。

## love-app

### STORY-2026-S01-011
| operationId | Method | Path | 说明 |
|---|---|---|---|
| listObservations | GET | /api/v1/love/app/profiles/{id}/observations | 查看观察集 |
| correctObservation | PATCH | /api/v1/love/app/profiles/{id}/observations/{oid} | 用户修正 |
```

> 契约里出现脚本不支持的 HTTP 方法、或 `x-stories` 缺失，脚本会非 0 退出并列出具体 operation——不要绕过，回 `detail-design` 补契约。

### 步骤 5：写 VERSION（版本来源必须可复现）

先确定版本标签。三条硬规则：

1. **契约有未提交改动 → 阻断**。`git status --porcelain docs/api/{服务标识}/` 非空时，
   VERSION 指向的 commit 里没有这份契约——前端按 SHA 找不到对应代码。
   先提交或打 tag 再发；不要用「反正是本地文件」绕过。
2. **git 不可用（不在仓 / 未 init / 没装 git）→ 阻断**，要求用户显式提供版本标签。
   没有可追溯的锚点，VERSION 就是一句空话。
3. **无 tag 时用短 SHA，并标注「未打 tag」**：`love-app @ 633c09a（未打 tag）`。
   让前端知道这是临时版本，不是正式发布；同时提醒后续补 tag。

```text
{服务标识} @ {tag 或 commit SHA 前 7 位}[（未打 tag）]
播种：{YYYY-MM-DD}
变更：{本版相对上一版的摘要；首次发布写「首版」}
```

多服务时**每个服务一行**，播种与变更可共用一段。

变更摘要的取法：与目标目录里的**旧快照**做 operation 级 diff（按 operationId 比对），
列出「新增 / 删除 / 变更」的 operationId；无旧快照则写「首版」。
**不要**写「详见 git log」——前端不读后端仓。

### 步骤 6：校验（阻断）

```bash
bash scripts/validate-skills.sh
# 非标准布局（跨仓/多前端线）：HANDOFF_DIR=/path/to/handoff bash scripts/validate-skills.sh
```

第 5 段会检查三件套：存在性、快照逐字节一致、VERSION 非 TBD、索引覆盖全部 operationId。
失败 → 报告具体项并停；不要「先发布再修」。

---

## 产出

```text
{前端线根}/docs/handoff/
├── openapi/{服务标识}.yaml   # 契约快照（整文件，未改）
├── VERSION                   # 版本 pin + 播种日期 + 变更摘要
└── stories-index.md          # Story ↔ operationId（脚本生成）
```

多服务时 `openapi/` 下多个 yaml，`VERSION` 为每个服务各写一行（门禁按服务名逐行校验），
`stories-index.md` 按服务分节（`## {服务}` → `### {Story}`）。

**多前端线**（App + Admin 各自消费不同服务）：每个前端线一个 handoff 目录，逐条发布——
生成器一次可传多个 yaml，但目标目录与 `HANDOFF_DIR` 是单值；门禁也只校验一个目录。

## 自检清单

- [ ] 快照与 `docs/api/{服务标识}/openapi.yaml` **内容一致**（门禁忽略换行符差异，其余任何改动都会 FAIL）
- [ ] VERSION 指向的 commit 里**确实包含**当前契约（发布时无未提交改动）
- [ ] 无 tag 时 VERSION 已标注「未打 tag」
- [ ] `VERSION` 非 TBD，含 tag/SHA + 播种日期 + 变更摘要
- [ ] `stories-index.md` 覆盖 openapi 里**全部** operationId（不是只列主流程）
- [ ] 目标目录缺失时已阻断并让用户选择，没有静默跳过
- [ ] 前端只看 `docs/handoff/` 就能开工——不需要问后端要任何东西

## 反模式

| 反模式 | 后果 |
|--------|------|
| 只发 `openapi.yaml` | 前端不知道对着哪版写，联调必踩「代码都对、接口不通」 |
| 把 `docs/api/` 整个目录拷过去 | 其中含非本前端用的服务；handoff 只放本前端消费的服务 |
| 在前端目录里改快照 | 快照失真；契约变更只能从后端重新发布 |
| 契约没定稿就发 | 前端按半成品开发，返工成本高于等待 |
| 后端改了契约不重发 | 前端快照过期且无人发现——靠 `validate-skills.sh` 第 5 段兜底 |
| 在本 Skill 里补 operationId / x-stories | 越界改了契约；应回 `detail-design` |

## 与相邻 Skill 的关系

| Skill | 关系 |
|-------|------|
| `detail-design` | 上游：定义契约（含 `operationId` + `x-stories`）；契约变更后通知重发 |
| `feature-coding` | 下游：按契约实现；不得改非当前 Story 的 operation 语义 |
| `frontend-story-splitting` | 消费方：handoff 是**阻断输入**（纯 UI 卡豁免） |
| `frontend-detail-design` / `frontend-feature-coding` | 消费方：同样以快照为准 |
