# _golden — 存量用例迁移 Golden 样例

> **模板说明**：本目录是方法论样例（Golden），正文中的文件链接指向源项目历史工件，在本模板中不可达属预期；接入项目重写 Golden 时用本项目真实路径。

> 配套 legacy-test-migration SKILL 与 DD-STORY-2026-S01-095 §9.1。
> 用途：**Golden 自证**——本目录的预期分类由人工预先定义，作为 Skill 分类准确率的 ground truth。

## 文件

| 文件 | 说明 |
|------|------|
| `legacy-cases-golden.csv` | 输入：模拟存量用例导出（无 Story/AC） |
| `expected-classification.csv` | ground truth：人工预定义的预期分类（8 契约字段 + `title`） |

## 覆盖范围

| 维度 | 覆盖 |
|------|------|
| 门禁 | G1（TC-0012）、G2（TC-0010）、G3（TC-0011）、G4（TC-0013） |
| 白盒 | W1（TC-0002）、W2（TC-0001）、W3（TC-0006）、W4（TC-0004）、W5（TC-0005）、W6（TC-0007） |
| 黑盒 | B1（TC-0008）、B3（TC-0009）、B5（TC-0014） |
| 去重 | TC-0003 → `merged` 到 TC-0002 |

**未覆盖（显式声明）**：B2（UI E2E）、B4（性能）——仅定义路由，Golden 不覆盖；Python 适配层首版仅文档；真实存量项目试点待输入。

## 落层说明（易争议行）

| 行 | 判定 | 理由 |
|----|------|------|
| TC-0001 | W2（非 W1） | 断言点含 HTTP 200 + `code`，属 BFF HTTP 入口 |
| TC-0002 | W1 | 断言点在 Service 返回（空 list + code），走进程内单元 |
| TC-0003 | merged → TC-0002 | 同锚点（车位查询）+ 同分支（无结果）+ 断言集合等价；参数不同（关键词 / lotId）视为参数化 |
| TC-0006 | W3（非 W1） | 跨 order/inventory 两模块，需真实 Spring + DB |
| TC-0008 | B1（非 W2） | 断言点在网关 + 鉴权链（部署态增量），进程内测不到 |
| TC-0014 | B5 | 定时任务/批处理 + 对账，非 HTTP |

## 使用方式

1. 将 `legacy-cases-golden.csv` 作为输入，按 SKILL 标准流程跑一遍。
2. 产出实际矩阵，与 `expected-classification.csv` **逐行比对** `gate`/`layer`/`status`。
3. 全部一致 → AC-03 通过；不一致 → 定位到分类规则并补详设。
