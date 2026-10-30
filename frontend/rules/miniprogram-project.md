# 微信小程序工程约束

读代码或改代码前，先扫一眼 [AGENTS.md](../README.md) 与 [docs/architecture/system-landscape.md](../architecture/system-landscape.md)。

> 权威来源：[微信开放文档 - 目录结构](https://developers.weixin.qq.com/miniprogram/dev/framework/structure.html)、[小程序代码构成](https://developers.weixin.qq.com/miniprogram/dev/framework/quickstart/code.html)。

## 1. 主体三文件（必须根目录）

| 文件 | 必需 | 作用 |
|------|------|------|
| `app.js` | 是 | 小程序逻辑 |
| `app.json` | 是 | 小程序公共配置（pages、window、tabBar、networkTimeout、subpackages） |
| `app.wxss` | 否 | 公共样式表 |

## 2. 页面四同名文件（微信硬约束）

> 描述页面的四个文件**必须具有相同的路径与文件名**（微信官方）。

```text
pages/home/
  ├── home.js      # 页面逻辑（必须）
  ├── home.wxml    # 页面结构（必须）
  ├── home.json    # 页面配置（可选）
  └── home.wxss    # 页面样式（可选）
```

## 3. 必守

1. **主体三文件**在根目录；页面四文件同名同路径
2. **只调 BFF**：`/api/v1/booking/app/...`；页面不直接 `wx.request`，经 `api/http.js` 或 `services/`
3. **契约唯一**：字段/错误码只认 `docs/handoff/openapi/booking-bff-app.yaml`；前端不得发明字段
4. **业务成败看 `body.code === 200`**（HTTP 常为 200，以 body 为准）
5. **分包**：主包 < 2MB；非首屏流程进 `subpackages`
6. **`project.private.config.json` 入 `.gitignore`**（个人偏好，避免团队冲突）
7. **`project.config.json` 入库**；明确 `libVersion` 保证团队基础库一致

## 4. 目录归属

| 路径 | 归属 |
|------|------|
| `app.js`/`app.json`/`app.wxss` | 小程序主体（根目录） |
| `pages/{page}/` | 页面四同名文件 |
| `packageA/pages/` | 分包页面 |
| `components/{comp}/` | 自定义组件（四同名文件） |
| `api/http.js` | 统一 `wx.request` 封装（`code`/401/baseUrl 拦截） |
| `api/generated/` | OpenAPI 生成 client（可选） |
| `services/` | 业务逻辑封装（按域：`booking/`、`order/`、`payment/`、`nav/`） |
| `utils/` | 纯工具函数（无副作用） |
| `config/` | 环境配置（dev/prod baseUrl） |
| `styles/` | 公共样式 / Less 变量 |
| `images/` | 静态图片 |
| `docs/` | AI Native 文档资产 |

## 5. 命名规范

| 类型 | 命名 | 示例 |
|------|------|------|
| 页面目录 | kebab-case | `pages/order-detail/` |
| 页面文件 | 与目录同名 | `order-detail.{js,wxml,wxss,json}` |
| 组件目录 | kebab-case | `components/reservation-card/` |
| 组件文件 | 与目录同名 | `reservation-card.{js,wxml,wxss,json}` |
| 工具函数 | camelCase | `utils/format-date.js` |
| service | 按域 + camelCase 方法 | `services/booking/createOrder` |
| API 方法 | 与 OpenAPI `operationId` 一致 | `api/generated/getActiveReservation` |
| 全局状态 | `globalData.*` camelCase | `app.globalData.token` |

## 6. app.json 关键配置

| 配置项 | 用途 | 最佳实践 |
|--------|------|----------|
| `pages` | 页面路径数组，**第一项为首页** | 按业务域分组注释 |
| `window` | 全局窗口表现 | 导航栏色统一 |
| `tabBar` | 底部导航 | 首页/我的订单/我的 |
| `networkTimeout` | 请求超时 | `request: 10000` |
| `subpackages` | 分包 | 按业务域；主包 < 2MB |
| `debug` | 调试模式 | 开发开，生产关 |
| `lazyCodeLoading` | 按需注入 | `"requiredComponents"` 降内存 |

## 7. TypeScript

V1 用 JS（不启用 TS）。

## 8. UI 库：vant-weapp

- UI 库选型：**vant-weapp**（有赞，小程序原生组件库）
- 引入方式：`npm i @vant/weapp`，微信开发者工具「工具 → 构建 npm」生成 `miniprogram_npm/`
- 页面按需在 `*.json` 的 `usingComponents` 声明用到的组件，**不**全局注册
- 优先用 vant 组件（Button、Cell、Toast、Dialog、Empty 等）；业务强相关组件自建放 `components/`
- 主题定制：覆盖 vant CSS 变量，统一在 `styles/` 维护
- 与原生组件混用时注意样式隔离（`styleIsolation`）

## 9. 反模式

- 页面里直接 `wx.request`（应经 `api/http.js`）
- 自行定义后端字段名（应认 OpenAPI）
- 所有页面堆主包（应分包）
- `project.private.config.json` 入库
- 页面四文件不同名（微信会报错）
