"""OpenAPI 的轻量解析：提取 operation 的 (method, path, operationId, stories, summary)。

只覆盖 handoff 环节需要的字段，不追求完整 OpenAPI 语义：
- 不依赖 PyYAML（接入项目不保证装），按缩进自适应，兼容 2/4 空格等任意**空格**缩进；
- tab 缩进直接报错（YAML 要求统一缩进，混用会让解析错位）；
- 只在 `paths:` 顶层块内解析，`components:` / `servers:` 等块自动跳过；
- 行尾注释会被剥离（` # ...`），避免 `  /b:  # 备注` 被漏识别后沿用上一个 path；
- 块状 `x-stories`（`- STORY-x` 换行列表）显式报错，不静默当空；
- 解析不出任何 operation、或找不到 `paths:` 时也报错——空结果不是成功。

被 `gen-stories-index.sh` 与 `validate-skills.sh` 共用，保证「生成」与「校验」同一套解析。
"""

import pathlib

HTTP_METHODS = frozenset({"get", "post", "put", "patch", "delete", "head", "options", "trace"})

# Path Item Object 的合法非方法键（OpenAPI 3.0）；其余同缩进键视为结构错误
PATH_ITEM_KEYS = frozenset({"parameters", "servers", "summary", "description", "$ref"})


def _strip_inline_comment(text):
    """剥离行尾注释（空格后的 #）。引号内的 # 不区分——只影响展示字段，不影响结构字段。"""
    index = text.find(" #")
    return text[:index].rstrip() if index > 0 else text


def extract_operations(openapi_path):
    """解析单个契约。

    返回 (operations, errors)。
    operations 元素：{method, path, operation_id, stories, summary}
    """
    try:
        lines = pathlib.Path(openapi_path).read_text(encoding="utf-8").splitlines()
    except OSError as exc:
        return [], [f"{openapi_path}: 读取失败（{exc}）"]

    operations, errors = [], []
    in_paths = False
    found_paths = False
    path_indent = None
    method_indent = None
    current_path = None
    current = None
    tab_reported = False
    # parameters:/servers: 的列表项键（如 in: query）不是方法，整块跳过
    skip_block_indent = None

    def flush():
        nonlocal current
        if current is None:
            return
        label = f"{current['method'].upper()} {current['path']}"
        if current["operation_id"] is None:
            errors.append(f"{openapi_path}: {label} 缺 operationId")
        elif current.get("invalid"):
            pass  # 格式错误已单独报过，不重复
        elif not current["stories"]:
            errors.append(f"{openapi_path}: {label} 缺 x-stories")
        else:
            operations.append(dict(current))
        current = None

    for raw in lines:
        if not raw.strip():
            continue
        leading = raw[:len(raw) - len(raw.lstrip())]
        if "\t" in leading:
            if not tab_reported:
                errors.append(f"{openapi_path}: 含 tab 缩进（YAML 要求统一用空格，否则层级会错位）")
                tab_reported = True
            continue
        stripped = _strip_inline_comment(raw.strip())
        if not stripped or stripped.startswith("#"):
            continue
        indent = len(raw) - len(raw.lstrip(" "))

        if indent == 0:
            flush()
            in_paths = stripped == "paths:"
            found_paths = found_paths or in_paths
            path_indent = None
            method_indent = None
            current_path = None
            skip_block_indent = None
            continue
        if not in_paths:
            continue

        # 跳过 parameters:/servers: 的整个子块（其列表项键会被误认为方法拼错）
        if skip_block_indent is not None:
            if indent > skip_block_indent:
                continue
            skip_block_indent = None

        # path 行：以 / 开头（可带引号），以 : 结尾
        body = stripped[:-1].strip() if stripped.endswith(":") else ""
        if body and (body.startswith("/") or body.startswith('"/') or body.startswith("'/")):
            flush()
            path_indent = indent
            method_indent = None
            current_path = body.strip("\"'")
            continue

        key = stripped.split(":", 1)[0].strip().strip("\"'")

        # path-item 层的 parameters:/servers:：其子块与 operation 无关，整块跳过
        if (key in ("parameters", "servers") and current is None
                and stripped.endswith(":")):
            skip_block_indent = indent
            continue

        # 方法行：与同一 path 下第一个方法同缩进；深层字段可能刚好叫 options/get，不能当方法
        if key in HTTP_METHODS and current_path is not None:
            if method_indent is None:
                method_indent = indent
            if indent == method_indent:
                flush()
                current = {"method": key, "path": current_path, "operation_id": None,
                           "stories": [], "summary": "", "invalid": False}
                continue

        # 第一个方法之前、比 path 深一层的纯字母键：只可能是方法拼错
        # （path-item 的 parameters/summary 等通过白名单放行；列表项含空格/短横，不会命中）
        if (current_path is not None and method_indent is None and indent > path_indent
                and key.isalpha() and key not in PATH_ITEM_KEYS
                and not key.startswith("x-")):
            errors.append(f"{openapi_path}: {current_path} 下有未知键 '{key}'"
                          "（HTTP 方法拼错或非标准字段）")
            continue

        # path-item 层：未知键不能沿用旧 path（否则 /b 的 operation 会被记到 /a）
        if path_indent is not None and indent == path_indent:
            if key in PATH_ITEM_KEYS or key.startswith("x-"):
                continue
            errors.append(f"{openapi_path}: {current_path} 下有未知键 '{key}'"
                          "（HTTP 方法拼错或非标准字段）")
            flush()
            current_path = None
            continue

        # operation 内的字段：缩进必须深于方法行
        if current is None or method_indent is None or indent <= method_indent:
            continue
        value = stripped.split(":", 1)[1].strip() if ":" in stripped else ""
        if key == "operationId":
            current["operation_id"] = value.strip("\"'")
        elif key == "x-stories":
            if value.startswith("[") and value.endswith("]"):
                current["stories"] = [item.strip().strip("\"'")
                                      for item in value[1:-1].split(",") if item.strip()]
            else:
                current["invalid"] = True
                errors.append(f"{openapi_path}: {current['method'].upper()} {current['path']} "
                              "的 x-stories 不是行内数组（不支持块状写法）")
        elif key == "summary":
            current["summary"] = value

    flush()

    if not found_paths:
        errors.append(f"{openapi_path}: 未找到 paths: 顶层键（文件结构或缩进异常）")
    elif not operations and not errors:
        errors.append(f"{openapi_path}: 未解析出任何 operation（检查 paths: 下的缩进与结构）")
    return operations, errors
