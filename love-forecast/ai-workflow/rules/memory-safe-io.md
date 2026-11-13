# 内存安全 IO

涉及文件上传、导入、导出、ZIP、大文件下载时，先读 [docs/reference/memory-safe-io-guide.md](../reference/memory-safe-io-guide.md)。

## 必守

1. **禁止全量读入内存**：`MultipartFile.getBytes()`、`Files.readAllBytes()`、`IOUtils.toByteArray()`、无 `LIMIT` 的全表 `selectList`
2. **上传分块**：`InputStream` + 固定 `byte[]` buffer（默认 1 MB）；累计大小超过 Story/配置上限 → `BizException`
3. **导出分批**：Mapper XML 提供 `selectAfterId(lastId, limit, ...)` keyset 查询；默认 batch 200
4. **HTTP 下载流式**：BFF 用 `StreamingResponseBody` 或 `InputStreamResource`；**禁止** `byte[]` 一次性响应
5. **ZIP 安全**：逐 entry 读取；校验路径不含 `..`、不以 `/` 开头；**禁止** Zip Slip
6. **分层**：`MultipartFile` 只在 BFF；域层接收 `InputStream` 或已落盘 `Path`；HTTP 只在 `love-app`

## 默认阈值（Story 未指定时标 `[AI推断]`）

| 参数 | 默认 |
|------|------|
| 单文件上传上限 | 50 MB |
| `CHUNK_SIZE` | 1 MB |
| 导出 batch | 200 |
| 同步导出条数上限 | 10,000 |

## 同步 vs 异步

- ≤ 10,000 条且单条较小 → 同步流式 HTTP
- 更大或含大附件 → 异步导出任务 + `task_id` + 完成后下载

## 反模式

```java
// ❌ 全量读上传
byte[] data = file.getBytes();

// ❌ 全量查库导出
List<OrderDO> all = orderMapper.selectAll();

// ❌ 全量读文件响应
return ResponseEntity.ok(Files.readAllBytes(path));

// ❌ 内存 ZIP
ZipInputStream zis = new ZipInputStream(new ByteArrayInputStream(file.getBytes()));
```

```java
// ✅ 分块落盘
try (InputStream in = new BufferedInputStream(file.getInputStream())) { ... }

// ✅ keyset 分批
List<OrderDO> batch = orderMapper.selectAfterId(lastId, 200, filter);

// ✅ 流式下载
StreamingResponseBody body = out -> { try (InputStream in = Files.newInputStream(path)) { ... } };
```
