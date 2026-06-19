# shemic-dever

Dever 项目的 AI 开发约束 skill。它要求 AI 先识别任务角色，再按需读取少量规则，避免普通 CRUD 被写成 Service/API/front plugin。

## 安装

唯一维护源：

```txt
https://github.com/shemic/skills-dever
```

推荐使用：

```bash
dever skill install
```

命令会每次从 GitHub 拉取临时副本，同步到：

```txt
~/.agents/skills/shemic-dever
```

并为常见工具目录创建 symlink 引用：

```txt
~/.codex/skills/shemic-dever
~/.claude/skills/shemic-dever
~/.opencode/skills/shemic-dever
~/.trae/skills/shemic-dever
~/.qoder/skills/shemic-dever
~/.codebuddy/skills/shemic-dever
```

项目根只写 `AGENTS.md`，`CLAUDE.md` 使用 `@AGENTS.md` 引用。

## 目录

```txt
SKILL.md                    # 薄入口：角色路由 + 全局硬规则
references/                 # 按角色读取的规则
references/front-page/      # page JSON 细协议
files/                      # AGENTS、Go、page、组件模板
scripts/                    # 静态 audit 和骨架脚本
```

## 规则归属

- 核心入口：`SKILL.md`、`files/AGENTS.dever.md`
- 应用开发：`references/app.md`
- Model：`references/model.md`
- Provider/Service/API：`references/service-api.md`
- Page JSON：`references/front-page.md` 和 `references/front-page/*`
- Front plugin：`references/front-plugin.md`
- Component/package/module：`references/component.md`
- Dever CLI/runtime：`references/framework.md`
- 审查、排障、安全、性能：`references/review.md`、`security.md`、`troubleshooting.md`
- Skill 自身维护：`references/skill-maintenance.md`

## 静态检查

```bash
bash scripts/audit.sh --changed
bash scripts/audit.sh <file-or-dir>
```

`audit.sh` 只检查可机器识别的硬约束，不替代人工判断。
