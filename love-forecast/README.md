# 恋爱预见（love-forecast）

Web 端亲密关系沟通辅助工具。用户描述情境 → 系统给出三档可执行回复建议；可选导入历史聊天记录，让建议更贴合这个具体的人。

技术栈：Java 21 + Spring Boot 3.2 + Spring AI + MySQL 8。

## 布局

采用**分离式布局**：工作流方法集中在一个目录，工程侧只放代码与产物。

```text
love-forecast/
├── ai-workflow/                  # 工作流实例（方法 + 项目上下文）
│   ├── skills/ rules/ templates/ reference/ hooks/ scripts/
│   ├── architecture/system-landscape.md   # 项目画像（唯一事实源）
│   ├── glossary/domain-glossary.md
│   ├── config/current-sprint
│   └── docs/{methodology,training,agile}/ + 各产物目录下的 _golden/
├── backend/                      # 工程
│   ├── docs/{requirements,design,api,schema,test-spec,qa,reviews}/
│   ├── tests/{blackbox,data}/
│   └── {maven-modules}/          # 待建
├── AGENTS.md                     # 项目入口
└── MIGRATION.md                  # 模板接入清单（Skill 相对链接需要）
```

## 路径解析

Skill 里写的是**逻辑路径**，按两个根解析：

| 逻辑路径 | 实际位置 |
|---------|---------|
| `architecture/...`、`glossary/...`、`config/...` | `ai-workflow/` |
| `docs/methodology`、`docs/training`、`docs/**/_golden` | `ai-workflow/docs/` |
| `docs/requirements|design|api|schema|test-spec|qa|reviews`、`tests/...` | `backend/` |
| 业务代码 | `backend/{module}/` |

## 常用命令

```bash
# 工作流资产校验（在 ai-workflow/ 下）
cd ai-workflow && bash scripts/validate-skills.sh

# 构建与测试（在 backend/ 下，代码建好后）
cd backend && mvn -DskipTests install
```

## 当前状态

- 迭代：`2026-S01`
- 已就绪：PRD v0.4、人格分析规范、系统画像、领域词表
- 待办：JSD → HLD → Story → DD → 编码
