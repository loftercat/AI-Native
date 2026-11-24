#!/usr/bin/env bash
# 校验工作流资产完整性（模板版，自源项目 scripts/validate-skills.sh 改造）：
#   1. 每个 SKILL.md 有 YAML frontmatter（name + description）
#   2. 文中引用的相对路径 / 模板根路径均可解析（链接缺失 = FAIL，须在 CI 拦截）
#   3. 未闭合方括号坏链检测（[text(url) 形态，防批量替换丢 ] 回归）
# 用法：bash scripts/validate-skills.sh [--quiet-tick]   （退出码非 0 = 存在错误）
#   --quiet-tick：WARN 仅报计数，不逐条列出
# 扫描范围：skills/ rules/ templates/ reference/ architecture/ glossary/ docs/methodology/
# （docs/**/_golden 为样例目录、docs/training 为课件，正文链接已按样例约定豁免，不扫）
# 与源项目的差异：无 symlink 镜像检查、无 docs/skills 历史残留检查（模板无迁移历史）。
set -uo pipefail
cd "$(dirname "$0")/.."
SCRIPTS_DIR="$(cd scripts && pwd)"
export SCRIPTS_DIR
export PYTHONDONTWRITEBYTECODE=1

FAIL=0
QUIET_TICK=0
[ "${1:-}" = "--quiet-tick" ] && QUIET_TICK=1
export QUIET_TICK

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
import os, pathlib, re, sys

sys.path.insert(0, os.environ["SCRIPTS_DIR"])
from openapi_ops import extract_operations

ROOT = pathlib.Path(".").resolve()
SCAN_ROOTS = [ROOT / d for d in
              ("skills", "rules", "templates", "reference", "architecture", "glossary",
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

# ── 2b) 画像小节编号交叉引用（FAIL）────────────────────────
# Skill/Rule 按编号引用画像（§3.7 / §4.3.4 / §4.7）或链接 fragment（#434-…）；编号被改名后
# 链接仍可解析、但 Skill 的锚点就断了。这里比对「画像/system-landscape 紧邻引用的 §N.N」
# 与链接 fragment 前导编号，要求存在于画像实际标题编号（含 4.4 ~ 4.6 区间展开）。
# 编号是硬约束（AGENTS.md / rules/system-landscape-change.md），假阳性为零 → FAIL。
def landscape_numbers(arch):
    nums = set()
    for line in arch.read_text(encoding="utf-8", errors="replace").splitlines():
        m = re.match(r"^#{2,5}\s+(\d+(?:\.\d+)*)", line)
        if m:
            nums.add(m.group(1))
        mr = re.match(r"^#{2,5}\s+(\d+)\.(\d+)\s*(?:~|～|-|–|—|至)\s*(\d+)\.(\d+)", line)
        if mr:
            a, b, c, d = map(int, mr.groups())
            if a == c and b <= d:
                for i in range(b, d + 1):
                    nums.add(f"{a}.{i}")
    return nums

def check_landscape_refs():
    arch = ROOT / "architecture" / "system-landscape.md"
    if not arch.exists():
        return []
    nums = landscape_numbers(arch)
    anchors = {n.replace(".", "") for n in nums}
    bad = []
    frag_re = re.compile(r"system-landscape(?:\.[a-z]{2,4})?#(\d+)")
    # 定向解析：先剥掉 markdown 链接路径（路径里的 / 会切断语义），再只匹配
    # 「关键词 + 紧邻连接字符 + §N.N」的引用；一串连写（§3.7 / §4.3.4）逐个提取。
    # 非紧邻引用（中间夹「见」「与 HLD」等中文）不校验——宁可漏，不误报他文档编号。
    link_strip = re.compile(r"\]\([^)]*\)")
    kw_ref = re.compile(r"(?:system-landscape(?:\.md)?|画像)[\s`\[\]()（）.,，、:：/|]*§(\d+(?:\.\d+)*)")
    next_ref = re.compile(r"[\s`\[\]()（）.,，、:：/|]*§(\d+(?:\.\d+)*)")
    sources = []
    for scan_root in SCAN_ROOTS:
        if scan_root.exists():
            sources.extend(scan_root.rglob("*.md"))
    sources.extend(sorted(ROOT.glob("*.md")))  # 根级 MIGRATION/USAGE/README 也按编号引用画像
    for src in sources:
        text = src.read_text(encoding="utf-8", errors="replace")
        for line in text.splitlines():
            if "system-landscape" not in line and "画像" not in line:
                continue
            stripped = link_strip.sub("]", line)
            for m in kw_ref.finditer(stripped):
                if m.group(1) not in nums:
                    bad.append(f"  [FAIL] {src.relative_to(ROOT)} -> 画像 §{m.group(1)} 在画像标题中不存在（编号漂移）")
                pos = m.end()
                while True:
                    m2 = next_ref.match(stripped[pos:])
                    if not m2:
                        break
                    if m2.group(1) not in nums:
                        bad.append(f"  [FAIL] {src.relative_to(ROOT)} -> 画像 §{m2.group(1)} 在画像标题中不存在（编号漂移）")
                    pos += m2.end()
            if "system-landscape" in line:
                for m in frag_re.finditer(line):
                    if m.group(1) not in anchors:
                        bad.append(f"  [FAIL] {src.relative_to(ROOT)} -> system-landscape.md#{m.group(1)}… 锚点前导编号不在画像标题中")
    return bad

errors.extend(check_landscape_refs())

# ── 3) Story 审查门禁（rules/story-review.md §五）─────────────
# FAIL：状态=已确认 但无报告 / 报告结论行缺失或不通过 / Blocker≠0 而通过
# WARN：存在 DD/TS 而 Story 状态≠已确认（流程跳跃提示）；线根出现非样例工件（应迁项目根）
# 工件根：线根 docs（模板仓自检）+ 项目根 docs（接入后工件），存在的合并扫描
# 项目根判定：候选 = AI-Native/{线}/../..；无 git（未 init）直接用候选；
# 有 git 时候选须位于仓库根内（monorepo 子目录接入时 top 高于候选；AI-Native 自带 .git 时候选在 top 外，不扫项目根）
def project_root():
    cand = (ROOT.parent.parent).resolve()
    try:
        import subprocess
        out = subprocess.run(["git", "-C", str(ROOT), "rev-parse", "--show-toplevel"],
                             capture_output=True, text=True, encoding="utf-8",
                             errors="replace", timeout=5)
        if out.returncode == 0 and out.stdout.strip():
            top = pathlib.Path(out.stdout.strip()).resolve()
            try:
                cand.relative_to(top)
            except ValueError:
                return None  # 候选不在仓库内 → 不可信，不扫项目根
    except Exception:
        pass
    return cand

LINE_DOCS = (ROOT / "docs").resolve()
_PROJECT_ROOT = project_root()
PROJ_DOCS = (_PROJECT_ROOT / "docs").resolve() if _PROJECT_ROOT else None

def artifact_roots():
    roots = []
    for cand in (LINE_DOCS, PROJ_DOCS):
        if cand is None:
            continue
        try:
            cand = cand.resolve()
        except OSError:
            continue
        if cand in roots:
            continue
        if any((cand / d).exists() for d in ("requirements", "design", "test-spec", "reviews")):
            roots.append(cand)
    return roots

def story_gate():
    art_roots = artifact_roots()
    errs, warns = [], []
    def disp(p):
        try:
            rp = p.resolve()
        except OSError:
            rp = p
        for art in (LINE_DOCS, PROJ_DOCS):
            if art is None:
                continue
            try:
                rel = str(rp.relative_to(art)).replace("\\", "/")
            except ValueError:
                continue
            return f"[线根] docs/{rel}" if art == LINE_DOCS else f"docs/{rel}"
        return str(p)
    if _PROJECT_ROOT is None and (ROOT.parent.parent / "docs").exists():
        warns.append("  [WARN] 项目根 docs 存在但被跳过——AI-Native/ 可能自带 .git（或位于仓库外）；请移除 AI-Native/.git 后重跑（见 README 快速开始），否则 story 门禁只看线根")
    # 线根出现非 _golden 工件 → 提示迁移（不要求项目根 docs 已存在；排除 .gitkeep 脚手架）
    if PROJ_DOCS and LINE_DOCS.exists() and PROJ_DOCS != LINE_DOCS:
        for pat in ("requirements", "design", "test-spec", "qa", "api", "schema", "reviews"):
            d = LINE_DOCS / pat
            if not d.exists():
                continue
            n = sum(1 for f in d.rglob("*")
                    if f.is_file() and f.name != ".gitkeep" and "_golden" not in str(f))
            if n:
                warns.append(f"  [WARN] [线根] docs/{pat}/ 有 {n} 个非样例工件；接入后工件应落项目根 docs/（布局唯一，见 rules/project-layout.md）")
        for pat in ("blackbox", "data"):
            d = ROOT / "tests" / pat
            if not d.exists():
                continue
            n = sum(1 for f in d.rglob("*") if f.is_file() and f.name != ".gitkeep")
            if n:
                warns.append(f"  [WARN] [线根] tests/{pat}/ 有 {n} 个文件；接入后可执行测试应落项目根 tests/（布局唯一）")
    stories = {}  # 卡号基名 -> (path, status)
    for art in art_roots:
        req_dir = art / "requirements"
        if not req_dir.exists():
            continue
        for it in req_dir.rglob("STORY-*.md"):
            s = str(it)
            if "_golden" in s:
                continue
            if it.stem.startswith("STORY-FE-"):
                continue  # 前端卡归前端线（前端线不设 Story 审查门禁），后端门禁不判
            m = re.search(r"\|\s*状态\s*\|\s*([^|]+)\|", it.read_text(encoding="utf-8", errors="replace"))
            status = m.group(1).strip() if m else ""
            stories[it.stem] = (it, status)
    reports = {}
    for art in art_roots:
        rev_dir = art / "reviews"
        if not rev_dir.exists():
            continue
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
            errs.append(f"  [FAIL] {disp(path)} 状态=已确认 但无审查报告（docs/reviews/**/REVIEW-{stem}.md）")
            continue
        latest = max(rs, key=lambda x: x.stat().st_mtime)
        rtext = latest.read_text(encoding="utf-8", errors="replace")
        m = re.search(r"^-\s*结论[：:]\s*(通过|不通过)\s*$", rtext, re.M)
        mb = re.search(r"^-\s*Blocker[：:]\s*(\d+)\s*$", rtext, re.M)
        if not m:
            errs.append(f"  [FAIL] {disp(latest)} 缺结论行（应为「- 结论：通过」或「- 结论：不通过」，整词一行）")
        elif m.group(1) != "通过":
            errs.append(f"  [FAIL] {disp(path)} 状态=已确认 但报告结论=不通过")
        elif mb and int(mb.group(1)) != 0:
            errs.append(f"  [FAIL] {disp(latest)} 结论=通过 但 Blocker≠0")
    # 下游工件（DD/TS）存在而 Story 未过审 → 流程跳跃提示；按去 slug 前缀匹配，容忍 slug 漂移
    def stem_prefix(stem):
        parts = stem.split("-")
        return "-".join(parts[:4]) if len(parts) >= 5 else stem
    prefix_map = {}
    for stem, val in stories.items():
        prefix_map.setdefault(stem_prefix(stem), []).append((stem, val))
    for art in art_roots:
        for sub in (("design", "DD-"), ("test-spec", "TS-")):
            sub_dir = art / sub[0]
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
                    warns.append(f"  [WARN] {disp(it)} 存在{kind}，但 {cands[0][1][0].name} 状态≠已确认（流程跳跃提示，见 rules/story-review.md）")
    return errs, warns

# ── 4) 迭代收尾提醒（依据 USAGE「迭代收尾」）─────────────
# status=active 且 end 已过 → WARN（不阻断）：提醒执行归档，避免迭代一直未关闭
# 扫描线根与项目根的 docs/agile/sprint-registry.yaml；无 status 字段的旧格式行静默跳过
def sprint_gate():
    import datetime
    warns = []
    regs = []
    for base, tag in ((LINE_DOCS, "[线根] "), (PROJ_DOCS, "")):
        if base is None:
            continue
        p = base / "agile" / "sprint-registry.yaml"
        if p.exists():
            regs.append((p, tag))
    if not regs:
        return warns
    today = datetime.date.today()
    for reg, tag in regs:
        text = reg.read_text(encoding="utf-8", errors="replace")
        for block in re.split(r"\n\s*-\s+", text)[1:]:
            m_st = re.search(r"\bstatus:\s*([^#\n,}]+)", block)
            if not m_st:
                continue  # 无状态字段的旧格式迭代行，跳过
            status = m_st.group(1).strip().strip("\"'")
            if status != "active":
                continue
            m_id = re.search(r"\bid:\s*[\"']?([^\"'\n,}]+)", block)
            sid = m_id.group(1).strip() if m_id else "(未命名迭代)"
            m_end = re.search(r"\bend:\s*[\"']?(\d{4}-\d{2}-\d{2})", block)
            if not m_end:
                warns.append(f"  [WARN] {tag}迭代 {sid} 状态为 active 但 end 缺失或格式非 YYYY-MM-DD，无法判断是否过期")
                continue
            try:
                end = datetime.date.fromisoformat(m_end.group(1))
            except ValueError:
                warns.append(f"  [WARN] {tag}迭代 {sid} 的 end 日期无法解析（{m_end.group(1)}），无法判断是否过期")
                continue
            if end < today:
                warns.append(f"  [WARN] {tag}迭代 {sid} 已过期未收尾（end: {end}），请执行迭代收尾（见 USAGE「迭代收尾」）")
    return warns

# ── 5) handoff 包一致性（存在才校验）─────────────
# 前端 handoff 是冻结快照：后端改了契约却不重发，前端会对着旧版开发。
# 没有 VERSION 且没有快照 = 未发布，跳过（模板仓的空目录不算失败）。
# FAIL：快照与 docs/api 不一致 / VERSION 含 TBD / 索引缺 operationId。
def normalized_text(path):
    """忽略换行符差异：跨仓 checkout（core.autocrlf）会把 LF 变 CRLF，不是契约变更。"""
    return path.read_text(encoding="utf-8", errors="replace").replace("\r\n", "\n")


def handoff_gate():
    errs, warns = [], []
    # 跨仓/多前端线：用 HANDOFF_DIR 显式指定；否则按标准布局自动找
    override = os.environ.get("HANDOFF_DIR")
    if override:
        handoff = pathlib.Path(override)
        if not handoff.is_dir():
            return [f"  [FAIL] HANDOFF_DIR={override} 不存在"], []
    else:
        candidates = [ROOT.parent / "frontend", ROOT.parent / "AI-Native" / "frontend"]
        handoff = None
        for cand in candidates:
            if (cand / "docs" / "handoff").is_dir():
                handoff = cand / "docs" / "handoff"
                break
        if handoff is None:
            return errs, warns

    openapi_dir = handoff / "openapi"
    snapshots = sorted(openapi_dir.glob("*.yaml")) if openapi_dir.is_dir() else []
    version_file = handoff / "VERSION"
    index_file = handoff / "stories-index.md"
    if not snapshots and not version_file.exists():
        return errs, warns  # 未发布

    if not version_file.exists():
        errs.append("  [FAIL] handoff 缺 VERSION（前端无法确认契约版本）")
    if not index_file.exists():
        errs.append("  [FAIL] handoff 缺 stories-index.md")
    if not snapshots:
        errs.append("  [FAIL] handoff/openapi 下没有契约快照")

    operation_ids = set()
    for snap in snapshots:
        service = snap.stem
        sources = [ROOT / "docs" / "api" / service / "openapi.yaml"]
        if PROJ_DOCS is not None:
            sources.append(PROJ_DOCS / "api" / service / "openapi.yaml")
        source = next((p for p in sources if p.exists()), None)
        if source is None:
            errs.append(f"  [FAIL] {snap.name} 找不到权威源 docs/api/{service}/openapi.yaml")
            continue
        if normalized_text(snap) != normalized_text(source):
            errs.append(f"  [FAIL] {snap.name} 与 {source} 不一致（契约已变更但 handoff 未重发）")
        parsed, parse_errors = extract_operations(snap)
        for item in parse_errors:
            errs.append("  [FAIL] " + item)
        ops = [operation["operation_id"] for operation in parsed]
        if not ops and not parse_errors:
            errs.append(f"  [FAIL] {snap.name} 无 operationId（契约不完整，回 detail-design 补）")
        operation_ids.update(ops)

    if version_file.exists():
        version_text = version_file.read_text(encoding="utf-8", errors="replace")
        if "TBD" in version_text.upper():
            errs.append("  [FAIL] handoff/VERSION 含 TBD")
        if not re.search(r"@\s*\S+", version_text):
            errs.append("  [FAIL] handoff/VERSION 缺「{服务} @ tag/SHA」行")
        for snap in snapshots:
            service = snap.stem
            if not re.search(rf"^\s*{re.escape(service)}\s*@", version_text, re.M):
                errs.append(f"  [FAIL] handoff/VERSION 缺 {service} 的版本行（多服务每个一行）")
        if "未打 tag" in version_text:
            warns.append("  [WARN] handoff/VERSION 是临时版本（未打 tag）；正式交付前请打 tag 重发")

    if index_file.exists() and operation_ids:
        index_text = index_file.read_text(encoding="utf-8", errors="replace")
        # 精确匹配表格首列：裸子串会让 listObservations 被 listObservationsV2 顶包
        missing = sorted(op for op in operation_ids
                         if not re.search(rf"^\|\s*{re.escape(op)}\s*\|", index_text, re.M))
        if missing:
            errs.append("  [FAIL] stories-index.md 未覆盖: " + ", ".join(missing))
    return errs, warns

h_errs, h_warns = handoff_gate()
errors.extend(h_errs)
warnings.extend(h_warns)

g_errs, g_warns = story_gate()
errors.extend(g_errs)
warnings.extend(g_warns)
warnings.extend(sprint_gate())

import os
if errors:
    print("\n".join(errors))
    if warnings:
        if os.environ.get("QUIET_TICK") == "1":
            print(f"  [WARN] 另有 {len(warnings)} 条提示（quiet 模式未逐条列出；修复 FAIL 后重跑查看）")
        else:
            print("\n".join(warnings))
    sys.exit(1)
if warnings and os.environ.get("QUIET_TICK") == "1":
    print(f"  [WARN] 提示共 {len(warnings)} 条（--quiet-tick 模式：仅计数；去掉参数查看逐条明细）")
else:
    for w in warnings:
        print(w)
print("  all hard links resolved + story review + sprint gate + handoff checked"
      + (f"（{len(warnings)} 个提示）" if warnings else ""))
PYEOF
if [ $? -ne 0 ]; then FAIL=1; fi

echo
if [ $FAIL -ne 0 ]; then echo "RESULT: FAILED"; exit 1; else echo "RESULT: PASSED"; fi
