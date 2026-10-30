# Hooks：机制化强制（不依赖 AI 自觉）

源项目验证过的三个 bugfix 配套 Hook。**理念**：质量约束写在 Rule/Skill 里靠 AI 自觉遵守，Hook 在工具层强制——「公共代码写入必须人确认」「diff 超限提示」「漏跑测试提醒」。全部 fail-open（依赖缺失时放行，不阻断开发）。

| Hook | 触发时机 | 作用 | 强度 |
|------|----------|------|------|
| `bugfix-protect-common.sh` | preToolUse（Write/Edit 前） | 公共代码路径写入 → `permission: ask` 强制人确认（BR-05） | 阻断待确认 |
| `bugfix-diff-size.sh` | afterFileEdit | `.java` 累计改动 >30 行 → 提示最小修改原则（BR-03） | 提示 |
| `bugfix-test-reminder.sh` | stop（会话结束） | 改动模块未跑对应 `mvn test` → 提示补跑（BR-06） | 提示 |

## 接入

1. **改保护路径**：`bugfix-protect-common.sh` 顶部 `PROTECTED` 数组按目标项目替换（公共库 / 对外 API 模块 / 公司级公共包的 glob）。**注意：`{项目}` 等占位符在 case 匹配中按字面量处理，未替换时该条保护静默不生效**——接入后务必用一个公共代码路径试触一次确认被拦。
2. **注册到 agent**：这些脚本遵循 Cursor hooks 的 JSON 协议（stdin 收 JSON、stdout 回 JSON）。Cursor 在 `.cursor/hooks.json` 注册；其他 Agent（Claude Code、ZCode 等）用各自等价机制挂载同一脚本，协议字段（`permission` / `additional_context` / `followup_message`）按目标平台语义适配。
3. `bugfix-test-reminder.sh` 假设 Maven 多模块（`mvn -pl <module> test`）；Gradle 项目改 `gradle :module:test` 的解析逻辑。

> Hook 不是质量保障的唯一层：它们只覆盖 bugfix 流程的三个高发违规点；工件层校验见 `scripts/validate-skills.sh`，流程约束见 `skills/bugfix/SKILL.md`。
