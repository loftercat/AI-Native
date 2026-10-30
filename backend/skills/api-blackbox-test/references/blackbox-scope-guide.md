# 黑盒范围指引（去重 · 边缘归属 · manifest 规模）

> **解决什么问题**：明确「哪些场景该写黑盒 pytest、哪些不该」，避免与 Java IT 重复（BR-03），
> 避免把边缘分支全量搬进黑盒（BR-06），收敛冒烟规模（BR-05）。

## 1. 与 integration-test-design 对比表

> **解决什么问题**：防止「同一场景 IT 和黑盒各写一份细断言」导致维护双倍。明确二者分工边界。

| 维度 | integration-test-design（`*IT`） | api-blackbox-test（pytest） |
|------|-------------------------------|-----------------------------|
| 语言 | Java | Python |
| 运行环境 | 进程内（`@SpringBootTest RANDOM_PORT`） | 部署后（已部署测试环境） |
| 时机 | MR 每次 PR（`mvn test`） | 发版后/提测后（独立 deploy stage） |
| Mock | 外部系统 `@MockBean`/WireMock | 环境级沙箱（测试支付、测试 iam） |
| 断言粒度 | DB + 错误码 + 状态机细断言 | HTTP 200 + `result.code==200` + 关键字段 |
| 覆盖目标 | PR 逻辑正确性 | 部署态可用性（网关/Filter/iam/配置） |
| 同场景 | **优先 IT**；IT 已覆盖 → pytest 不复制 | 仅域级 1 条主路径冒烟 |
| `ci_covered` 行 | 090 已判定 TS 全覆盖 **且** 无部署态独有（BR-05 双条件） | **不生成 pytest**；Then 以 MR `mvn test` 通过为准 |
| `manual`/`frontend_only`/`obsolete` 行 | 非黑盒 | **不生成 pytest**（归 090 GWT / 前端仓） |

## 2. 冒烟 vs 回归

> **解决什么问题**：防止「每次发版全量跑」导致发版阻塞。冒烟小而快，回归按影响面选集。

| 选集 | 规模 | 构成 | 时机 |
|------|------|------|------|
| `smoke` | 5~15 条 | 各域 1 主路径 + 横切 health/auth_probe | 提测/发版优先跑 |
| `regression` | 按影响面选集 | 其余 blackbox 候选 | 发版后/定时 |

**冒烟横切探测**（迭代级共享，不重复为每个 Story 新增）：

- **health**：`GET /actuator/health` → 200
- **auth_probe Admin**：未授权 `GET /api/v1/booking/admin/...` → 401/403
- **auth_probe App**：未授权 `GET /api/v1/booking/app/...` → 401/403

## 3. 边缘场景归属（BR-06）

> **解决什么问题**：防止「参数非法全组合、业务错误码全表」被搬进黑盒导致用例爆炸。明确默认归属 IT，例外才进黑盒。

| 场景 | 默认归属 | 例外进黑盒条件 |
|------|----------|----------------|
| 参数非法全组合 | IT / `*ServiceTest`（PR 白盒） | — |
| 业务错误码全表 | IT / `*ServiceTest`（PR 白盒） | — |
| 真实网关/Filter 链路 | — | **必进黑盒**（IT 不经真实 Filter） |
| 真实 iam 鉴权 | — | **必进黑盒**（IT 用 Mock） |
| 真实支付沙箱联调 | — | **进回归 manifest**（注理由） |
| 历史缺陷路径 | — | **进回归 manifest**（注理由） |

**判定原则**：仅当「环境/网关/真实 iam 特有」**且**「IT 无法覆盖」时，方进黑盒 manifest。

## 4. manifest 规模原则

> **解决什么问题**：防止 manifest 无限膨胀。冒烟小而快，回归按影响面，边缘默认不进。

- smoke ≤ 15 条（各域 1 主路径 + 横切 3 条；单条 <2 min）
- regression 按本次变更影响面选集（非每次全量）
- 边缘场景默认不进；例外注 `rationale` 字段

## 5. 断言粗粒度（BR-04）

> **解决什么问题**：防止黑盒 pytest 复制 IT 的 DB 细断言导致维护双倍。黑盒只验「部署态能通 + 用户可见结果」。

- **必断**：HTTP status 200、`result.code == 200`、少量关键字段存在性
- **不禁**：Mapper 内部状态、Mock 调用次数、DB 行数、单字段精确值
- 失败输出含 **URL + HTTP status + result.code**（BR-07）

## 6. 环境敏感点

> **解决什么问题**：防止「测试环境偶发漂移」被当成代码缺陷。明确缺配置时 skip 而非 fail，auth_probe 失败先查配置。

- `BLACKBOX_BASE_URL` 缺失 → `pytest.skip`（非 fail，AC-07）
- `ADMIN_TOKEN` / `APP_TOKEN` 缺失 → auth_probe 用例 skip；主路径用例标 xfail 或 skip
- 测试支付沙箱不可用 → 支付类回归 skip + 汇总提示
- Token/iam 漂移 → auth_probe 失败优先查配置而非改断言
