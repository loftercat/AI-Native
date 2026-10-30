---
marp: true
theme: default
paginate: false
size: 16:9
header: ''
footer: ''
style: |
  section { font-size: 18px; padding: 14px 32px 10px; }
  h1 { color: #1E3A8A; font-size: 34px; margin: 0 0 4px; line-height: 1.1; }
  h2 { font-size: 20px; color: #1E40AF; margin: 6px 0 3px; border-bottom: 1px solid #E2E8F0; padding-bottom: 2px; }
  table { font-size: 16px; line-height: 1.32; margin: 2px 0; width: 100%; }
  th, td { padding: 4px 8px; }
  th:nth-child(2), td:nth-child(2) { white-space: nowrap; width: 1%; }
  th { background: #F1F5F9; }
  code { background: #F1F5F9; font-size: 14px; padding: 0 3px; }
  .funnel { font-size: 16px; line-height: 1.36; background: #F8FAFC; border-left: 3px solid #1E3A8A; padding: 6px 12px; margin: 4px 0; }
  strong { color: #0F172A; }
---

# 黑盒用例如何筛选

**输入**：Story（AC/BR）+ OpenAPI，与 **测试规格** 对齐防漏。  
**回归**：按 **变更影响面** 从回归库选子集；库可含历史 Story 沉淀路径，但须可追溯 Story/OpenAPI/矩阵。

## 筛选漏斗（全量 → 冒烟 / 回归 / 不进黑盒）

<div class="funnel">

**① 全量候选** = 本迭代 AC + Epic 主路径（链路级场景）+ 历史缺陷复现（典型 200～700 条意向）  
**② 剔除** → 白盒已细测、黑盒无部署态增量 → **不进黑盒**  
**③ 黑盒候选** → 真实 HTTP 端到端 / 跨进程或跨服务 / 真实第三方 / 用户可见 / 历史缺陷  
**④ 冒烟 5～15 条** → P0 主路径 + 横切检查（健康检查 + 各 BFF 未授权拦截）+ &lt;2 min  
**⑤ 回归** → 其余黑盒候选，**按本次变更影响面选集**（可数十～数百，非每次全量）

</div>

## 黑盒候选判定（按场景归属）

| 场景 | 归属 | 落点 / 理由 |
|:--|:--|:--|
| 参数校验全分支、401/403 鉴权分支；业务状态机、事务逻辑、数据库断言；单字段映射、业务计算逻辑 | 不进黑盒 | 拉取请求（PR）阶段白盒已覆盖： |
| 仅 Mock 第三方的超时/异常 | 不进黑盒 | 在 PR 白盒集成测试`*IT`中，通过`@MockBean`模拟外部依赖即可验证，无需部署环境黑盒验证 |
| 真实 HTTP（网关、Filter、TLS） | 黑盒候选 | 部署态独有 |
| 跨进程/跨服务串联（BFF→iam→域） | 黑盒候选 | 进程外视角；进程内多模块归白盒 IT |
| 真实第三方联调（支付沙箱、iam） | 黑盒候选 | 白盒 Mock 不了真环境 |
| 用户可见主路径、导出、列表 | 黑盒候选 | UAT/黑盒粗断言 |
| 线上曾出过缺陷的路径 | 黑盒候选 | 回归必留 |
