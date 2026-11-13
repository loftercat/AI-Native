# 内存安全 IO 实践指南（Java）

> **L1 静态层上下文资产**：`detail-design` 步骤 6 在 AC/BR 出现文件上传、导入、导出、ZIP、附件、大文件下载等关键词时加载本指南。  
> **本仓库 V1**：单体 `love-app`；HTTP 在 `love-app`；业务在 `*-impl` Service；详见 [system-landscape.md](../architecture/system-landscape.md)。

---

## 一、为什么需要内存安全 IO

OOM（Out Of Memory）常见于两类写法：

| 场景 | 高风险写法 | 后果 |
|------|-----------|------|
| 文件上传/导入 | `multipartFile.getBytes()` / `IOUtils.toByteArray(is)` 全量读入 | 大文件撑爆堆内存 |
| 批量导出 | `selectList` 无分页全量查库再写文件 | 数据量大时内存与 GC 压力剧增 |

**核心原则**：控制内存峰值 —— 加载一部分、处理一部分、释放一部分，不在内存中保留全量数据。

---

## 二、适用场景

| 场景 | 触发特征 | 典型业务（源项目示例） |
|------|---------|---------------------|
| 文件上传 | AC 含上传、导入、附件 | 运营批量导入车位规则、凭证附件 |
| 批量导出 | AC 含导出、下载、报表 | Admin 预约单 CSV、对账明细 |
| 大文件下载 | AC 含下载、预览 | 日志导出、导出包下载 |
| ZIP 处理 | AC 含 ZIP、压缩包、manifest | 批量导入配置包 |

---

## 三、决策树：同步流式 vs 异步任务

```text
涉及导出/下载
    │
    ├── 预估结果集 ≤ 10,000 条 且 单条较小
    │     → 同步 HTTP + 流式响应（StreamingResponseBody / Resource）
    │
    └── 预估结果集 > 10,000 条 或 单条较大（含附件/ZIP）
          → 异步导出任务
          → 写对象存储 / 临时目录
          → 返回 task_id + 完成后下载链接
```

上传侧无论大小，**均禁止无上限全量 read**；超过配置上限直接拒绝。

---

## 四、本仓库分层落点

```text
love-app   接收 MultipartFile、流式下载 ResponseEntity
*-impl/app/service/                   流式读写、ZIP 解析、导出编排
*-impl/infrastructure/mapper/         keyset 分批查询（XML）
love-app/application.yml           multipart 大小上限
```

| 层 | 职责 |
|----|------|
| **BFF Controller** | 接收 `MultipartFile`、校验 Content-Type/大小、调用 `XxxApi` 或 Facade；大文件下载返回 `StreamingResponseBody` |
| **Service** | 编排流式读取、解析逻辑、分批写文件、错误汇总 |
| **Mapper + XML** | keyset 分批查询（`selectAfterId`）；**禁止**无 `LIMIT` 的全量 `selectList` |
| **`*-api`** | 导出任务 DTO、错误码；**不**暴露 `MultipartFile` |

**禁止**：

- BFF 内 `getBytes()` 后把 `byte[]` 传给域层
- Service 一次性 `List<DO>` 加载全表再写文件
- 在 `*-impl` 写 `@RestController` 处理上传（HTTP 只在 BFF）

---

## 五、文件上传 / 导入

### 5.1 Spring 配置上限

```yaml
# love-app/src/main/resources/application.yml
spring:
  servlet:
    multipart:
      max-file-size: 50MB      # 单文件上限，Story BR 可覆盖
      max-request-size: 55MB   # 略大于 max-file-size
```

超过上限由 Spring 拦截；业务层仍须在 Service **二次校验**累计读取量（防绕过或分块上传）。

### 5.2 分块流式落盘（BFF → Service）

```java
// love-app/.../ImportController.java
@PostMapping(value = "/imports", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
public Result<ImportTaskDTO> upload(@RequestPart("file") MultipartFile file) {
    importApi.submitImport(file.getOriginalFilename(), file.getContentType(), file.getInputStream());
    return Result.success(...);
}

// advice-impl/.../ImportService.java
public static final int CHUNK_SIZE = 1024 * 1024;           // 1 MB
public static final long MAX_UPLOAD_SIZE = 50L * 1024 * 1024; // 50 MB

public void saveUploadStreaming(InputStream in, Path destPath) throws IOException {
    long total = 0;
  try (InputStream input = new BufferedInputStream(in);
         OutputStream out = Files.newOutputStream(destPath, CREATE, TRUNCATE_EXISTING)) {
        byte[] buffer = new byte[CHUNK_SIZE];
        int read;
        while ((read = input.read(buffer)) != -1) {
            total += read;
            if (total > MAX_UPLOAD_SIZE) {
                throw new BizException(AdviceErrorCode.FILE_TOO_LARGE);
            }
            out.write(buffer, 0, read);
        }
    }
}
```

> **注意**：`MultipartFile.getInputStream()` 由 Spring 管理生命周期；Service 内须在 `try-with-resources` 中读完，勿缓存 InputStream 跨请求使用。

### 5.3 ZIP 导入

**禁止**：

- `new ZipInputStream(new ByteArrayInputStream(file.getBytes()))` — 全量 bytes 在内存
- `zip.extractAll(path)` 不校验 entry 路径 — 路径穿越（Zip Slip）+ 磁盘/内存不可控
- `Files.readAllBytes(zipPath)` 后整包解析

**推荐**：

1. 流式或分块落**临时文件**（`Files.createTempFile`）
2. 用 `ZipFile`（基于 `Path`）或 `ZipInputStream` **逐 entry** 读取
3. 校验 entry 名：不含 `..`、不以 `/` 开头、规范化后须在目标目录内
4. `finally` 删除临时文件

```java
public void processZipEntries(Path zipPath, Consumer<ZipEntryChunk> chunkHandler) throws IOException {
    try (ZipFile zipFile = new ZipFile(zipPath.toFile())) {
        Enumeration<? extends ZipEntry> entries = zipFile.entries();
        while (entries.hasMoreElements()) {
            ZipEntry entry = entries.nextElement();
            String name = entry.getName();
            if (name.contains("..") || name.startsWith("/") || name.startsWith("\\")) {
                throw new BizException(ErrorCode.PARAM_ERROR);
            }
            try (InputStream entryIn = new BufferedInputStream(zipFile.getInputStream(entry))) {
                byte[] buffer = new byte[CHUNK_SIZE];
                int read;
                while ((read = entryIn.read(buffer)) != -1) {
                    chunkHandler.accept(new ZipEntryChunk(name, buffer, read));
                }
            }
        }
    }
}
```

---

## 六、批量导出

### 6.1 游标分批（keyset，推荐）

与 [scheduled-task-guide.md](./scheduled-task-guide.md) 的 checkpoint 模式一致，使用稳定排序键（自增 `id` / `created_at, id`）：

```java
// advice-impl/.../ExportService.java
private static final int EXPORT_BATCH_SIZE = 200;

public void exportOrdersToCsv(Path csvPath, ExportFilter filter) throws IOException {
    long lastId = 0L;
    try (BufferedWriter writer = Files.newBufferedWriter(csvPath, StandardCharsets.UTF_8)) {
        writer.write("id,status,created_at\n");
        while (true) {
            List<BookingOrderDO> batch = orderMapper.selectAfterId(lastId, EXPORT_BATCH_SIZE, filter);
            if (batch.isEmpty()) {
                break;
            }
            for (BookingOrderDO order : batch) {
                writer.write(order.getId() + "," + order.getStatus() + "," + order.getCreatedAt() + "\n");
                lastId = order.getId();
            }
        }
    }
}
```

Mapper XML（**禁止**注解 SQL）：

```xml
<select id="selectAfterId" resultType="...BookingOrderDO">
  SELECT id, status, created_at
  FROM booking_order
  WHERE id &gt; #{lastId}
    <!-- 可选 filter 条件 -->
  ORDER BY id ASC
  LIMIT #{limit}
</select>
```

Repository/Mapper 须提供 `selectAfterId(lastId, limit, filter)`，**不要**用 `OFFSET` 深分页导出大数据集。

### 6.2 按格式流式写入

| 格式 | 推荐方式 |
|------|---------|
| CSV | `BufferedWriter` 逐行 `write`，不先 `StringBuilder` 拼全量 |
| JSON Lines | 每行 `objectMapper.writeValueAsString(record) + "\n"` 写入 |
| ZIP | `ZipOutputStream` 包在 `OutputStream` 外，`putNextEntry` 逐 entry 追加 |
| Excel | 数据量大时优先 CSV 或异步任务；小量可用 Apache POI `SXSSFWorkbook`（窗口行数如 100） |

### 6.3 HTTP 流式下载（BFF）

```java
@GetMapping("/exports/{taskId}/download")
public ResponseEntity<StreamingResponseBody> download(@PathVariable String taskId) {
    Path path = exportService.resolveResultPath(taskId);
    StreamingResponseBody body = outputStream -> {
        try (InputStream in = Files.newInputStream(path)) {
            byte[] buffer = new byte[CHUNK_SIZE];
            int read;
            while ((read = in.read(buffer)) != -1) {
                outputStream.write(buffer, 0, read);
            }
        }
    };
    return ResponseEntity.ok()
            .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"export.zip\"")
            .contentType(MediaType.APPLICATION_OCTET_STREAM)
            .body(body);
}
```

**禁止**：`Files.readAllBytes(path)` 或 `byte[] content = ...` 后一次性 `ResponseEntity.ok(content)`。

小文件也可用 `InputStreamResource` + `Content-Length`（仍须 `InputStream`，非 `byte[]`）。

### 6.4 异步导出任务（大数据量）

预估 > 10,000 条时：

1. `POST /exports` → 创建任务，返回 `task_id`
2. 后台 Job（`@Scheduled` 或异步执行器）分批查询 + 写文件 + 上传对象存储（V2+）
3. `GET /exports/{task_id}` → 查询进度 / 下载 URL
4. 设置文件过期时间，定时清理（见 scheduled-task-guide）

详设须定义 `export_task` 表（或复用通用异步任务表）：`status`、`progress`、`file_path`、`expire_at`。

---

## 七、默认阈值

| 参数 | 默认值 | 覆盖方式 |
|------|--------|----------|
| 上传单文件上限 | 50 MB | Story BR / `application.yml` |
| 分块大小 `CHUNK_SIZE` | 1 MB | 常量 |
| 导出分批 `limit` | 200 | Story / 常量 |
| 同步导出上限 | 10,000 条 | Story / 配置项 |

详设中若使用默认值，标注 `[AI推断]`；产品明确上限时在 BR 中写死。

---

## 八、与现有规范的关系

| 规范 | 关系 |
|------|------|
| [rules/../rules/memory-safe-io.md?no | 编码硬约束（禁止项 + 模板） |
| [rules/../rules/mybatis-conventions.md?no | 导出分批 SQL 写在 XML；提供 keyset 方法 |
| [rules/../rules/java-project.md?no | 上传/下载 HTTP 只在 BFF；域 `XxxApi` 用 `InputStream` / 路径 DTO |
| [rules/../rules/exception-and-result.md?no | 超限抛 `BizException` + 域错误码 |
| [scheduled-task-guide.md](./scheduled-task-guide.md) | 定时批处理、异步导出清理同样适用 `selectAfterId + limit` |

---

## 九、详设产出要点

涉及上传/导出时，详设「专项设计」章节须包含：

| 项 | 说明 |
|----|------|
| 上传/导出方式 | 流式 / 分批 / 异步任务 |
| 大小/条数上限 | 单文件 MB、同步导出条数 |
| 分批参数 | `limit`、排序键 |
| 临时文件 | 存放位置（`java.io.tmpdir` / 配置目录）、清理策略 |
| 失败处理 | 超限错误码、部分失败是否保留已写数据 |
| §8 类清单 | `ImportController`、`ExportService`、`selectAfterId` Mapper 方法 |

---

## 十、PR Review / feature-coding Checklist

- [ ] 是否存在无上限的 `getBytes()` / `readAllBytes()` / `IOUtils.toByteArray()` / 无 `LIMIT` 全量查询？
- [ ] 上传是否分块读取并有大小上限校验（配置 + 业务层）？
- [ ] ZIP 是否逐 entry 处理并校验路径（防 Zip Slip）？
- [ ] 导出是否 keyset 分批加载 + 流式写入？
- [ ] 大数据量是否走异步任务而非同步全量响应？
- [ ] 临时文件是否在 `finally` / `try-with-resources` 中清理？
- [ ] BFF 是否用 `StreamingResponseBody` / `InputStream`，而非 `byte[]`？

---

## 十一、与公司级 Python 指南的差异

| Python Demo | 本仓库 Java |
|-------------|-------------|
| `UploadFile` + `async read(CHUNK_SIZE)` | `MultipartFile.getInputStream()` + `BufferedInputStream` |
| `StreamingResponse` + 生成器 | `ResponseEntity<StreamingResponseBody>` |
| `zipfile.ZipFile` + `writestr` | `java.util.zip.ZipFile` / `ZipOutputStream` |
| `find_after_id` async Repository | MyBatis XML `selectAfterId` + `LIMIT` |
| FastAPI 路由 | `love-app` Controller；业务在 `*-impl` Service |

---

## 延伸阅读

- [special-scenarios.md](../skills/detail-design/references/special-scenarios.md) — 关键词识别
- [scheduled-task-guide.md](./scheduled-task-guide.md) — 分批与 checkpoint
- [implementation-checklist.md](../skills/feature-coding/references/implementation-checklist.md) — 编码阶段勾选
