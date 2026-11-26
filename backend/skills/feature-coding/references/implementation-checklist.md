# 功能编码实现检查清单（Java 微服务版）

> 执行 Skill：`../SKILL.md`
> 每层实现与测试完成后勾选；阻断项未解除不得进入下一层。

---

## 0. 开工前（步骤 1～4）

- [ ] Story 编号、AC/BR、变更记录已读
- [ ] 详设 §8 代码骨架 / AC→追溯表已读
- [ ] 画像 `architecture/system-landscape.md` §5.4 第一档（P-1~P-6）及本 Story 命中的第二档（E-1~E-7）均已定稿（无未决 `[TBD]`）
- [ ] 缺口清单已输出（阻断 / 整改 / 可补充）
- [ ] 服务终判与 Story「服务/模块」及画像 §二 一致
- [ ] 对外 BFF OpenAPI / 服务间内部契约（按画像 P-2）与详设 §5 对齐
- [ ] 错误码号段与响应格式符合画像 §3.7（P-4）与 `rules/exception-and-result.md`

---

## 1. 持久化层（本服务 `*-impl/infrastructure/`，详设 §6 要求时）

### 实现

- [ ] **无跨服务 SQL JOIN、无跨服务外键**，仅操作本服务独占表（见画像 §二）
- [ ] DO/Entity 字段与 `docs/schema/{服务标识}/schema.md`（含 DDL）或详设 §6 一致
- [ ] Flyway：`docs/schema/{服务标识}/ddl/V{序号}__{Story}.sql` 已落盘到**本服务** `{service}-impl/src/main/resources/db/migration/`；**禁止修改已合并的** `V{n}__*.sql`
- [ ] 若本服务持久化单测另维护 `src/test/resources/schema.sql`，已与本服务 Flyway 结果逐表同构
- [ ] ORM 实现严格遵循画像 §5.4 **P-3** 与 schema-conventions §1.2 的执行口径（若选 MyBatis：非主键 SQL 仅 XML，只执行「项目实现」已填写的主键分支与删除分支；若选其他 ORM：只执行替换规则文首，未写明主键或删除则阻断。软删支条件查询含 `deleted = 0` 且软删用 `UPDATE`；状态作废支不追加 `deleted = 0`；两支都不用 `deleteById` 做业务删除）

### 测试

- [ ] 默认 **不在** Service 测试外单独测简单 CRUD（复杂 SQL 按需跑容器持久化测试）
- [ ] Service 层用 Mock 持久化层覆盖 AC（无真实 DB）

---

## 2. 服务契约层（`*-api/`）

### 实现

- [ ] 远程契约接口/客户端（按画像 P-2）+ DTO/枚举，**无业务实现代码**
- [ ] DTO 命名与详设 §8.3 一致；请求/响应分离
- [ ] 服务错误码枚举（如 `{Domain}ErrorCode`）含 code + 默认 message，号段对齐画像 §3.7
- [ ] 内部 DTO 不泄漏 BFF VO；不违反画像 §5.4 P-6 公共库边界

### 测试

- [ ] 本层通常无独立测试；由服务单测与单服务 `*IT` 覆盖

---

## 3. 领域微服务实现层（`*-impl/`）

### 实现

- [ ] 内部远程入口（HTTP 内部 Controller 或 RPC Provider，按画像 P-2）薄委托 → Facade，且落实画像 **P-5** 防外泄与鉴权/透传头要求
- [ ] Facade 编排；**核心状态机在 Service / 可选贫血 domain**，不在 BFF
- [ ] **领域厚度**按详设 §4.4：薄 Story 用 Service+DO+DTO；复杂可选 `domain/model`（贫血）
- [ ] **状态迁移落库**：条件 `UPDATE`（`WHERE status=?`）；`affected_rows=0` → 抛业务异常；**非**默认全量覆盖
- [ ] DO↔DTO 经 `infrastructure/converter` MapStruct（或详设已列 `*Converter`）；**禁止** Service 内大段手写拷贝
- [ ] Service 抛业务异常 + 域错误码，入口层不吞异常；跨服务错误传播按画像 §3.7（P-4）统一在客户端解包层处理
- [ ] 跨服务调用经 `app/client` 封装下游服务的 `*-api` 远程客户端（按画像 P-2）+ 透传请求头（按 P-5）；**严禁依赖其他服务的 `*-impl`**
- [ ] 外部厂商南向对接仅在专属适配微服务中实现；业务服务不直连外部厂商
- [ ] **事务与一致性核对**：本地 `@Transactional` **仅限本服务单库多步写**，严禁包裹跨服务远程调用；涉及跨服务写一致性按详设与画像 **E-3** 落实幂等/补偿/发件箱

### 测试（本服务 `*-impl/src/test/java/`）

- [ ] `*ServiceTest`：JUnit 5 + Mockito；Mock 持久化层 / 下游远程客户端 / 外部 Client
- [ ] 覆盖 Story BR 边界（详设 §9）
- [ ] 断言业务异常的 code 与 message（对齐 AC）
- [ ] 不启动完整容器与外部注册中心（单服务 `*IT` 归 `integration-test-design`）

---

## 4. BFF 层（`{project}-bff-app` / `{project}-bff-admin`）

### 实现

- [ ] Controller 仅：鉴权上下文、**守卫**（空参/格式）、调用下游远程客户端（按 P-2）、VO 转换与响应封装（按 P-4）
- [ ] DTO↔VO 经 `{basePackage}.bff.*.converter` MapStruct；**禁止** Controller 内手写字段映射
- [ ] **禁止**在 BFF 实现 normalize、分词、匹配、推荐、状态机、资源锁定或跨服务复杂写编排
- [ ] **禁止** BFF 与领域微服务各建同职责工具类；详设 §8 重复时**阻断**并回溯 `detail-design`
- [ ] 对外 URL 前缀对齐画像 §六（如 App `/api/v1/{project}/app/`；Admin `/api/v1/{project}/admin/`）
- [ ] `@Valid` 请求体；校验失败由全局异常处理器统一处理
- [ ] Controller 类/公开方法有**中文 JavaDoc**；`@Tag` + `@Operation(summary, description)`，对齐 OpenAPI YAML
- [ ] 需登录接口有 `@SecurityRequirement(name = "bearerAuth")`（与 YAML 一致）
- [ ] 请求/响应 VO 字段有中文 `@Schema(description)`
- [ ] 模块依赖 `io.swagger.core.v3:swagger-annotations-jakarta`（见 layer-guides §5.1）

### 测试（`{project}-bff-*/src/test/java/`）

- [ ] `{Resource}ControllerTest`：`@WebMvcTest(controllers = {Resource}Controller.class)` + MockMvc
- [ ] Mock 下游远程客户端，不访问数据库
- [ ] 断言 HTTP 状态、业务响应字段（对齐画像 §3.7）与关键返回数据
- [ ] 失败类 AC 对齐 Story 可见文案

---

## 5. 服务独立配置与网关（按需）

- [ ] 本服务 `application-test.yml` 关闭外部服务注册与配置中心（按画像 E-1），保证单测与 `*IT` 离线可跑
- [ ] 若 Story 涉及网关路由，已确认 API 网关**剥离外部不可信头**且**禁止对外转发领域服务内部路径**（按画像 P-5）
- [ ] 单服务集成测试（若有）在本服务 `src/test/java/`，归 `integration-test-design` 编写

---

## 6. 契约 / 详设同步（整改或路径变更时）

- [ ] 仅改**当前 Story** 的对外/内部 OpenAPI paths / examples / components
- [ ] 错误响应示例与失败 AC 文案一致（见 `openapi-conventions.md`）
- [ ] 详设 §5 path 与 Controller `@RequestMapping` 一致
- [ ] 共享 component 影响其他 operation → 阻断，先 `detail-design`

---

## 7. Story 范围验收

```bash
# 单仓库多服务（画像 P-1）
mvn test -pl {目标服务模块路径} -am
# 一服务一独立仓库（画像 P-1）
mvn test
```

- [ ] Story 关联测试全部通过
- [ ] 无新增 `@Disabled` / 删断言 / skip
- [ ] 实现汇总含 AC → 测试 → 实现追溯表
- [ ] 按 [test-quality.md](./test-quality.md) 命名与断言

---

## 8. 大文件 IO（详设命中上传/导出/ZIP 时）

- [ ] 上传：`InputStream` 分块读取；无 `getBytes()` / `readAllBytes()`
- [ ] 上传：`spring.servlet.multipart.max-file-size` 与业务层二次校验一致
- [ ] ZIP：逐 entry + 路径校验（防 Zip Slip）；临时文件 `finally` 清理
- [ ] 导出：keyset 分批查询；无全表一次性加载
- [ ] 下载：BFF `StreamingResponseBody` / `InputStreamResource`；无 `byte[]` 全量响应
- [ ] 大数据量（>10,000 条）：异步任务 + `task_id`，非同步全量 HTTP

详见 [memory-safe-io-guide.md](../../../reference/memory-safe-io-guide.md)、`rules/memory-safe-io.md`。

---

## 9. 常见反模式（禁止）

| 反模式 | 正确做法 |
|--------|----------|
| BFF 或其他服务直接依赖 `*-impl` 内部类或表 | 通过 `*-api` 远程契约调用（按画像 P-2） |
| 把跨服务远程调用包进本地 `@Transactional` | 本地事务仅限单服务单库；跨服务写按画像 E-3 选型 |
| BFF 与领域微服务各建 `{Domain}Normalizer` 等同职责类 | 算法仅归属领域服务一处；guard 在 BFF |
| 将领域服务内部路径暴露到公网 API 网关 | 按画像 P-5 做好隔离与内部鉴权 |
| Service 单测连真实 DB 或真实下游服务 | Mock 持久化层与远程客户端 |
| 跨服务 SQL JOIN 或跨服务外键 | 严禁；经远程接口或本服务异步冗余副本获取 |
| 在画像 §5.4 `[TBD]` 项未拍板时擅自猜测中间件写法 | 阻断提问，拍板回写画像后再编码 |
