# 内存安全 IO 实践指南（Java 微服务）

> **L1 静态层上下文资产**：`detail-design` 步骤 6 在 AC/BR 出现文件上传、导入、导出、ZIP、附件、大文件下载等关键词时加载本指南。
> **微服务分层**：对外文件上传/下载入口在对应 BFF 服务（各自独立配置 `multipart` 上限，并与 API 网关请求体上限对齐）；业务解析与分批查询在归属领域微服务 `*-impl`；详见 [system-landscape.md](../architecture/system-landscape.md)。

---

## 一、为什么需要内存安全 IO

OOM（Out Of Memory）常见于两类写法：

| 场景 | 高风险写法 | 后果 |
|------|-----------|------|
| 文件上传/导入 | `multipartFile.getBytes()` / `IOUtils.toByteArray(is)` 全量读入 | 大文件撑爆堆内存 |
| 批量导出 | 无分页全量查库再写文件 | 数据量大时内存与 GC 压力剧增 |

**核心原则**：控制内存峰值 —— 加载一部分、处理一部分、释放一部分，不在内存中保留全量数据。

---

## 二、决策树：同步流式 vs 异步任务

```text
涉及导出/下载
    │
    ├── 预估结果集 ≤ 10,000 条 且 单条较小
    │     → 同步 HTTP + 流式响应（StreamingResponseBody / InputStreamResource）
    │
    └── 预估结果集 > 10,000 条 或 单条较大（含附件/ZIP）
          → 异步导出任务
          → 分批查询写对象存储 / 临时目录
          → 返回 task_id + 完成后下载链接
```

上传侧无论大小，**均禁止无上限全量 read**；超过配置上限直接拒绝。

---

## 三、微服务分层落点

```text
{project}-gateway（可选）   配置网关层最大请求体限制
{project}-bff-*             接收 MultipartFile、流式下载 ResponseEntity（各自配 multipart 上限）
{domain}-impl/app/service/  流式读写、ZIP 解析、分批导出编排
{domain}-impl/infrastructure/ keyset 分批查询（按画像 §5.4 P-3 ORM）
```

| 层 | 职责 |
|----|------|
| **BFF Controller** | 接收 `MultipartFile`、校验 Content-Type/大小、流式转存对象存储/临时文件后传引用给领域服务；大文件下载返回 `StreamingResponseBody` |
| **领域 Service** | 编排流式读取、解析校验、分批写文件、错误汇总 |
| **持久化层** | keyset 分批查询（`selectAfterId`）；**禁止**无 `LIMIT` 的全量加载 |
| **`*-api`** | 导出任务 DTO、文件引用与错误码；**不**暴露 `MultipartFile` 或大 `byte[]` |

**禁止**：
- BFF 内 `getBytes()` 后把 `byte[]` 经远程调用传给领域微服务
- Service 一次性加载全表再写文件
- 将领域服务大文件内部入口直接暴露到公网 API 网关

---

## 四、关键实现约束

1. **上传上限双重校验**：BFF `application.yml` 配置 `spring.servlet.multipart.max-file-size`（默认 50MB），业务流读取时仍按 `CHUNK_SIZE`（默认 1MB）累计字节数做二次拦截。
2. **ZIP 防 Zip Slip**：逐 entry 读取，将目标路径 `normalize()` 后校验必须以解压根目录为前缀，严禁包含 `..`；限制总解压体积防 ZIP 炸弹；临时目录在 `finally` 块强制清理。
3. **导出 keyset 分批**：按主键递增 `WHERE id > #{lastId} ... ORDER BY id ASC LIMIT #{batchSize}`（默认 200），边查边 flush 到输出流，不把结果集留在内存列表。
4. **下载流式输出**：BFF 使用 `StreamingResponseBody` 或 `InputStreamResource`，显式设置 `Content-Disposition` 与 `Content-Type`。
