#!/bin/bash
# bugfix Hook 1: 公共代码保护（preToolUse，写操作前触发）
# 命中「公共代码」路径 → permission: ask 强制人确认（bugfix BR-05）
# fail open: 依赖缺失时不阻断
#
# ── 接入配置 ─────────────────────────────────────────────
# PROTECTED 为公共/共享代码的 glob 列表，接入时替换为本项目真实路径。
# 建议保护：项目公共库、各微服务对外契约 *-api、公共基础包目录。
PROTECTED=(
  "*{project}-common/src/main/*"
  "*-api/src/main/java/*"
  "*com/{company}/common/*"
)
# ─────────────────────────────────────────────────────────

command -v jq >/dev/null 2>&1 || { echo '{"permission":"allow"}'; exit 0; }

input=$(cat)
path=$(echo "$input" | jq -r '.tool_input.path // empty')

# 无路径字段 → 放行
[[ -z "$path" ]] && { echo '{"permission":"allow"}'; exit 0; }

# 白名单放行：测试、文档、工作流资产目录
case "$path" in
  *src/test/*|*docs/*|.cursor/*|.claude/*|.agents/*|rules/*|skills/*)
    echo '{"permission":"allow"}'
    exit 0
    ;;
esac

# 命中公共代码
for pattern in "${PROTECTED[@]}"; do
  case "$path" in
    $pattern)
      cat <<EOF
{
  "permission": "ask",
  "user_message": "公共代码改动需确认（BR-05）。请确认后再放行。",
  "agent_message": "Hook 拦截：目标文件属于公共代码（${pattern}）。按 bugfix-conventions Rule + SKILL.md BR-05，须停下来用 AskQuestion 跟人确认，不擅自改。"
}
EOF
      exit 0
      ;;
  esac
done

# 默认放行
echo '{"permission":"allow"}'
exit 0
