# 请求层与 OpenAPI Client 约束

> 契约唯一真相：`docs/handoff/openapi/booking-bff-app.yaml`（从后端同步）。  
> 后端 OpenAPI 约定见后端仓 `skills/detail-design/references/openapi-conventions.md`。

## 1. 统一请求层 `api/http.js`

所有网络请求 **必须**经 `api/http.js` 封装，**禁止**页面/组件直接 `wx.request`。

### 职责

- 注入 `Authorization: Bearer <token>`（从 `wx.getStorageSync('token')`）
- 注入 `baseUrl`（按环境 dev/prod，见 `config/`）
- **业务成败判据**：`response.data.code === 200` 为成功
- `code === 401`：清 token + 触发重新 `wx.login`
- `code !== 200`：抛业务错误（含 `code`/`message`），由调用方或全局 Toast 处理
- 统一超时（`networkTimeout`）
- 错误日志（开发期）

### 骨架示例

```js
// api/http.js
const config = require('../config/index')

function request(options) {
  const { method = 'GET', url, data, header = {} } = options
  const token = wx.getStorageSync('token')
  return new Promise((resolve, reject) => {
    wx.request({
      url: config.baseUrl + url,
      method,
      data,
      header: Object.assign(
        { 'Content-Type': 'application/json' },
        token ? { Authorization: 'Bearer ' + token } : {},
        header
      ),
      success(res) {
        const body = res.data || {}
        if (body.code === 200) {
          resolve(body.data)          // 成功只返回 data
        } else if (body.code === 401) {
          wx.removeStorageSync('token')
          // 触发重新登录（见 services/auth）
          reject({ code: 401, message: body.message })
        } else {
          reject({ code: body.code, message: body.message })
        }
      },
      fail(err) {
        reject({ code: -1, message: '网络异常' })
      }
    })
  })
}

module.exports = { request }
```

## 2. OpenAPI Client（可选但推荐）

### 生成

- 工具选型（任一）：`openapi-typescript-codegen` / `orval` / 手写封装
- 输入：`docs/handoff/openapi/booking-bff-app.yaml`
- 输出：`api/generated/`，方法名与 `operationId` 一致
- 何时跑：契约更新时手动 / commit hook / CI

### 封装

- 生成 client 底层调用 `api/http.js`（而非自带 fetch）
- 业务代码调 `api/generated/getActiveReservation(params)`，得到强类型 `data`
- **不**在业务代码里手写 path / method

## 3. 鉴权流程

```text
wx.login() → code → POST 后端登录 → Bearer JWT
  → wx.setStorageSync('token', jwt)
  → http.js 自动注入 Authorization
  → 401 → 清 token + 重新 wx.login
```

- token 存 `wx.setStorageSync('token', ...)`
- 请求拦截在 `http.js` 统一加 header
- 401 处理在 `http.js` 统一，不在每个调用方重复

## 4. 错误展示（与 `rules/error-display-conventions.md` 联动）

| code 来源 | 处理 |
|-----------|------|
| 401 | 重新登录（`http.js` 统一） |
| 400 BFF 守卫 | Toast `message` |
| 1501/1606 等域业务 | 按 Story AC 展示 `message` 或前端按 `code` 映射 |
| -1 网络异常 | Toast「网络异常」+ 重试 |

## 5. 多环境

```text
config/
  ├── index.js      # 按 __wxConfig.env 或构建变量导出 baseUrl
  ├── dev.js        # dev baseUrl
  └── prod.js       # prod baseUrl
```

- dev: `http://localhost:8080/api/v1/booking/app`（联调后端）
- prod: `https://{domain}/api/v1/booking/app`

## 6. 反模式

- 页面/组件直接 `wx.request`
- 自行拼接字段名（应认 OpenAPI schema）
- 每个调用方各自判断 `code === 200`
- 每个调用方各自处理 401
- 硬编码 baseUrl
