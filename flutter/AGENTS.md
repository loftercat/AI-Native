# Flutter 工作流入口

首次接入或升级读 [接入指南](MIGRATION.md)。日常开发从 [使用手册](USAGE.md) 选择拆卡、详设或编码。模板只维护流程和 Golden 样例，业务工件在接入项目后按迭代落盘。项目事实统一维护在[系统画像](architecture/system-landscape.md)，后端协议由 [handoff](docs/handoff/README.md) 锁定版本。

从项目根启动时，读取项目根 AGENTS.md 和本入口。本线文档中的 `skills/`、`rules/`、`templates/`、Golden、handoff、方法论和原型资料、`config/`、`architecture/`、`glossary/` 相对 `AI-Native/flutter/`；迭代 Story、DD 和审查报告写入应用根的 `docs/{requirements,design,reviews}/{迭代}/`。应用代码、测试及 Flutter 命令使用画像 §3.2 登记的应用根。

本线用于新项目，统一采用 MVVM。接入时按[接入指南](MIGRATION.md#2-填写-flutter-画像)将[技术栈配置](config/tech-stack.md)写入项目画像。开发时以项目的[画像 §3.1](architecture/system-landscape.md#31-技术栈)为技术基线，业务 ViewModel 与数据 Bean 命名遵循[工程规则](rules/flutter-project.md#5-命名规范)。UI 组件、数据 Bean、Repository 和 Service 按[目录归属规则](rules/flutter-project.md#4-目录归属)放置。

生成文档遵循[工程规则的文档命名约定](rules/flutter-project.md#工作流文档命名)，端标识统一使用完整名称 `Flutter`。

Skill 定义阶段顺序与交付物，Rule 定义实现和验收要求。在线根运行 `bash scripts/validate-skills.sh --quiet-tick` 校验模板。编码阶段完成自动检查后按[审查规则](rules/code-review.md)定档，独立审查人只读，实现者记录结论。L0 记录门禁结果，L1–L3 使用[报告模板](templates/code-review-report.md)。

本线沿用前端三阶段，不设独立 Story/DD 审查门禁。涉及后端的卡必须先取得包含快照、VERSION 和索引的同版交接包；`TBD` 仅表示接入待补，不能作为开发依据。纯 UI、本地或仅原生 SDK 且无后端调用的卡填 `N/A`。
