# Python 适配层（adapters/python.md）

> 配套 [legacy-test-migration SKILL](../../SKILL.md)。
> 核心分类标准与语言无关；本文件提供 Python 生态的锚定与落点映射。**首版仅文档**（当前仓库为 Java，Python 侧待目标项目验证，开放问题 #2）。
> 目标项目：Python 生态（FastAPI / pytest）。

## 1. 层 → 测试形态

| layer | 测试文件命名 | 目录 | 说明 |
|-------|-------------|------|------|
| W1 | `test_{unit}.py` | `tests/unit/` | pytest，纯函数/类，无外部依赖 |
| W2 | `test_{router}.py` | `tests/api/` | `fastapi.testclient.TestClient` |
| W3 | `test_{module}_it.py` | `tests/integration/` | 真实 DB（Testcontainers），事务回滚 fixture |
| W4 | `test_{scenario}.py` | `tests/integration/` | 多步骤业务链路 |
| W5 | `test_{model}_repo.py` | `tests/unit/repo/` 或 `tests/integration/` | 持久层切片（SQL/ORM） |
| W6 | 前端组件（另仓） | 前端仓 | Vitest/Jest |
| B1 | `test_{api}_blackbox.py` | `tests/blackbox/` | `httpx` + `@pytest.mark.blackbox`，打部署态 |
| B3 | `test_{vendor}_sandbox.py` | `tests/blackbox/` | 真实第三方沙箱 |
| B5 | `test_{job}.py` + seed | `tests/integration/` + `tests/data/` | 批处理/定时 |

## 2. Mock / DB 约定

| 场景 | 方案 |
|------|------|
| 依赖覆写 | `app.dependency_overrides` |
| 外部调用 | `pytest-mock`（`mocker.patch`）/ `monkeypatch` |
| W3/W4 DB | Testcontainers + fixture（事务回滚）/ 独立 schema |
| 黑盒 | `httpx`/`requests`，`@pytest.mark.blackbox` |

## 3. 锚定信号（Step 4）

| 用例线索 | Python 锚点 |
|----------|-------------|
| 接口路径 | `APIRouter` 路由函数（`@router.get("/spaces")`） |
| operationId | 路由函数名 |
| 请求/响应字段 | Pydantic model 字段 |
| 错误码/文案 | 错误码常量 / `HTTPException.detail` |
| 表 / 字段 | ORM model（SQLAlchemy）/ migration |
| 业务动作 | service 函数 / use-case |

## 4. 与 Java 的核心差异

| 维度 | Java | Python |
|------|------|--------|
| 测试框架 | JUnit5 + Mockito | pytest + pytest-mock |
| 分层切片 | `@WebMvcTest`/`@MybatisTest` | TestClient / repo fixture |
| 事务隔离 | `@Sql`/`@Transactional` | fixture yield 回滚 |
| 黑盒标记 | pytest（同） | `@pytest.mark.blackbox` |

> 差异**只在此文件**；分类标准、门禁、矩阵字段、路由跨语言一致。
