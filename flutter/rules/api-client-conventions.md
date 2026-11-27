# 请求层与 OpenAPI Client 约束

## 1. 统一请求层

### 职责

从 [handoff](../docs/handoff/README.md) 的 OpenAPI + VERSION 确定 operationId、方法、路径、字段、分页、空值、时间单位及错误语义。仅调用本卡列出的公开服务。示例里的业务成功码仅适用于该契约。

Widget → ViewModel → Repository → 业务 Service → 统一 HTTP 客户端。每个信任域使用独立配置。统一 HTTPS、超时、请求关联 ID、取消和错误转换；业务 Token 仅向允许的主机发送，重定向也需校验目的地。生产构建验证证书。

### 接口定义与中文注释

业务网络接口按模块在 `lib/features/{feature}/request/*_service.dart` 定义和实现。Service 直接使用注入的统一 HTTP 客户端，在各自的请求方法中维护与 handoff `operationId` 对应的 HTTP 方法、路径、参数绑定和接口专属请求配置。应用入口装配 HTTP 客户端；`lib/core/network/` 负责客户端配置、日志、鉴权等跨模块请求策略。接口总览沿用 handoff 的 OpenAPI 和 operationId 索引。

为每个接口方法用 Dart 文档注释记录用途、`operationId`、HTTP 方法、路径、每个请求参数及响应含义。逐项核对当前 handoff 的路径、查询、请求头、请求体和响应 schema。接口参数及请求、响应 Bean 字段都须带对应的中文注释，保留契约描述中的必填性、空值、单位、格式、枚举等有定义的语义。字段缺少独立描述时，按 schema 和已说明的接口语义补注释，待确认的业务含义向上游核实。

### 骨架示例

```text
ViewModel → Repository → 业务 Service（operationId、方法、路径、参数）
                         → 统一客户端（baseUrl、认证、超时、日志）
```

## 2. OpenAPI Client（可选）

### 生成

以 handoff 快照为输入，在 VERSION 变化后重新生成 Dart client，核对 operationId、空值和枚举。生成目录和命令由项目画像记录。

### 封装

采用生成客户端时，由各业务 Service 调用本模块对应的生成方法，Repository 接收类型化数据。Bean 字段的中文注释随契约更新，生成模型的注释维护方式见[工程规范](flutter-project.md#中文业务注释写法)。

## 3. 鉴权流程

根据画像定义的认证失效信号处理 HTTP 401 或契约业务码。支持刷新时，同一会话的并发请求共享一次刷新；刷新端点排除自身拦截，原调用最多重放一次且请求体可重建。临时断网保留恢复机会，凭据确实失效时统一清会话并触发一次登录路由。退出或换号后丢弃旧会话的刷新结果和响应。

## 4. 错误展示

分别识别传输异常、HTTP 状态、业务结果与解析异常；兼容无响应体等契约约定。取消静默结束；超时可重试时给出入口；展示规则见[错误反馈](error-display-conventions.md)。

## 5. 多环境

通过 `AppConfig` 获取当前 flavor 的服务地址，客户端静态配置、HTTPS、签名和日志开关遵循[打包配置](testing-release.md#打包配置)。用户会话等运行时凭据按项目的安全存储方案处理。

## 6. 反模式

典型问题包括 Widget 直接拼接 URL、不同页面分别刷新 Token，以及切换账号后仍接受旧请求。

GET 等可安全重试的调用使用有限次数、退避并尊重服务端限流。创建、支付等写操作需要服务端幂等键及结果查询；响应丢失先确认结果。前端禁用按钮只能防止重复点击。

搜索防抖并校验请求序号；分页按查询条件、游标及账号隔离，拒绝过期页。上传另设超时与取消策略。请求、响应和 Dio 异常路径统一执行[分环境日志规则](testing-release.md#分环境日志)。
