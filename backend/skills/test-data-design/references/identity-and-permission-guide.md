# 身份与权限对齐指引

> 配套 `test-data-design` Skill。明确黑盒用例在「功能权限 + 数据权限」下，造数与测试账号怎么对齐。
> **本指引的思路**：账号/Token 由外部准备（认证服务 / App 认证），**test-data-design 只造业务数据**；身份列（`{scope_id}`/`created_by`/`owner_id` 等）按 [system-landscape §4.3.4 测试账号约定表](../../../architecture/system-landscape.md#434-测试账号约定供-test-data-design-skill-消费) 写死；黑盒按 AC 挑对应 Token。

## 1. 两类权限，两种处理

| 权限类型 | 谁负责 | 造数怎么做 | 黑盒怎么做 |
|----------|--------|-----------|-----------|
| **功能权限**（`@RequirePermission` 权限码） | 认证/权限服务配角色+权限码 | **不在 seed 里写** | 挑有权限的 Token；403 用 `ADMIN_TOKEN_DENIED` |
| **数据权限**（scope / 创建人 / 用户本人） | 认证/权限服务配 scope；本仓 seed 写身份列 | 按 §4.3.4 约定 id 写 `{scope_id}`/`created_by`/`owner_id` | 挑对应 scope / 用户的 Token |

**关键**：功能权限 **不靠造数解决**，靠挑 Token；数据权限 **靠造数写对身份列**，Token 也按约定挑。

## 2. 数据权限的三种 seed 写法

| 数据权限类型 | seed 写什么列 | 对齐谁 | 例子 |
|--------------|---------------|--------|------|
| **层级 scope** | `{scope_id}`（如 `tenant_id` / `org_id`，归属键） | Token 的 `scopeIds` 含此值 | seed `tenant_id={scope_id_a}` ↔ `ADMIN_TOKEN_{SCOPE_A}` 的 `scopeIds=[{scope_id_a}]` |
| **行级创建人** | `created_by` | Token 解出的 `userId` | seed `created_by={u-scope-a}` ↔ `ADMIN_TOKEN_{SCOPE_A}` 的 `userId` |
| **C 端用户本人** | `owner_id` | App Token 的 `userId`/`ownerId` | seed `owner_id={u-app-a}` ↔ `APP_TOKEN` 的 `ownerId={u-app-a}` |

**具体 id 用什么**：查 [system-landscape §4.3.4 测试账号约定表](../../../architecture/system-landscape.md#434-测试账号约定供-test-data-design-skill-消费)，**不要自己编**。

## 3. 账号在哪里造

| 账号类型 | 在哪造 | 谁负责 | 本 Skill 是否造 |
|----------|--------|--------|----------------|
| B 端运营账号（角色/权限码/scope 授权） | **认证/权限服务**（外仓，见画像 §4.2/§4.3）测试环境 | 认证服务运维 / 对应服务造数 | **否** |
| C 端用户 Token | App 认证签发 | 本仓 `{project}-bff-app` 认证 + 用户档案 | **用户档案行**可由 seed 造；**Token** 不造 |
| 业务库身份列值（`{scope_id}`/`created_by`/`owner_id`） | 本仓库业务表 | 本 Skill seed SQL | **是**（写列值，按 §4.3.4 约定） |

**三条红线**：
- seed 脚本 **不连认证服务库插账号**
- seed 脚本 **不签发 Token**
- seed 脚本 **不调 `/user/me` 校验 Token**

## 4. Token 环境变量

由 [system-landscape §4.3.4](../../../architecture/system-landscape.md#434-测试账号约定供-test-data-design-skill-消费) 测试账号约定表规定，常见：

| 环境变量 | 用途 |
|----------|------|
| `ADMIN_TOKEN` | B 端平台超管（默认/主路径） |
| `ADMIN_TOKEN_{SCOPE_A}` | B 端一级数据范围（如租户/组织）scope 账号 |
| `ADMIN_TOKEN_{SCOPE_B}` | B 端二级数据范围（如业务单元）scope 账号 |
| `ADMIN_TOKEN_DENIED` | B 端无权限码账号（验 403） |
| `APP_TOKEN` | C 端用户 A（默认） |
| `APP_TOKEN_USER_B` | C 端用户 B（验「非本人不可见」） |

Token 值由运维/CI 注入环境变量，**不进 Git**。

## 5. 造数流程（Skill 步骤里引用）

1. 读 AC Given，识别是否涉及权限/数据隔离
2. **不涉及**（如 C 端只读列表搜索）：seed 只写主数据，任意合法 Token 即可
3. **涉及数据权限**：查 §4.3.4 约定表，seed 身份列写约定 id（如 `tenant_id={scope_id_a}`、`owner_id={u-app-a}`）
4. **涉及功能权限**：seed 不用改；黑盒按 AC 挑 Token（正向用有权限的，403 用 `ADMIN_TOKEN_DENIED`）
5. DP 的 `env_vars` 只写 pytest 需要的（如 `BLACKBOX_DATA_PROFILE`）；**不在 DP 里展开 identity 契约**

## 6. 跨仓对齐（进阶，可选）

若多仓（`{project}` / 认证服务 / 其他业务仓）需要共享同一套测试 id，避免各仓各自编造冲突 id：

| 阶段 | 做法 |
|------|------|
| 真源 | `system-landscape §4.3.4` 当真源；或独立 `test-contracts` 仓放 `{tests/data}/test-ids.yaml` |
| 各仓 seed | 读同一份约定写 id |
| 认证服务仓 persona | 同一份约定生成 SQL（SQL 通道） |
| CI | 先认证服务 persona → 再各仓 seed → 再黑盒（编排执行） |

**首版可不做**：仅靠 §4.3.4 表 + 人工对照即可；多仓漂移严重时再升级独立仓 + CI 拉取固定 ref。

## 7. 边界

- **不造账号**：认证服务账号 / C 端用户 Token 由外部准备
- **不跨仓写库**：seed SQL 只打本仓库业务表
- **不验证权限**：seed 脚本不调 `/user/me`，不校验 Token
- **真源是 §4.3.4**：身份列 id 从测试账号约定表来，不在 DP 里重复声明
