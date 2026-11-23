#!/usr/bin/env bash
# 从 OpenAPI 的 x-stories 生成 Story ↔ operationId 索引（handoff 包的一部分）。
#
# 用法：bash scripts/gen-stories-index.sh <输出.md> <openapi.yaml>...
#   多服务时一次传多个 yaml，输出按服务分节（不要逐个生成后再拼接——会互相覆盖）。
# 退出码：0 成功；1 契约缺 operationId/x-stories、operationId 重复、含 tab 缩进、
#         path-item 层有未知键、或解析不出任何 operation（未知 HTTP 方法会被白名单忽略）；2 参数错误
set -euo pipefail

if [ $# -lt 2 ]; then
  echo "用法: bash scripts/gen-stories-index.sh <输出.md> <openapi.yaml>..." >&2
  exit 2
fi

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export SCRIPTS_DIR
export PYTHONDONTWRITEBYTECODE=1

# Windows 下 python3 常为 Store stub，优先找真实解释器
PY=python3
python3 -c pass 2>/dev/null || PY=python

$PY - "$@" <<'PYEOF'
import os
import pathlib
import sys

sys.path.insert(0, os.environ["SCRIPTS_DIR"])
from openapi_ops import extract_operations

target, sources = sys.argv[1], sys.argv[2:]


def service_of(source):
    """docs/api/{服务}/openapi.yaml 取父目录名；handoff/openapi/{服务}.yaml 取文件名。"""
    path = pathlib.Path(source)
    return path.parent.name if path.stem == "openapi" else path.stem


by_service, errors = {}, []
seen_by_service = {}
for source in sources:
    operations, errs = extract_operations(source)
    errors.extend(errs)
    service = service_of(source)
    # operationId 只要求文档内唯一；跨服务重名合法（前端按服务分包生成 client）
    seen = seen_by_service.setdefault(service, set())
    for operation in operations:
        if operation["operation_id"] in seen:
            errors.append(f"{source}: operationId 在服务 {service} 内重复: "
                          f"{operation['operation_id']}")
        seen.add(operation["operation_id"])
    # 同一服务可能拆成多个 yaml：累加而不是覆盖
    by_service.setdefault(service, []).extend(operations)

if errors:
    print("索引生成失败：", file=sys.stderr)
    for item in errors:
        print("  - " + item, file=sys.stderr)
    print("提示：operationId / x-stories 属于契约内容，回 detail-design 补，不在本脚本里猜。", file=sys.stderr)
    sys.exit(1)

out = [
    "# Story ↔ operationId 索引",
    "",
    "> 由 `scripts/gen-stories-index.sh` 从 OpenAPI 的 `x-stories` 自动生成，不要手工编辑。",
    "",
]
total = 0
for service in sorted(by_service):
    out.append(f"## {service}")
    out.append("")
    by_story = {}
    for operation in by_service[service]:
        for story in operation["stories"]:
            by_story.setdefault(story, []).append(operation)
    for story in sorted(by_story):
        out.append(f"### {story}")
        out.append("")
        out.append("| operationId | Method | Path | 说明 |")
        out.append("|---|---|---|---|")
        for operation in sorted(by_story[story],
                                key=lambda item: (item["path"], item["method"])):
            out.append(f"| {operation['operation_id']} | {operation['method'].upper()} "
                       f"| {operation['path']} | {operation['summary']} |")
            total += 1
        out.append("")

pathlib.Path(target).write_text("\n".join(out), encoding="utf-8")
print(f"索引已生成: {target}（{len(by_service)} 个服务 / {total} 条关联）")
PYEOF
