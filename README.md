# shemic-dever

仅针对 `shemic-dever` 这个 skill 的安装与使用说明（Human README）。

## 上下文说明

这个 `README.md` 不会影响 AI 常驻上下文：

1. 技能触发主要看 `SKILL.md` 的 frontmatter（`name` + `description`）。
2. `README.md` 未被 `SKILL.md` 引用，AI 默认不会主动加载它。
3. 仅当你明确要求读取 `README.md` 时，才会进入会话上下文。

## 安装

### 方式 1：通过 skills CLI 安装（推荐）

```bash
npx skills add shemic/skills-dever
```

### 方式 2：手动安装（离线备用）

如果你不能用 `npx skills`，再用手动方式：

```bash
tmp_dir="$(mktemp -d)"
git clone git@github.com:shemic/skills-dever.git "$tmp_dir"
mkdir -p ~/.codex/skills/shemic-dever
cp -r "$tmp_dir"/{SKILL.md,references,scripts,README.md} ~/.codex/skills/shemic-dever/
rm -rf "$tmp_dir"
```

### Claude Code 路径（可选）

如果你用 Claude Code，把目标路径换成：

```bash
~/.claude/skills/shemic-dever
```

### 卸载

```bash
npx skills remove shemic-dever
```

## 目录结构

- `SKILL.md`：技能入口与执行规则
- `references/boot.md`：空项目冷启动入口
- `references/module.md`：module 业务开发手册
- `scripts/boot.sh`：一键初始化空项目
- `scripts/module.sh`：按模块/资源生成业务骨架

## 会话中怎么使用

安装后，在对话第一句建议显式指定：

```text
使用 shemic-dever skill。当前是冷启动模式，请先初始化项目，再生成 blog/article 模块骨架。
```

或：

```text
使用 shemic-dever skill。当前是迭代模式，请在 module/blog 增加 article 审核接口并按规则执行 init。
```

## 快速使用

1. 空项目初始化：
   - `bash scripts/boot.sh <module_name> [dever_version] [app_name] [port]`
2. 生成业务模块骨架：
   - `bash scripts/module.sh <module_dir> <resource_name> [dever_version]`
3. 业务补充完成后执行：
   - `go run github.com/shemic/dever/cmd/dever@main init --skip-tidy`

## 建议

1. 规则改动优先更新 `SKILL.md`。
2. 业务实现方法与模板优先更新 `references/module.md`。
3. 仅当脚手架行为变化时更新 `scripts/*.sh`。
