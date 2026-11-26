# 异常处理与响应封装（微服务版）

> **选型驱动原则**：本规则只固化**与具体包装方式无关的通用异常纪律**；项目的对外/对内返回格式、跨服务错误码传递策略（透传 vs 映射）、公共基础库坐标与微服务错误码号段，一律以 [system-landscape.md](../architecture/system-landscape.md) §3.7（及 §5.4 **P-4**）为准。若画像 P-4 仍为 `[TBD]`，详设与编码前须阻断请用户拍板。

## 一、通用异常纪律（必守，不随选型变化）

1. **错误码必须按微服务号段归口枚举**：各领域服务在自己的 `*-api` 定义 `{Domain}ErrorCode` 枚举（号段见画像 §3.7）；入口守卫错误码放公共横切模块；**禁止**在代码里硬编码 magic number 或用纯字符串代替业务错误码。
2. **禁止入口层吞异常**：Controller / 内部远程入口**不写** `try/catch (BizException)` 手动拼装失败响应，统一交由全局异常处理器或协议拦截器处理。
3. **不重复造公共基础库轮子**：项目已引入统一公共基础库（见画像 §3.7 公共基础库锚点）时，严禁在各微服务或 `{project}-common` 里重复定义同名响应体、异常类或全局异常处理器。
4. **错误文案与 Story AC 对齐**：失败类 AC 中写明的用户可见提示文案，必须与对应错误码枚举的默认文案或转换规则保持一致。
5. **跨服务异常传播边界**：
   - 调用下游微服务（协议见画像 §5.4 P-2）时，必须在统一客户端解包/拦截层（如 `ErrorDecoder` / RPC Filter）处理下游失败响应，**不得**在业务 Service 中到处散落手工拆解 HTTP 状态码或 JSON 错误体；
   - 下游错误码是**原样透传**还是**映射为上游服务错误码**，以及内部接口是否与对外接口共用同一包装体，严格按画像 §3.7（P-4）结论执行；
   - 网络超时、连接失败、5xx 等不可用故障须归入远程调用失败类错误（如 `REMOTE_SERVICE_ERROR`），不得伪装成业务成功。

## 二、模块依赖原则（微服务独立启动）

- 每个独立启动的服务模块（各 BFF 与各领域服务 `*-impl`）均须引入 Web / 协议异常处理依赖（确保各自的全局异常处理与远程解包组件独立生效）。
- 各 `*-api` 契约模块仅引入最轻量的核心依赖（错误码接口、分页/响应契约），不引入 Web 容器或数据库依赖。

---

## 三、项目实现速查（接入时按画像 §3.7 填写）

> **接入动作**：按 [common-foundation-migration.md](../docs/methodology/common-foundation-migration.md) 把本项目真实公共基础库（或自建封装）的坐标、响应体、异常、分页与号段填入本节，供 AI 编码直接照抄、防止造同名轮子。

### 依赖坐标与包根

| 能力 | 依赖坐标 | 包根 |
|------|----------|------|
| 核心契约（响应 / 异常 / 分页） | `{groupId}:{common-core}` | `{com.company.common.core.*}` |
| Web / 协议异常处理与解包 | `{groupId}:{common-web}` | `{com.company.common.web.*}` |

### 最小代码形态示意

```java
// ✅ 对外 BFF Controller：按画像 §3.7 响应形态返回，异常上浮给全局处理器
@PostMapping("/{resource}")
public {Result}<{Entity}VO> handle(@Valid @RequestBody {Action}Request req) {
    return {Result}.success(toVo({domainClient}.{action}(req)));
}

// ✅ 领域服务：抛归属服务错误码枚举
throw new {BizException}({Domain}ErrorCode.{BIZ_ERROR});

// ❌ 禁止在 Controller try/catch 后手动拼装失败响应
// ❌ 禁止硬编码数字错误码或自造同名响应/异常类
```

### 微服务错误码号段与核心 API 速查

| 项 | 填写内容（对齐画像 §3.7） |
|----|--------------------------|
| 系统级错误码 | `{SystemErrorCode}`（位置与常见枚举值） |
| 入口守卫错误码 | `{GuardErrorCode}`（放 `{project}-common`） |
| 各领域服务错误码号段 | 见画像 §3.7 号段表（每个领域放各自 `{domain}-api`） |
| 统一响应体 API | `{Result.success / fail / isSuccess 签名与成功判据}` |
| 业务异常构造器 | `{BizException 构造器清单}` |
| 分页对象 | `{PageQuery / PageResult 签名}` |
| 主键生成器（若适用） | `{IdGenerator 签名，按画像 §5.4 P-3}` |

完整实践说明见 [reference/exception-and-result.md](../reference/exception-and-result.md)。
