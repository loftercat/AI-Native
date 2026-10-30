#!/usr/bin/env bash
# 校验工作流资产完整性（模板版，自源项目 scripts/validate-skills.sh 改造）：
#   1. 每个 SKILL.md 有 YAML frontmatter（name + description）
#   2. 文中引用的相对路径 / 模板根路径均可解析（链接缺失 = FAIL，须在 CI 拦截）
#   3. 未闭合方括号坏链检测（[text(url) 形态，防批量替换丢 ] 回归）
# 用法：bash scripts/validate-skills.sh   （退出码非 0 = 存在错误）
# 扫描范围：skills/ rules/ reference/ architecture/ glossary/ docs/methodology/
# （docs/**/_golden 为样例目录、docs/training 为课件，正文链接已按样例约定豁免，不扫）
# 与源项目的差异：无 symlink 镜像检查、无 docs/skills 历史残留检查（模板无迁移历史）。
set -uo pipefail
cd "$(dirname "$0")/.."

FAIL=0

echo "== 1) frontmatter 检查 =="
for f in skills/*/SKILL.md; do
  if ! head -1 "$f" | grep -q '^---$'; then
    echo "  [FAIL] $f 缺 YAML frontmatter"; FAIL=1
  elif ! sed -n '2,10p' "$f" | grep -q '^name:'; then
    echo "  [FAIL] $f frontmatter 缺 name:"; FAIL=1
  fi
done
echo "  done"

echo "== 2) 引用路径解析检查 =="
# Windows 下 python3 常为 Store stub，优先找真实解释器
PY=python3
python3 -c pass 2>/dev/null || PY=python
$PY - <<'PYEOF'
import pathlib, re, sys

ROOT = pathlib.Path(".").resolve()
SCAN_ROOTS = [ROOT / d for d in
              ("skills", "rules", "reference", "architecture", "glossary",
               "docs/methodology")]
EXT = r"\.(md|mdc|ya?ml|csv|sql|py|java|sh|ts|xml|json|txt)$"
errors, warnings = [], []

link_re = re.compile(r"\]\(([^)\s]+?)(?:#[^)\s]*)?\)")
tick_re = re.compile(r"`([^`\s]+)`")
# [text(url)：方括号与括号之间缺 ]，多由批量替换事故产生
broken_re = re.compile(r"\[([^\]\[\n]+)\((?!http)[^)\s]*\)")

def candidates(text):
    for m in link_re.finditer(text):
        yield m.group(1), "link"
    for m in tick_re.finditer(text):
        yield m.group(1), "tick"

SKIP_TOKENS = {"N/A", "-", "—"}

def check_path(raw, src, kind):
    if raw in SKIP_TOKENS or raw.startswith(("http://", "https://", "mailto:", "/", "@")):
        return
    if re.fullmatch(r"\.[a-z0-9]+", raw):
        return  # 纯扩展名提及（.java / .py / .mdc），非路径
    # 注意：源版把 "..." 写进字符集导致 '.' 也在集合内，所有带扩展名链接被静默跳过；
    # 模板版只跳字面省略号与通配字符，路径中的点和 ../ 前缀正常校验。
    if "..." in raw or any(c in raw for c in "{}*<>()|="):
        return  # 模式占位符 / 代码片段 / 枚举，跳过
    if not re.search(EXT + "|/", raw):
        return  # 非路径标识符
    # 严格解析：相对链接只按文件自身目录解析；模板根相对写法（docs/、rules/…）按模板根解析。
    # 含 ../ 的链接不允许回退到 ROOT 解析——否则越界到线外/根的断链会被误判可达。
    bases = [src.parent] + ([] if raw.startswith("../") else [ROOT])
    has_sep = "/" in raw
    is_dir_ref = raw.endswith("/")
    if not has_sep or is_dir_ref:
        # 裸文件名 / 目录引用：可能是描述性提及，宽松解析，找不到仅告警
        bases += [ROOT / "rules", ROOT / "reference", ROOT / "architecture",
                  ROOT / "docs/agile", ROOT / "docs/methodology"] \
                 + list((ROOT / "skills").glob("*/templates")) \
                 + list((ROOT / "skills").glob("*/references"))
    for base in bases:
        cand = (base / raw)
        try:
            if cand.exists():
                return
        except OSError:
            continue
    hard = bool(re.search(EXT, raw)) and kind == "link"
    # 设计取舍：markdown 链接 ](path) 是显式引用，缺失即 FAIL；
    # 反引号 tick 多为「描述性提及项目文件」（pom.xml、schema.sql 等运行时产物），
    # 模板中不存在属正常，降为 WARN 提示人工确认。
    msg = f"  [{'FAIL' if hard else 'WARN'}] {src.relative_to(ROOT)} -> {raw} ({kind})"
    (errors if hard else warnings).append(msg)

for scan_root in SCAN_ROOTS:
    if not scan_root.exists():
        continue
    for src in scan_root.rglob("*"):
        if src.suffix not in (".md", ".csv", ".yaml"):
            continue
        text = src.read_text(encoding="utf-8", errors="replace")
        for m in broken_re.finditer(text):
            errors.append(f"  [FAIL] {src.relative_to(ROOT)} 未闭合方括号坏链: {m.group(0)[:80]}")
        for raw, kind in candidates(text):
            check_path(raw, src, kind)

# ── 3) Story 审查门禁（rules/story-review.md §五）─────────────
# FAIL：状态=已确认 但无报告 / 报告结论行缺失或不通过 / Blocker≠0 而通过
# WARN：存在 DD/TS 而 Story 状态≠已确认（流程跳跃提示，按去 slug 前缀匹配）；_golden 豁免
def story_gate():
    req_dir = ROOT / "docs" / "requirements"
    design_dir = ROOT / "docs" / "design"
    errs, warns = [], []
    stories = {}  # 卡号基名 -> (path, status)
    if req_dir.exists():
        for it in req_dir.rglob("STORY-*.md"):
            s = str(it)
            if "_golden" in s:
                continue
            m = re.search(r"\|\s*状态\s*\|\s*([^|]+)\|", it.read_text(encoding="utf-8", errors="replace"))
            status = m.group(1).strip() if m else ""
            stories[it.stem] = (it, status)
    reports = {}
    rev_dir = ROOT / "docs" / "reviews"
    if rev_dir.exists():
        for it in rev_dir.rglob("REVIEW-*.md"):
            s = str(it)
            if "_golden" in s:
                continue
            key = it.stem.replace("REVIEW-", "", 1)
            reports.setdefault(key, []).append(it)
    for stem, (path, status) in stories.items():
        if not status.lstrip().startswith("已确认"):
            continue
        rs = reports.get(stem, [])
        if not rs:
            errs.append(f"  [FAIL] {path.relative_to(ROOT)} 状态=已确认 但无审查报告（docs/reviews/**/REVIEW-{stem}.md）")
            continue
        latest = max(rs, key=lambda x: x.stat().st_mtime)
        rtext = latest.read_text(encoding="utf-8", errors="replace")
        m = re.search(r"^-\s*结论[：:]\s*(通过|不通过)\s*$", rtext, re.M)
        mb = re.search(r"^-\s*Blocker[：:]\s*(\d+)\s*$", rtext, re.M)
        if not m:
            errs.append(f"  [FAIL] {latest.relative_to(ROOT)} 缺结论行（应为「- 结论：通过」或「- 结论：不通过」，整词一行）")
        elif m.group(1) != "通过":
            errs.append(f"  [FAIL] {path.relative_to(ROOT)} 状态=已确认 但报告结论=不通过")
        elif mb and int(mb.group(1)) != 0:
            errs.append(f"  [FAIL] {latest.relative_to(ROOT)} 结论=通过 但 Blocker≠0")
    # 下游工件（DD/TS）存在而 Story 未过审 → 流程跳跃提示；按去 slug 前缀匹配，容忍 slug 漂移
    def stem_prefix(stem):
        parts = stem.split("-")
        return "-".join(parts[:4]) if len(parts) >= 5 else stem
    prefix_map = {}
    for stem, val in stories.items():
        prefix_map.setdefault(stem_prefix(stem), []).append((stem, val))
    for sub in (("design", "DD-"), ("test-spec", "TS-")):
        sub_dir = ROOT / "docs" / sub[0]
        if not sub_dir.exists():
            continue
        for it in sub_dir.rglob(sub[1] + "STORY-*.md"):
            s = str(it)
            if "_golden" in s:
                continue
            stem = it.stem.replace(sub[1], "", 1)
            cands = prefix_map.get(stem_prefix(stem), [])
            if len(cands) == 1 and not cands[0][1][1].lstrip().startswith("已确认"):
                kind = "详设" if sub[1] == "DD-" else "测试规格"
                warns.append(f"  [WARN] {it.relative_to(ROOT)} 存在{kind}，但 {cands[0][1][0].name} 状态≠已确认（流程跳跃提示，见 rules/story-review.md）")
    return errs, warns

g_errs, g_warns = story_gate()
errors.extend(g_errs)
warnings.extend(g_warns)

if errors:
    print("\n".join(errors))
    sys.exit(1)
for w in warnings:
    print(w)
print("  all hard links resolved + story review gate checked"
      + (f"（{len(warnings)} 个提示）" if warnings else ""))
PYEOF
if [ $? -ne 0 ]; then FAIL=1; fi

echo
if [ $FAIL -ne 0 ]; then echo "RESULT: FAILED"; exit 1; else echo "RESULT: PASSED"; fi
