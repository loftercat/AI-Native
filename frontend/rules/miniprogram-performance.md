# 微信小程序性能与内存约束

> 权威来源（微信开放文档）：  
> - [合理使用 setData](https://developers.weixin.qq.com/miniprogram/dev/framework/performance/tips/runtime_setData.html)  
> - [内存优化](https://developers.weixin.qq.com/miniprogram/dev/framework/performance/tips/runtime_memory.html)  
> - [渲染性能优化](https://developers.weixin.qq.com/miniprogram/dev/framework/performance/tips/runtime_render.html)  
> - [评测标准](https://developers.weixin.qq.com/miniprogram/dev/framework/performance/perf_diagnostic_rules.html)

## 1. setData（最高频性能问题）

`setData` 涉及逻辑层→渲染层线程通信，滥用导致卡顿/OOM。

### 必守

- ✅ 仅在需要更新视图时调用 `setData`
- ✅ **只传变化的字段**，不传整个对象
- ✅ **合并连续 `setData`** 为一次
- ✅ 单次 `setData` 数据 `JSON.stringify` 后 **< 256KB**
- ✅ 每秒 `setData` 次数 **≤ 20**
- ✅ 优先用 **组件的 `setData`**（只更新当前组件+子组件，降低虚拟 DOM 开销）

### 禁止

- ❌ 毫秒级高频 `setData`（如倒计时用 `setInterval` + `setData`）
- ❌ 在 `onPageScroll` 回调里每次 `setData`
- ❌ 后台态页面 `setData`（抢占前台；延迟到 `onShow` 后）
- ❌ 传与渲染无关的数据进 `setData`

### 倒计时/动画

- 倒计时：用 `setTimeout` 递归或服务端时间差，**不**用 `setInterval` + 高频 `setData`
- 动画：优先 **CSS 动画 / WXS 响应事件**；不得已用 `setData` 时改为组件级 `setData`

## 2. 内存泄漏（OOM 主因）

页面 `onUnload` 后基础库清理页面栈；若代码持有 `this` 未释放 → 无法回收 → 内存持续增长 → 闪退/被微信销毁。

### 必守：onUnload 清理清单

```js
Page({
  onLoad() {
    this._timer = setInterval(...)
    this._handler = this.onChange.bind(this)
    wx.onThemeChange(this._handler)
    wx.onLocationChange(this._locHandler)
  },
  onUnload() {
    clearInterval(this._timer)              // 1. 清定时器
    wx.offThemeChange(this._handler)       // 2. 解绑 wx.on* 监听
    wx.offLocationChange(this._locHandler)
    getApp().userInfoListener = null       // 3. 清全局/外部引用
    this._timer = this._handler = null
  }
})
```

### 三类典型泄漏（微信官方案例）

1. **事件监听未解绑**：`wx.onThemeChange`/`onLocationChange` 等持有 `this`，`onUnload` 必须 `wx.off*`
2. **外部/全局变量引用**：闭包挂到 `getApp()` 或模块级变量，`onUnload` 置 `null`
3. **长异步回调持有 this**：长 `setTimeout`/`setInterval`/耗时 `wx.request`，`onUnload` `clearTimeout`/`clearInterval`

### 内存告警

- 用 `wx.onMemoryWarning` 监听，主动释放暂不用的组件/JS 对象
- iOS 连续内存告警 → 微信主动销毁小程序

## 3. 渲染性能

### WXML 节点

- ✅ 单页 WXML 节点 **< 1000**
- ✅ 节点树深度 **< 30 层**
- ✅ 子节点数 **≤ 60**

### 复杂数据

- Page 构造参数的 **自定义数据会被深拷贝**；复杂/大量数据 **在 `onLoad`/`created` 手动赋值到 `this`**，不通过构造参数传

### scroll 事件

- ✅ 非必要 **不监听** `onPageScroll`（构造时不传，而非留空函数）
- ✅ 滚动动画用 **滚动驱动动画** 或 **WXS 响应事件**
- ❌ scroll 回调里复杂逻辑 / `setData` / 同步 API

## 4. 启动与包体积

- ✅ 分包加载（`subpackages`）降启动耗时与内存
- ✅ 开启 **按需注入** + **用时注入**（`lazyCodeLoading: "requiredComponents"`）
- ✅ 主包 < 2MB，总包 < 20MB
- ✅ 图片压缩、按需加载

## 5. 网络与缓存

- ✅ 缓存 `storage` / `getSystemInfo` / `getLocation` 结果（30s 内不重复调 `getLocation`）
- ✅ 本地缓存占用 **< 50%**
- ✅ `wx.request` 超时统一在 `api/http.js` 配 `networkTimeout`

## 6. 评测红线（微信评分）

| 指标 | 红线 |
|------|------|
| `setData` 频率 | ≤ 20 次/秒 |
| `setData` 数据量 | < 256KB（stringify 后） |
| WXML 节点 | < 1000/页 |
| 页面方法耗时 | < 50ms |
| scroll 事件处理 | < 50ms / 总 < 150ms |
| `wx.on*` 监听 | 页面销毁时必须移除 |
| `observe` 监听 | 页面销毁时必须停止 |

## 7. 反模式

- `setInterval` 倒计时 + 每秒 `setData`
- `onUnload` 不解绑 `wx.on*`
- 全局变量持有页面 `this`
- 后台页继续 `setData`
- `onPageScroll` 留空函数（应不传）
- 主包塞所有页面
