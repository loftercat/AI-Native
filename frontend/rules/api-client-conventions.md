# 请求层与 OpenAPI Client 约束

> 契约唯一真相：`docs/handoff/openapi/{后端BFF服务标识}.yaml`（以 [architecture/system-landscape.md](../architecture/system-landscape.md) §四 为准）。
> 后端 OpenAPI 约定见后端仓 `skills/detail-design/references/openapi-conventions.md`。

## 1. 统一请求层 `api/http.js`

所有网络请求 **必须**经 `api/http.js` 封装，**禁止**页面/组件直接 `wx.request`。

### 职责

- 注入鉴权头（按画像 §四，如 `Authorization: Bearer <token>`）
- 注入 `baseUrl`（按环境 dev/prod，见 `config/`，与画像 §四 一致）
- **业务成败判据**：严格按画像 §四（对齐后端画像 §3.7；若采用统一包装体则按约定的成功码判断，若采用 HTTP 状态码则按 `2xx` 判断）
- `401`（鉴权失效）：清 token + 触发重新登录，统一拦截不冒泡到页面
- 业务失败：抛标准化业务错误 `{ code, message }`，由调用方或全局提示处理
- 统一超时（`networkTimeout`）与开发期错误日志

### 骨架示意（以统一包装体 `{SUCCESS_CODE}` 模式为例）

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
        if (body.code === config.successCode) {
          resolve(body.data)          // 成功只返回业务数据
        } else if (body.code === 401 || res.statusCode === 401) {
          wx.removeStorageSync('token')
          // 触发重新登录（见 services/auth）
          reject({ code: 401, message: body.message })
        } else {
          reject({ code: body.code, message: body.message })
        }
      },
      fail() {
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
- 输入：`docs/handoff/openapi/{后端BFF服务标识}.yaml`（见画像 §四）
- 输出：`api/generated/`，方法名与 `operationId` 一致
- 何时跑：契约更新时手动 / commit hook / CI

### 封装

- 生成 client 底层调用 `api/http.js`（而非自带 fetch）
- 业务代码调 `api/generated/{operationId}(params)`，得到与 OpenAPI 对齐的数据结构
- **不**在业务代码里手写 path / method

## 3. 鉴权流程

```text
登录获取凭证 → POST 后端登录接口 → 获取 Token
  → wx.setStorageSync('token', token)
  → http.js 自动注入鉴权头
  → 401 → 清 token + 触发重新登录
```

- 请求拦截与 401 统一在 `http.js` 处理，不在每个调用方重复。

## 4. 错误展示（与 `rules/error-display-conventions.md` 联动）

| 错误来源 | 处理 |
|----------|------|
| 401 鉴权失效 | 静默重新登录（`http.js` 统一） |
| BFF 参数守卫错误（见画像 §4.3） | Toast 展示服务端 `message` |
| 领域业务错误（号段见后端画像 §3.7） | 按 Story AC 展示 `message` 或前端按 `code` 映射 |
| -1 网络异常 | Toast「网络异常」+ 重试 |

## 5. 多环境

```text
config/
  ├── index.js      # 按运行环境导出 baseUrl 与 successCode
  ├── dev.js        # 开发/联调环境 baseUrl（与画像 §四 对齐）
  └── prod.js       # 生产环境 baseUrl
```

## 6. 反模式

- 页面/组件直接 `wx.request`
- 自行拼接字段名（应认 OpenAPI schema）
- 每个调用方各自判断响应成功码
- 每个调用方各自处理 401
- 硬编码 baseUrl
