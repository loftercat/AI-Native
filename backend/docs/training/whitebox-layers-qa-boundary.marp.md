---
marp: true
theme: default
paginate: false
size: 16:9
header: ''
footer: ''
style: |
  section { font-size: 16px; padding: 24px 38px 18px; }
  h1 { color: #1E3A8A; font-size: 32px; margin: 0 0 6px; line-height: 1.1; }
  h2 { font-size: 18px; color: #1E40AF; margin: 10px 0 5px; border-bottom: 1px solid #E2E8F0; padding-bottom: 4px; }
  table { font-size: 15px; line-height: 1.38; margin: 5px 0; }
  th { background: #F1F5F9; }
  code { background: #F1F5F9; font-size: 14px; padding: 0 3px; }
  ol { margin: 8px 0 0; padding-left: 22px; line-height: 1.45; font-size: 16px; }
  ol li { margin: 5px 0; }
  strong { color: #0F172A; }
---

# 白盒自动化分层 × QA 验收边界

## 一、PR 阶段白盒分层定义（进程内 · CI 执行 · 覆盖粒度细、用例量大）

| 分层（技术标识） | 验证范围 | Mock 边界 | 测试边界限制 |
|:--|:--|:--|:--|
| **单元测试**<br>类名 *ServiceTest | 单方法：业务规则、分支、状态机 | 模拟数据访问层；跨系统 / 微服务调用 | 不加载 Web 任何组件，直接调用业务方法；无路由、拦截器、HTTP 请求等 Web 链路，数据访问层、跨系统调用等依赖全部 Mock，不访问任何数据库 |
| **BFF 接口测试**<br>`*ControllerTest` | 单 HTTP 接口：参数、401/403、返回 Result | Mock 业务领域层接口 | 加载 Web 最小上下文，内存仿真 HTTP 请求（无端口、无 TCP）；不调用真实业务服务，不连真实数据库 |
| **集成测试**<br>`*IT` | 单链路：BFF→领域→Mapper→测试 DB | 数据库存储不 Mock，使用测试数据库；仅 Mock 外部第三方系统 | 只测单链路，不做多业务串联 |
| **场景集成测试**<br>`*ScenarioIT` | 多 API 多步骤串联，进程内执行 | 同集成测试 | 进程内仿真，非完整部署环境 |
| **前端组件测试**<br>Vitest 组件测试（独立仓） | UI 渲染、前端工具逻辑 | Mock 接口、依赖注入 | 后端 PR 流水线不替代前端测试 |
| **（可选）持久层切片**<br>`@MybatisTest` | 复杂 SQL、Mapper 数据库映射 | MyBatis 最小上下文 | 仅校验 SQL 映射，不验证上层业务 |

## 二、研发白盒 × QA 验收用例 · 职责边界

1. **相同点**：用例同源，均基于 Story（AC/BR）与 OpenAPI，需求基线保持一致。
2. **差异点**：研发白盒自动化校验代码内部实现逻辑；QA 验收用例站在用户/业务交付视角，**仅编写业务场景摘要用例（Given-When-Then 场景描述）**，不写底层细粒度断言脚本。
3. **协作规则**：分层去重，白盒已全覆盖的 AC 场景，QA 直接引用 CI 成功结果作为验收凭证，不再重复开发等价自动化；仅 `manual` / 前端专属场景，由 QA 补充手工或 E2E 用例。
