# handoff：客户端与后端契约交接区

> 客户端与后端分离（不同仓库/目录）时的**契约唯一交接点**。Flutter 客户端只消费不定义；接口变更必须先改后端 OpenAPI，再同步到本目录。机制说明见 [architecture/system-landscape.md §六](../../architecture/system-landscape.md)。

## 目录约定（接入后由 handoff 流程写入）

| 文件 | 作用 | 示例（源项目） |
|------|------|---------------|
| `openapi/{后端服务标识}.yaml` | 后端发布的 OpenAPI 契约快照 | `openapi/booking-bff-app.yaml` |
| `VERSION` | 契约版本 pin（tag 或 commit SHA + 播种时间 + 变更摘要） | `booking-bff-app @ tag 2026-S02-rc2` |
| `stories-index.md` | Story ↔ operationId 索引（拆卡时按页面选相关 operation） | 按服务、后端 Story 分组 |
| `story 摘要`（可选） | 后端每张卡的接口语义摘要，供 Flutter 客户端拆卡对齐 | — |

**模板未随附契约文件**——接入时向后端团队索取同一次发布的快照、VERSION 和索引，整包同步到本目录。`openapi/` 子目录在首次同步时创建。

## 工作方式（源自源项目的实践）

1. 后端在 OpenAPI 定稿或接口语义变更后，用 `api-handoff` 发布到 Flutter 的交接目录。发布时用 `--target` 指定该目录的绝对路径，再将后端校验器的 `HANDOFF_DIR` 指向同一绝对路径。后端校验器第 5 段核对快照与源契约、各服务版本行和索引覆盖。
2. Flutter 客户端把包同步进本目录（整文件替换，不改内容）。
3. `flutter-story-splitting` 拆卡时读本目录：按后端 Story 在索引中查找 operationId，再到对应服务的快照核对字段与 examples。索引由后端根据 `x-stories` 生成；发现缺项时请后端核对并重发。
4. 联调时客户端与后端对齐同一 VERSION 指向的环境。

## 缺失与后补

接入期按 [MIGRATION.md](../../MIGRATION.md) 选择现在获取或后补；后补时 VERSION 写 `TBD`，画像 §四及契约替换组列为待补项。拆卡、详设和编码的网络卡均需同版三件套，`TBD` 不代表已发布协议。

无业务后端调用的纯 UI、本地或仅原生 SDK 卡将契约、版本和 API 范围填 `N/A`，无需伪造 handoff；SDK 方法、权限和回调仍须有依据。混合项目的网络卡继续等待契约。

补齐时同步整包，更新画像与待补映射，再重跑接入验收。Story、DD、实现与联调环境应使用同一版本。
