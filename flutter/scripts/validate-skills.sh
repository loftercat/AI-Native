#!/usr/bin/env bash
# 在模板目录或工作流接入的工程内检查本线资产。仅依赖 Bash 和 Python 3。
# 用法：bash scripts/validate-skills.sh [--quiet-tick]（仅汇总描述性路径 WARN）
set -eu
cd "$(dirname "$0")/.."
PYTHON=python3
python3 -c pass 2>/dev/null || PYTHON=python
"$PYTHON" - "$@" <<'PY'
import argparse
from pathlib import Path
import re
import sys

parser = argparse.ArgumentParser(description="校验 Flutter 工作流资产与引用")
parser.add_argument("--quiet-tick", action="store_true", help="描述性路径 WARN 仅报计数")
args = parser.parse_args()
errors = []
warnings = []
skills = ("flutter-story-splitting", "flutter-detail-design", "flutter-feature-coding")
required = ["AGENTS.md", "README.md", "USAGE.md", "MIGRATION.md", "architecture/system-landscape.md",
            "glossary/domain-glossary.md", "templates/code-review-report.md",
            "docs/handoff/README.md", "docs/methodology/readme.md", "config/current-sprint",
            "config/tech-stack.md"]
rules = ("flutter-project", "flutter-performance", "api-client-conventions",
         "error-display-conventions", "code-review", "state-storage-events",
         "platform-bridge", "ui-design", "testing-release")
required.extend(f"rules/{name}.md" for name in rules)
for stage, prefix in (("requirements", "STORY"), ("design", "DD")):
    required.append(f"docs/{stage}/_golden/README.md")
    required.append(f"docs/{stage}/_golden/{prefix}-Flutter-GOLDEN-001-destination-search-allocate.md")
required.extend(f"skills/{name}/SKILL.md" for name in skills)
# 扫描扩展的规则和 Skill 附件，使新增 Markdown 的断链也能被发现。
documents = set(required)
for folder in ("rules", "skills", "templates", "architecture", "glossary", "docs/methodology"):
    documents.update(str(path) for path in Path(folder).rglob("*.md"))
for item in sorted(documents):
    path = Path(item)
    if not path.is_file():
        errors.append(f"缺少 {path}")
        continue
    try:
        content = path.read_text(encoding="utf-8")
    except UnicodeError:
        errors.append(f"{path}: 预期 UTF-8")
        continue
    if path.name == "SKILL.md":
        match = re.match(r"\A---\n(.*?)\n---\n", content, re.S)
        header = match[1] if match else ""
        if (f"name: {path.parent.name}" not in header.splitlines()
                or not re.search(r"^description:\s*\S+", header, re.M)):
            errors.append(f"{path}: 检查 name / description / frontmatter")
    if item == "config/current-sprint" and not re.fullmatch(r"\d{4}-S\d{2}", content.strip()):
        errors.append(f"{item}: 预期 YYYY-SNN")
    if path.suffix != ".md":
        continue
    # 代码示例中的路径是接入后的工件。只解析正文 Markdown 本地链接。
    prose = re.sub(r"^```[^\n]*\n[\s\S]*?^```[^\n]*$", "", content, flags=re.M)
    for dest in re.findall(r"\]\(([^)\s]+)\)", prose):
        target = dest.split("#", 1)[0]
        if target and not re.match(r"[a-z]+:", target) and not (path.parent / target).exists():
            errors.append(f"{path}: 断链 {target}")
    if re.search(r"\[[^\[\]\n]+\([^()\s]+\)", prose):
        errors.append(f"{path}: 检查缺少 ] 的链接")
    # 反引号中的应用路径/待生成工件不是显式链接：与前端一致，仅 WARN。
    for raw in sorted(set(re.findall(r"`([^`\s]+)`", prose))):
        if (raw in ("N/A", "-", "—") or raw.startswith(("/", "@", "#"))
                or re.match(r"[a-z]+:", raw) or "..." in raw
                or any(c in raw for c in "{}*<>()|=")
                or re.fullmatch(r"\.[a-z0-9]+", raw)):
            continue
        if not re.search(r"/|\.(?:md|mdc|ya?ml|json|dart|sh|py|lock)$", raw):
            continue
        # ../ 必须相对来源文件，不回退到线根以免掩盖跨线断链。
        bases = [path.parent] + ([] if raw.startswith("../") else [Path(".")])
        if not any((base / raw.split("#", 1)[0]).exists() for base in bases):
            warnings.append(f"[WARN] {path}: {raw} (tick)")
if errors:
    sys.exit("\n".join(errors))
if args.quiet_tick:
    if warnings:
        print(f"[WARN] 描述性路径提示共 {len(warnings)} 条（--quiet-tick：仅计数）")
else:
    for warning in warnings:
        print(warning)
print(f"PASSED: {len(skills)} skills, {len(rules)} rules, {len(required)} assets and local links")
PY
