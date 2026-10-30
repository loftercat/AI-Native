# blackbox pytest 衔接指引

> 配套 `test-data-design` Skill。明确 `api-blackbox-test` 如何经环境变量读 DP 约定，不在 pytest 内嵌 SQL。

## 1. 环境变量约定

> Token 变量清单的**真源**是 [system-landscape §4.3.4 测试账号约定表](../../../architecture/system-landscape.md#434-测试账号约定供-test-data-design-skill-消费)；本表为运维/CI 快速参考，新增/变更 Token 先改 §4.3.4，再同步本表。

| 变量 | 用途 | 缺失行为 | 来源 |
| `SEED_DB_URL` | seed 脚本执行环境 | skip（非 fail） | 运维/CI |
| `BLACKBOX_BASE_URL` | blackbox pytest base URL | skip（091 AC-07） | 运维/CI |
| `BLACKBOX_SEARCH_KEYWORD` | pytest 读画像约定关键词 | 默认 `万象城` | DP `env_vars` |
| `BLACKBOX_DATA_PROFILE` | pytest 标记当前画像 | 默认 `smoke-main` | DP `env_vars` |
| `APP_TOKEN` | C 端车主 Token（默认） | App 用例 skip | 运维/CI |
| `ADMIN_TOKEN` | B 端运营 Token（默认，如 platform 超管） | Admin 用例 skip | 运维/CI |
| `ADMIN_TOKEN_PARTNER` | B 端合作方 scope 账号 | 该 scope 用例 skip | 运维/CI |
| `ADMIN_TOKEN_LOT` | B 端车场 scope 账号 | 该 scope 用例 skip | 运维/CI |
| `ADMIN_TOKEN_DENIED` | B 端无权限码账号（验 403） | 403 用例 skip | 运维/CI |
| `APP_TOKEN_OWNER_B` | C 端另一车主（验非本人不可见） | 该用例 skip | 运维/CI |

> 多 Token 约定：黑盒按 AC 挑对应 Token 环境变量；具体变量名与角色/场景的对应见 [system-landscape §4.3.4 测试账号约定表](../../../architecture/system-landscape.md#434-测试账号约定供-test-data-design-skill-消费)。Token **不进** Git（由运维/CI 注入环境变量）。详见 [identity-and-permission-guide.md](identity-and-permission-guide.md)。

## 2. 执行顺序（CI deploy stage 建议）

```text
1. seed stage:
   python -m tests.data.seed_s02_007_space_query --profile smoke-main > seed.sql
   mysql -h $SEED_DB_HOST ... < seed.sql

2. blackbox stage:
   export BLACKBOX_SEARCH_KEYWORD=万象城
   export BLACKBOX_DATA_PROFILE=smoke-main
   pytest tests/blackbox/ -m smoke

3. cleanup stage（可选）:
   python -m tests.data.seed_s02_007_space_query --profile smoke-main --cleanup > cleanup.sql
   mysql -h $SEED_DB_HOST ... < cleanup.sql
```

## 3. pytest 如何读环境变量

`api-blackbox-test` 的 pytest **不嵌 SQL**，通过 `os.environ` 读 DP 约定：

```python
# tests/blackbox/test_smoke_2026_s02_007_space_query.py（建议演进）
import os
KEYWORD = os.environ.get("BLACKBOX_SEARCH_KEYWORD", "万象城")
PROFILE = os.environ.get("BLACKBOX_DATA_PROFILE", "smoke-main")

def test_search_lots_smoke(http_client, app_token):
    resp = http_client.post("/api/v1/booking/app/lots/search",
                            json={"keyword": KEYWORD}, ...)
```

> 当前 S02-007 黑盒脚本硬编码 `万象城`；后续可改为读环境变量，与 DP 联动（属 091 增量，非本卡）。

## 4. 边界

- **DP 是数据契约**：定义「环境里该有什么数据」
- **seed 脚本是执行器**：生成 SQL，由运维/CI 执行
- **pytest 是消费者**：经环境变量读约定，不直连 DB，不嵌 SQL
- **三者解耦**：DP 变更不强制改 pytest（除非 keyword 变）；seed 脚本变更不影响 pytest
