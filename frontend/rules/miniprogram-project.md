# 微信小程序工程约束

读代码或改代码前，先扫一眼 [frontend/README.md](../README.md) 与 [architecture/system-landscape.md](../architecture/system-landscape.md)。

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
pages/{page}/
  ├── {page}.js      # 页面逻辑（必须）
  ├── {page}.wxml    # 页面结构（必须）
  ├── {page}.json    # 页面配置（可选）
  └── {page}.wxss    # 页面样式（可选）
```

## 3. 必守

1. **主体三文件**在根目录；页面四文件同名同路径
2. **只调 BFF**（`baseUrl` 以画像 §四 为准）；页面不直接 `wx.request`，经 `api/http.js` 或 `services/`；严禁直连后端领域微服务
3. **契约唯一**：字段/错误码只认画像 §四 指定的 `docs/handoff/openapi/{后端BFF服务标识}.yaml`；前端不得发明字段
4. **业务成败判据**：严格遵循画像 §四（对齐后端画像 §3.7）
5. **分包**：主包 < 2MB；非首屏流程进 `subpackages`
6. **`project.private.config.json` 入 `.gitignore`**（个人偏好，避免团队冲突）
7. **`project.config.json` 入库**；明确 `libVersion` 保证团队基础库一致

## 4. 目录归属

| 路径 | 归属 |
|------|------|
| `app.js`/`app.json`/`app.wxss` | 小程序主体（根目录） |
| `pages/{page}/` | 页面四同名文件 |
| `package{X}/pages/` | 分包页面 |
| `components/{comp}/` | 自定义组件（四同名文件） |
| `api/http.js` | 统一 `wx.request` 封装（成功判据/401/baseUrl 拦截） |
| `api/generated/` | OpenAPI 生成 client（可选） |
| `services/{domain}/` | 按业务域划分的业务逻辑封装 |
| `utils/` | 纯工具函数（无副作用） |
| `config/` | 环境配置（dev/prod baseUrl） |
| `styles/` | 公共样式 / Less 变量 |
| `images/` | 静态图片 |
| `docs/` | AI Native 文档资产 |

## 5. 命名规范

| 类型 | 命名 | 格式示意 |
|------|------|----------|
| 页面目录 | kebab-case | `pages/{entity}-detail/` |
| 页面文件 | 与目录同名 | `{entity}-detail.{js,wxml,wxss,json}` |
| 组件目录 | kebab-case | `components/{entity}-card/` |
| 组件文件 | 与目录同名 | `{entity}-card.{js,wxml,wxss,json}` |
| 工具函数 | kebab-case 文件 + camelCase 导出 | `utils/format-date.js` |
| service | 按域 + camelCase 方法 | `services/{domain}/{action}` |
| API 方法 | 与 OpenAPI `operationId` 一致 | `api/generated/{operationId}` |
| 全局状态 | `globalData.*` camelCase | `app.globalData.token` |

## 6. app.json 关键配置

| 配置项 | 用途 | 最佳实践 |
|--------|------|----------|
| `pages` | 页面路径数组，**第一项为首页** | 按业务域分组注释 |
| `window` | 全局窗口表现 | 导航栏色统一 |
| `tabBar` | 底部导航 | 按画像 §一 与设计稿配置 |
| `networkTimeout` | 请求超时 | `request: 10000` |
| `subpackages` | 分包 | 按业务域；主包 < 2MB |
| `debug` | 调试模式 | 开发开，生产关 |
| `lazyCodeLoading` | 按需注入 | `"requiredComponents"` 降内存 |

## 7. 语言与 UI 组件库

- 语言（JS / TS）与 UI 组件库选型以画像 §3.1 为准；组件按需在页面 `*.json` 的 `usingComponents` 声明，不全局注册；主题变量统一在 `styles/` 维护。

## 8. 反模式

- 页面里直接 `wx.request`（应经 `api/http.js`）
- 自行定义后端字段名（应认 OpenAPI）
- 所有页面堆主包（应分包）
- `project.private.config.json` 入库
- 页面四文件不同名（微信会报错）
