# OpenAPI / Swagger 契约约定

> 配套 `detail-design` Skill。HTTP 类 Story 产出或增量修改 `docs/api/{服务标识}/openapi.yaml` 时 **必须** 遵循。

## 1. 文件与工具

| 项 | 约定 |
|----|------|
| 路径 | `docs/api/{服务标识}/openapi.yaml`、`docs/api/{服务标识}/openapi.yaml` |
| 版本 | OpenAPI **3.0.3** |
| 浏览 | Swagger Editor、springdoc-openapi（实现阶段） |
| 校验 | 推荐 CI 使用 [Spectral](https://github.com/stoplightio/spectral)（`docs/api/{服务标识}/openapi.yaml` lint） |
| 导入 | Postman / Insomnia 可导入生成 Collection |

## 2. 与本项目 `Result<T>` 对齐

本仓库 **业务成败看 `body.code === 200`**，多数失败仍返回 **HTTP 200**（见 `rules/exception-and-result.md`）。

OpenAPI 须体现：

1. **`info.description`** 写明「HTTP 200 ≠ 业务成功」及自动化断言规则。
2. **`components/schemas/BusinessErrorBody`**：失败响应（`code`、`message`、`data`）。
3. **每接口 `responses.'200'`**：
   - `schema.oneOf`：`XxxSuccessBody` + `BusinessErrorBody`；或专用命名响应 schema。
   - **`examples`**：至少 **1 个成功 + 本接口涉及的每个失败 AC**（引用 `components/examples`）。
4. **禁止** 仅写泛型 `Result` + `allOf` 而不挂失败 `examples`（Swagger / Newman 无法生成失败用例）。

成功响应建议 **每接口独立** `XxxSuccessBody`（含 `code: enum: [200]`、`data` 具名类型），便于契约测试与 springdoc 对照。

## 3. 必填结构清单（HTTP Story）

详设落盘 OpenAPI 前自检：

- [ ] `openapi` 3.0.3、`info.title`、`info.version`、`info.description`（含 Result 语义）
- [ ] `servers`：含 `http://localhost:8080/api/v1/love/{app|admin}` **和** 相对路径
- [ ] `paths.*.operationId` 唯一、camelCase（供代码生成）
- [ ] `tags` 按资源分组
- [ ] 每个 operation：`summary`、`description` 标注 **Story AC 编号**
- [ ] `components/securitySchemes.bearerAuth`（BFF 需鉴权接口）
- [ ] 需登录的 operation 声明 `security: [bearerAuth: []]`
- [ ] `components/schemas`：请求/响应 DTO + `BusinessErrorBody`
- [ ] `components/examples`：每个业务错误码至少一个 example
- [ ] 每个 `responses.'200'.content.application/json.examples` 挂成功 + 失败样例
- [ ] 错误码与详设 §5.3、域 `*ErrorCode` 枚举一致

## 4. 错误码与 examples 映射

| 层级 | OpenAPI 落点 |
|------|--------------|
| Story AC 失败文案 | `components/examples/ErrorXxx` + operation `examples` 引用 |
| 业务码 | `BusinessErrorBody.code` + 详设 §5.3 表 |
| 参数校验失败 | `code: 400`，message 与 AC 一致 |

**规则**：Story 中每条「失败类 Then」须在 OpenAPI 某 operation 的 `examples` 中有对应项，或在详设 §5.3 标 N/A。

## 5. 自动化测试衔接

| 测试方式 | 使用 OpenAPI 的方式 |
|----------|---------------------|
| **JUnit `@WebMvcTest`** | 以 Story AC 为准；OpenAPI 作字段对照，非必须 |
| **Postman + Newman** | 导入 YAML；Collection 变量 `baseUrl`、`token`；断言 `pm.expect(json.code).to.eql(200)` |
| **REST Assured + OpenAPI** | 校验响应 schema 用每接口 `SuccessBody`；业务失败用 examples 手工用例 |
| **springdoc 运行时** | `love-app` 引入 `springdoc-openapi-starter-webmvc-ui`；实现后与 `docs/api` diff |
| **契约回归** | PR 改 `docs/api/{服务标识}/openapi.yaml` 时跑 Spectral + 可选 openapi-diff |

详设 §9 **测试策略** 须注明：哪些 AC 用 MockMvc、哪些计划用 Newman/契约（若本 Story 含 HTTP）。

## 6. springdoc 与 BFF Java 注解（feature-coding 阶段）

**契约优先**：评审与自动化以 `docs/api/*.yaml` 为准。  
实现阶段 BFF Controller / VO **必须**补中文 JavaDoc + OpenAPI 注解（`@Tag` / `@Operation` / `@Schema`），文案与 YAML `summary`/`description`/字段说明一致。完整清单见 [layer-guides.md](../../feature-coding/references/layer-guides.md) §5.1。

```xml
<!-- love-app -->
<dependency>
  <groupId>io.swagger.core.v3</groupId>
  <artifactId>swagger-annotations-jakarta</artifactId>
</dependency>

<!-- love-app：Swagger UI -->
<dependency>
  <groupId>org.springdoc</groupId>
  <artifactId>springdoc-openapi-starter-webmvc-ui</artifactId>
</dependency>
```

- 开发环境：`/swagger-ui.html`（springdoc 2.x 默认路径）
- springdoc 扫描结果与 YAML 对照，避免漂移
- 可选：`springdoc.swagger-ui.url` 指向静态 `docs/api` 合并后的 openapi

## 7. 反模式

- 只有 `200` 成功 schema、无失败 examples
- 用 `Object` 作 `data` 类型
- 错误码只在详设表格、OpenAPI 未体现
- Admin / App 混在同一 openapi 文件（应分 `love-app`）
- 域 `XxxApi` 写入 OpenAPI（域无 HTTP，只写 BFF）

## 8. 变更记录

| 日期 | 变更 |
|------|------|
| 2026-07-26 | 初版：Result 语义、examples、Swagger/自动化测试约定 |
| 2026-07-30 | BFF 必补 `@Tag`/`@Operation`/`@Schema` + 中文 JavaDoc；与 feature-coding §5.1 对齐 |
