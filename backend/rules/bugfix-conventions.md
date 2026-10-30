# bugfix 修 bug 约束（常驻）

> 完整七步流程见 [skills/bugfix/SKILL.md](../skills/bugfix/SKILL.md)。
> 本 Rule 只列通用硬禁令，常驻生效，不靠点名。项目特定数据（错误码号段 / 模块归属 / 鉴权层）见 [system-landscape.md §4.7](../architecture/system-landscape.md)。

## 硬禁令（违反即停）

1. 修 bug 前先澄清输入五要素（现象/预期/实际/复现步骤/上下文）；不清晰 → AskQuestion，超 2 轮 → 阻断
2. 复现测试必须先 RED（断言失败匹配 bug 现象）；GREEN / 假 RED → 回 Step 1 重写
3. 禁止改测试断言让测试通过；禁止 `@Disabled` 跳过失败测试
4. 禁止大范围重构式修 bug（提取方法、换模式、改继承）；改动 ≤ 30 行
5. 改公共代码（横向抽象层 / 外部依赖 / 域接口）→ 停下来 AskQuestion，不擅自改
6. 改 ORM 映射同步检查 DAO 方法；改错误码同步 API 契约文档；改 DTO 同步序列化测试
7. 循环计数器（修代码→跑测试→失败）超 3 轮 → 交还人工

## 责任域定位

按 [system-landscape.md §4.7 端到端调用链与 bugfix 责任域定位](../architecture/system-landscape.md#47-端到端调用链与-bugfix-责任域定位) 定位责任域（错误码号段 / 模块归属 / 鉴权层）。

根因不在本域 → AskQuestion 换仓，禁止硬改。
