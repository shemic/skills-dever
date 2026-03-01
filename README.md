# dever-project-dev

面向开发者的说明文档（Human README），用于快速了解这个 skill 的结构与使用方式。

## 上下文说明

这个 `README.md` 不会影响 AI 常驻上下文：

1. 技能触发主要看 `SKILL.md` 的 frontmatter（`name` + `description`）。
2. `README.md` 未被 `SKILL.md` 引用，AI 默认不会主动加载它。
3. 仅当你明确要求读取 `README.md` 时，才会进入会话上下文。

## 目录结构

- `SKILL.md`：技能入口与执行规则
- `references/empty-project-bootstrap.md`：空项目冷启动入口
- `references/module-business-development.md`：module 业务开发手册
- `scripts/bootstrap-empty-project.sh`：一键初始化空项目
- `scripts/scaffold-module.sh`：按模块/资源生成业务骨架

## 快速使用

1. 空项目初始化：
   - `bash scripts/bootstrap-empty-project.sh <module_name> [dever_version] [app_name] [port]`
2. 生成业务模块骨架：
   - `bash scripts/scaffold-module.sh <module_dir> <resource_name> [dever_version]`
3. 业务补充完成后执行：
   - `go run github.com/shemic/dever/cmd/dever@main init --skip-tidy`

## 建议

1. 规则改动优先更新 `SKILL.md`。
2. 业务实现方法与模板优先更新 `references/module-business-development.md`。
3. 仅当脚手架行为变化时更新 `scripts/*.sh`。
