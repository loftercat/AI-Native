# 单元测试质量约定（Java）

> 对应公司级 `unit-test-quality`（公司级示例）。与 `rules/tdd-project-conventions.md` 互补：Rule 管原则，本文管可执行检查项。

## 命名与追溯

- 测试类：`{被测类名}Test`（如 `{Entity}QueryServiceTest`、`{Entity}CommandServiceTest`、`{Resource}ControllerTest`），与 `src/main/java` 包路径镜像
- `@DisplayName` 或方法注释标明 `STORY-{迭代}-{序号} AC-n`
- 一条测试方法覆盖一个可判定行为（对齐单条 AC 或 BR 边界）

## 结构与可读性

```java
// Given — When — Then 用空行或注释分段
@Test
@DisplayName("STORY-{迭代}-{序号} AC-06: 条件不满足时抛出对应领域错误码")
void execute_whenPreconditionUnsatisfied_throwsBizException() {
    // given
    when(mapper.selectAvailable(...)).thenReturn(List.of());
    // when / then
    {BizException} ex = assertThrows({BizException}.class, () -> service.execute(req));
    assertEquals({Domain}ErrorCode.{ERR_ENUM}.getCode(), ex.getCode());
}
```

## Mock 边界

| 层 | Mock 什么 | 不 Mock 什么 |
|----|-----------|--------------|
| `{Entity}QueryServiceTest` / `{Entity}CommandServiceTest` | 持久化层、`{Domain}Client`、`{External}Client` | 被测 Service 自身逻辑 |
| `{Resource}ControllerTest` | 下游 `{Domain}Client` 或 Service | Controller 守卫与序列化 |
| 单服务集成测试 `{Scenario}IT` | 进程外下游微服务（WireMock/Stub）、外部系统 `{External}Client` | 本服务完整入口 + 业务 + 真实容器 DB |

## 断言要求

- BFF：`MockMvc` + `jsonPath`；失败类 AC 断言错误文案字段（全文或关键子串）
- Service：`{BizException}` 的错误码与文案；禁止只断言 `Exception` 类型
- 成功路径：按画像 §3.7（P-4）约定断言（如统一包装体 `{Result<T>}` 断言业务成功码，HTTP 状态码模式断言对应 `2xx`）

## 禁止

- `@Disabled` / 删断言 / 注释掉断言使 Story 范围变绿
- 测试依赖执行顺序（除明确 `@Order` 的集成场景）
- Service 测试启动真实 DB 或全量 Spring（除非 `@SpringBootTest` 集成 Story）
- 断言实现细节（如 Mock Mapper 被调用次数）代替业务结果 — 除非 AC 明确要求

## 前端-only AC

测试类文件头注释：

```java
/**
 * N/A backend — 前端另仓
 * STORY-{迭代}-{序号} AC-0x（纯前端展示 / 交互组件）
 */
```

## 增量 TDD 六分支（摘要）

1. 绿测 + AC 未变 → 保留  
2. 红测 + AC 未变 → 修实现  
3. 红测 + AC 已变 → 先改测再改实现  
4. 无覆盖 → 先红后绿  
5. 有实现无追溯 → 补 DisplayName，不重写逻辑  
6. 废弃 AC → 删/改用例，禁止长期 `@Disabled`  

完整流程见 `../SKILL.md` 步骤 6。
