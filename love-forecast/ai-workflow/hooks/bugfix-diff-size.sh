#!/bin/bash
# bugfix Hook 2: 改动行数提示（afterFileEdit）
# .java 累计改动 > 30 行 → additional_context 提示（非阻断）
# fail open: 依赖缺失或解析失败 → 无输出

command -v git >/dev/null 2>&1 || exit 0
command -v awk >/dev/null 2>&1 || exit 0

# 取 .java 累计改动行数（git diff --stat 最后一行 summary）
summary=$(git diff --stat -- '*.java' | tail -1)

# 无改动 → 放行
[[ -z "$summary" ]] && exit 0

# 解析 insertions + deletions
ins=$(echo "$summary" | grep -oE '[0-9]+ insertion' | grep -oE '[0-9]+' || echo 0)
del=$(echo "$summary" | grep -oE '[0-9]+ deletion' | grep -oE '[0-9]+' || echo 0)
changed=$((ins + del))

# 解析失败或无改动 → 放行
[[ -z "$changed" || "$changed" -le 0 ]] && exit 0

if [ "$changed" -gt 30 ]; then
  cat <<EOF
{
  "additional_context": "Hook 提示：本次 .java 累计改动 ${changed} 行（>30）。按 bugfix BR-03 最小修改原则，请确认是否确有必要；超项须在 Step 3 显式说明理由。"
}
EOF
fi
exit 0
