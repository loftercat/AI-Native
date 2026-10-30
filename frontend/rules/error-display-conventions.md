# 错误展示约束

> 与后端错误码分层对齐，详见后端仓 `docs/reference/exception-and-result.md`。  
> 业务成败判据：`body.code === 200`（HTTP 常为 200，以 body 为准）。

## 1. 错误码分层

| 层级 | 来源 | code 示例 | 前端处理 |
|------|------|-----------|----------|
| 系统 | `hema-common` `ErrorCode` | 401 / 403 / 500 / 502 | 401→重新登录；其它→通用 Toast |
| BFF 守卫 | `booking-common` `BookingErrorCode` | 400 | Toast `message` |
| 域业务 | order 1500–1599、inventory 1600–1699、adapter 1700–1799 | 1501 / 1606 | 按 Story AC 展示 `message` 或前端按 `code` 映射 |
| 网络 | `http.js` | -1 | Toast「网络异常」+ 重试 |

## 2. 展示方式

| 场景 | 方式 |
|------|------|
| 表单校验/参数错 | Toast（`wx.showToast`） |
| 业务阻断（如无车位） | Toast `message` |
| 关键操作失败（支付/下单） | Modal `wx.showModal` + `message` |
| 401 | 静默重新登录（不 Toast） |
| 网络异常 | Toast + 重试按钮 |

## 3. 文案来源

- **默认用后端 `message`**（中文，写死在后端域错误码枚举）
- 若需前端按 `code` 映射（如离线文案），在 `services/` 维护映射表，**不**散落页面
- 多语言 V1 不做（后端 `message` 中文写死）

## 4. 全局拦截

- `api/http.js` 统一拦截 `code !== 200`，抛 `{ code, message }`
- 页面/组件 catch 后决定 Toast / Modal / 跳转
- 401 在 `http.js` 统一处理，**不**冒泡到页面

## 5. 反模式

- 每个调用方各自判断 `code === 200`
- 每个调用方各自 Toast
- 前端重新定义错误码文案（应认后端 `message`）
- 401 在页面处理（应在 `http.js` 统一）
