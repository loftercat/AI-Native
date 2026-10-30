#!/bin/bash
# bugfix Hook 3: 测试兜底提示（stop）
# 有 .java 改动但未跑匹配模块 mvn test → followup_message 提示（非阻断）
# fail open: 依赖缺失或字段缺失 → 无输出

command -v git >/dev/null 2>&1 || exit 0
command -v grep >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0

# 改动模块集合（取顶层 Maven 模块名）
changed_modules=$(git diff --name-only -- '*.java' | sed 's|/src/.*||' | sort -u)

# 无 .java 改动 → 放行
[[ -z "$changed_modules" ]] && exit 0

# 会话历史中的 mvn test 命令（按 create-hook 约定，输入含 session_commands）
input=$(cat)
ran_test=$(echo "$input" | jq -r '.session_commands[]? // empty' 2>/dev/null | grep -E 'mvn.*test' || true)

# 全量 mvn test 视为覆盖所有模块
if echo "$ran_test" | grep -qE 'mvn\s+test($|\s)'; then
  exit 0
fi

# 检查每个改动模块是否有 mvn -pl <模块> test
uncovered=""
for m in $changed_modules; do
  if ! echo "$ran_test" | grep -qE "mvn.*-pl[[:space:]]+$m"; then
    uncovered="$uncovered $m"
  fi
done

if [[ -n "$uncovered" ]]; then
  cat <<EOF
{
  "followup_message": "Hook 提示：以下模块有 .java 改动但未跑对应 mvn test：${uncovered}。按 bugfix SKILL.md Step 6，改完代码须跑受影响测试。"
}
EOF
fi
exit 0
