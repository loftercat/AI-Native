# 错误展示约束

> 与后端错误码分层对齐，详见 [architecture/system-landscape.md](../architecture/system-landscape.md) §4.3 与后端画像 `§3.7`。
> 业务成败判据以画像 §四 为准。

## 1. 错误码分层

| 层级 | 来源（见后端画像 §3.7） | 前端处理 |
|------|-------------------------|----------|
| 系统层 | 后端系统错误码（401 / 403 / 500 / 502 等） | 401 → 静默重新登录；其余 → 通用 Toast |
| BFF 守卫层 | 后端 BFF 参数守卫错误码 | Toast 展示 `message` |
| 领域业务层 | 各领域微服务错误码号段 | 按 Story AC 展示 `message` 或前端按 `code` 映射 |
| 网络层 | `api/http.js`（`-1`） | Toast「网络异常」+ 重试 |

## 2. 展示方式

| 场景 | 方式 |
|------|------|
| 表单校验 / 参数非法 | Toast（`wx.showToast`） |
| 普通业务阻断 | Toast `message` |
| 关键操作失败（如资金/提交类不可逆操作） | Modal（`wx.showModal`）+ `message` |
| 401 鉴权失效 | 静默重新登录（不弹 Toast） |
| 网络异常 | Toast + 重试入口 |

## 3. 文案来源

- **默认用后端返回 `message`**（与 OpenAPI examples / Story AC 对齐）
- 若需前端按 `code` 映射（如多语言或特殊引导文案），在 `services/` 维护集中映射表，**不**散落页面

## 4. 全局拦截

- `api/http.js` 统一按画像 §四 拦截失败响应，抛 `{ code, message }`
- 页面/组件 catch 后决定 Toast / Modal / 跳转
- 401 在 `http.js` 统一处理，**不**冒泡到页面

## 5. 反模式

- 每个调用方各自解析成功判据
- 每个调用方各自弹重复 Toast
- 前端脱离 Story/OpenAPI 自行发明错误码文案
- 401 在页面内各自处理（应在 `http.js` 统一）
