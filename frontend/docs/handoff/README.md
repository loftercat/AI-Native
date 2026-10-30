# handoff：前后端契约交接区

> 前后端分离（不同仓库/目录）时的**契约唯一交接点**。前端只消费不定义；接口变更必须先改后端 OpenAPI，再同步到本目录。机制说明见 [architecture/system-landscape.md §六](../../architecture/system-landscape.md)。

## 目录约定（接入后由 handoff 流程写入）

| 文件 | 作用 | 示例（源项目） |
|------|------|---------------|
| `openapi/{后端服务标识}.yaml` | 后端发布的 OpenAPI 契约快照 | `openapi/booking-bff-app.yaml` |
| `VERSION` | 契约版本 pin（tag 或 commit SHA + 播种时间 + 变更摘要） | `booking-bff-app @ tag 2026-S02-rc2` |
| `stories-index.md` | Story ↔ operationId 索引（拆卡时按页面选相关 operation） | 主流程 001→007 有序索引 |
| `story 摘要`（可选） | 后端每张卡的接口语义摘要，供前端拆卡对齐 | — |

**模板未随附契约文件**——接入时从你的后端仓库复制 OpenAPI 与版本 pin 到本目录。`openapi/` 子目录留空待用。

## 工作方式（源自源项目的实践）

1. 后端 OpenAPI 定稿并打 tag → 后端发布 handoff 包（openapi + VERSION + stories-index）。
2. 前端把包同步进本目录（整文件替换，不改内容）。
3. `frontend-story-splitting` 拆卡时读本目录：契约与版本以这里的快照为准，不直接读后端仓。
4. 联调时前后端对齐同一 VERSION 指向的环境。
