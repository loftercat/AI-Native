# 功能编码实现检查清单（Java）

> 执行 Skill：`../SKILL.md`  
> 每层实现与测试完成后勾选；阻断项未解除不得进入下一层。

---

## 0. 开工前（步骤 1～4）

- [ ] Story 编号、AC/BR、变更记录已读
- [ ] 详设 §8 代码骨架 / AC→追溯表已读
- [ ] 缺口清单已输出（阻断 / 整改 / 可补充）
- [ ] 模块终判与 Story「服务/模块」一致
- [ ] OpenAPI 当前 Story operation 与详设 §5 对齐（含 HTTP 时）
- [ ] 错误码号段符合 `rules/exception-and-result.md`（order 1500–1549、payment 1550–1599、inventory 1600–1699、adapter 1700–1799、push 1800–1899、iot 1900–1999）

---

## 1. 持久化层（`*-impl/infrastructure/`，详设 §6 要求时）

### 实现

- [ ] DO 字段与 `docs/schema/{服务}/schema.md`（含 DDL）或详设 §6 一致（含 `deleted` / `deletedAt`）
- [ ] Flyway：`docs/schema/{服务}/ddl/V{序号}__{Story}.sql` 已落盘到 `booking-app/src/main/resources/db/migration/`；主键 **无** `AUTO_INCREMENT`；**禁止修改已合并的** `V{n}__*.sql`
- [ ] Mapper 测试 schema（涉及 `order-impl` / `inventory-impl` 表时）：落盘 Flyway 后执行 `scripts/sync-mapper-schema-from-flyway.sh order|inventory|all`（需 Docker，**推荐**）；或手工维护 `*-impl/src/test/resources/schema.sql` 与 Flyway 结果逐表同构
- [ ] Mapper 接口仅声明方法；**非主键查询 SQL 写在 XML**；条件查询含 `deleted = 0`
- [ ] 主键 `selectById` 可用 MyBatis Plus `BaseMapper`（见 `rules/mybatis-conventions.md`）
- [ ] 新建写入：`SnowflakeIdGenerator.nextId()` → `setId` → `insert`（`com.hema:common-core:${hema-common.version}`）
- [ ] 业务删除走 XML 软删，**不用** `deleteById`
- [ ] XML `namespace` 与 Mapper 接口全限定名一致

### 测试

- [ ] 默认 **不在** Service 测试外单独测 Mapper（复杂 SQL 可 `@MybatisTest`，按需）
- [ ] Service 层用 Mock Mapper 覆盖 AC

---

## 2. 域契约层（`*-api/`）

### 实现

- [ ] `XxxApi` 仅接口 + DTO/枚举，**无实现、无 Spring 注解业务逻辑**
- [ ] DTO 命名与详设 §8.3 一致；请求/响应分离
- [ ] 域错误码枚举（如 `InventoryErrorCode`）含 code + 默认 message
- [ ] BFF 守卫错误码使用 `booking-common` 的 `BookingErrorCode`；系统级用 `hema-common` `ErrorCode`
- [ ] 跨域类型不泄漏 BFF VO

### 测试

- [ ] 本层通常无独立测试；由 impl Service 测试覆盖

---

## 3. 域实现层（`*-impl/`）

### 实现

- [ ] `XxxApiImpl`（`app/provider/`）薄委托 → Facade
- [ ] Facade 编排；**核心状态机在 Service / 可选贫血 domain**，不在 BFF
- [ ] **领域厚度**按详设 §4.4：薄 Story 用 Service+DO+DTO；复杂可选 `domain/model`（贫血）
- [ ] **状态迁移落库**：Mapper XML **条件 `UPDATE`**（`WHERE status=?`）；`affected_rows=0` → `BizException`；**非**默认 `updateById` 全量 save
- [ ] DO↔DTO 经 `infrastructure/converter` **MapStruct**（或详设已列的 `*Converter`）；**禁止** Service 内大段字段 builder 拷贝
- [ ] Service 抛 `BizException` + 域错误码，不吞异常
- [ ] 跨域仅通过 `app/client` 注入其它 `XxxApi`；**V1 不用 OpenFeign**
- [ ] 车场厂商 API **仅** `booking-parking-adapter`；order/inventory 用 `ParkingLotGateway`
- [ ] 支付 **仅** `order-impl` `PaymentClient`
- [ ] **事务注解核对**：详设 §8.3 标注 `@Transactional` 的方法（或职责列含「事务编排」的多步写 Facade/CommandService）实现已加 `@Transactional`；外部调用（支付/车场）与事务的关系与 §1.3 ADR 一致
- [ ] **`*-impl` 无 Controller**

### 测试（`*-impl/src/test/java/`）

- [ ] `*ServiceTest`：JUnit 5 + Mockito；Mock Mapper / Client / 其它 `XxxApi`
- [ ] 覆盖 Story BR 边界（详设 §9）
- [ ] 断言 `BizException` 的 code 与 message（对齐 AC）
- [ ] 不启动 Spring 容器（除非 `@SpringBootTest` 集成场景）

---

## 4. BFF 层（`booking-bff-app` / `booking-bff-admin`）

### 实现

- [ ] Controller 仅：鉴权上下文、**守卫**（空参/格式）、`@Autowired XxxApi`、组装 `Result<T>`
- [ ] DTO↔VO 经 `bff.*.converter` **MapStruct**；**禁止** Controller 内手写字段映射
- [ ] **禁止**在 BFF 实现 normalize、分词、匹配、推荐、状态机、库存锁定
- [ ] **禁止**BFF 与 `*-impl` 各建同职责工具类；详设 §8 重复时**阻断**并回溯 detail-design
- [ ] URL 前缀：App `/api/v1/booking/app/`；Admin `/api/v1/booking/admin/`
- [ ] 统一 `com.hema.common.core.result.Result<T>`；**业务成功 `code === 200`**
- [ ] `@Valid` 请求体；校验失败由 `hema-common` 全局处理
- [ ] **禁止**在 BFF 写预约状态机、库存锁定核心逻辑
- [ ] Controller 类/公开方法有**中文 JavaDoc**；`@Tag` + `@Operation(summary, description)`，对齐 OpenAPI YAML
- [ ] 需登录接口有 `@SecurityRequirement(name = "bearerAuth")`（与 YAML 一致）
- [ ] 请求/响应 VO 字段有中文 `@Schema(description)`
- [ ] 模块依赖 `io.swagger.core.v3:swagger-annotations-jakarta`（见 layer-guides §5.1）

### 测试（`booking-bff-*/src/test/java/`）

- [ ] `@WebMvcTest(controllers = XxxController.class)` + MockMvc
- [ ] Mock 域 `XxxApi`，不 Mock Mapper
- [ ] 断言 HTTP 状态、`jsonPath("$.code")`、`jsonPath("$.message")`、`$.data` 关键字段
- [ ] 失败类 AC 对齐 Story 可见文案

---

## 5. 启动与聚合（`booking-app/`，按需）

- [ ] `{项目}/pom.xml` 聚合本 Story 涉及的 `*-impl`、BFF 模块
- [ ] 含 HTTP 时引入 `springdoc-openapi-starter-webmvc-ui`（Swagger UI）
- [ ] 不新增第二个 `@SpringBootApplication`
- [ ] 集成测试（若有）在 `booking-app/src/test/java/`，Mock 外部支付/车场

---

## 6. OpenAPI / 详设同步（整改或路径变更时）

- [ ] 仅改**当前 Story** 的 paths / examples / components
- [ ] `BusinessErrorBody` 与失败 AC 文案一致（见 `openapi-conventions.md`）
- [ ] 详设 §5 path 与 Controller `@RequestMapping` 一致
- [ ] 共享 component 影响其他 operation → 阻断，先 detail-design

---

## 7. Story 范围验收

```bash
mvn test -pl {模块列表} -am
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
- [ ] 导出：Mapper XML `selectAfterId` keyset 分批；无全表 `selectList`
- [ ] 下载：BFF `StreamingResponseBody` / `InputStreamResource`；无 `byte[]` 全量响应
- [ ] 大数据量（>10,000 条）：异步任务 + `task_id`，非同步全量 HTTP

详见 [memory-safe-io-guide.md](../../../reference/memory-safe-io-guide.md)、`rules/memory-safe-io.md`。

---

## 9. 常见反模式（禁止）

| 反模式 | 正确做法 |
|--------|----------|
| BFF 直接注入 `*Mapper` / `*Service`（impl 内部） | 注入 `XxxApi` |
| BFF 与 impl 各建 `KeywordNormalizer` 等同职责类 | 算法仅 domain 一处；guard 用 `isBlank` 在 Controller |
| `*-impl` 写 `@RestController` | HTTP 只在 BFF |
| Service 测试连真实 DB | Mock Mapper |
| `@WebMvcTest` 启动全量 `booking-app` | 只加载目标 Controller |
| 业务成功 `code === 0` | `code === 200`（hema-common） |
| 注解 SQL 写复杂查询 | XML Mapper |
