# Flutter 工作流入口

从 [使用手册](USAGE.md) 选择拆卡、详设或编码。模板只维护流程和 Golden 样例，业务工件在接入项目后按迭代落盘。项目事实统一维护在[系统画像](architecture/system-landscape.md)，后端协议由 [handoff](docs/handoff/README.md) 锁定版本。

从项目根启动时，读取项目根 AGENTS.md 和本入口。本线文档中的 `skills/`、`rules/`、`templates/`、`docs/`、`config/`、`architecture/`、`glossary/` 相对 `AI-Native/flutter/`；应用代码、测试及 Flutter 命令使用画像 §3.2 登记的应用根。

执行开发任务时，以[画像 §3.1](architecture/system-landscape.md)为技术选型基线。

Skill 定义阶段顺序与交付物，Rule 定义实现和验收要求。在线根运行 `bash scripts/validate-skills.sh` 校验模板。编码阶段完成自动检查后按[审查规则](rules/code-review.md)定档，独立审查人只读，实现者记录结论。L0 记录门禁结果，L1–L3 使用[报告模板](templates/code-review-report.md)。
