#!/usr/bin/env bash
# 在模板目录或工作流接入的工程内检查本线资产。仅依赖 Bash 和 Python 3。
set -eu
cd "$(dirname "$0")/.."
python3 - <<'PY'
from pathlib import Path
import re
import sys

errors = []
skills = ("flutter-story-splitting", "flutter-detail-design", "flutter-feature-coding")
required = ["AGENTS.md", "README.md", "USAGE.md", "architecture/system-landscape.md",
            "glossary/domain-glossary.md", "templates/code-review-report.md",
            "docs/handoff/README.md", "docs/methodology/readme.md", "config/current-sprint"]
rules = ("flutter-project", "flutter-performance", "api-client-conventions",
         "error-display-conventions", "code-review", "state-storage-events",
         "platform-bridge", "ui-design", "testing-release")
required.extend(f"rules/{name}.md" for name in rules)
for stage, prefix in (("requirements", "STORY"), ("design", "DD")):
    required.append(f"docs/{stage}/_golden/README.md")
    required.append(f"docs/{stage}/_golden/{prefix}-FL-GOLDEN-001-destination-search-allocate.md")
for name in skills:
    path = Path("skills", name, "SKILL.md")
    required.append(str(path))
    if path.is_file():
        match = re.match(r"\A---\n(.*?)\n---\n", path.read_text(encoding="utf-8"), re.S)
        header = match[1] if match else ""
        if (f"name: {name}" not in header.splitlines()
                or not re.search(r"^description:\s*\S+", header, re.M)):
            errors.append(f"{path}: 检查 name / description / frontmatter")
# 扫描扩展的规则和 Skill 附件，使新增 Markdown 的断链也能被发现。
documents = set(required)
for folder in ("rules", "skills", "templates", "architecture", "glossary", "docs/methodology"):
    documents.update(str(path) for path in Path(folder).rglob("*.md"))
for item in sorted(documents):
    path = Path(item)
    if not path.is_file():
        errors.append(f"缺少 {path}")
        continue
    content = path.read_text(encoding="utf-8")
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
if errors:
    sys.exit("\n".join(errors))
print(f"PASSED: {len(skills)} skills, {len(rules)} rules, {len(required)} assets and local links")
PY
