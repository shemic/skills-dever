# shemic-dever

Dever 项目的 AI 开发约束 skill。它要求 AI 先识别任务角色，再按需读取少量规则，避免普通 CRUD 被写成 Service/API/front plugin。

## 安装

唯一维护源：

```txt
https://github.com/shemic/skills-dever
```

全新机器或全新项目先运行安装脚本：

```bash
curl -fsSL https://raw.githubusercontent.com/shemic/skills-dever/main/scripts/install.sh | bash
```

脚本会在 Linux/macOS 自动安装 Go 1.25.3 到 `~/.dever/go`，检查 git，安装 Dever CLI，然后执行 `dever skill install` 同步项目提示词和多工具 skill 引用。该命令要求 Node.js 18+ 与 npm，用于安装或更新 Trellis，并初始化当前项目；不需要 Trellis 时使用 `--skip-trellis`。Windows 暂不自动安装 Go，按脚本提示手动安装 Go 后重跑。

`dever skill install` 会每次从 GitHub 拉取临时副本，同步到：

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

Trellis 默认通过 `dever skill install` 管理：全局 CLI 更新到指定 npm 版本（默认 `latest`）；项目没有 `.trellis/` 时按 Codex 模式初始化，已有配置时使用 `trellis update --skip-all` 更新。Dever 会关闭 Trellis 自动 Git 提交，保留项目现有 `AGENTS.md` 内容，并把无任务状态调整为“小任务直接处理，复杂任务才询问是否创建 Trellis 任务”。

## 常用命令

首次安装 Dever CLI 和 AI skill：

```bash
curl -fsSL https://raw.githubusercontent.com/shemic/skills-dever/main/scripts/install.sh | bash
```

之后更新 Dever CLI 和当前项目 Dever 框架依赖：

```bash
dever update
dever update --ref=latest
```

`dever update` 默认追 GitHub `main`，会先在当前 Dever 后端项目中执行 `go get github.com/shemic/dever@<ref>`，再安装同一 ref 的 `dever` 命令。它不同步 AI skill；需要更新 AI skill 时单独执行：

```bash
dever skill install
dever skill doctor
```

只同步 Dever skill、不安装 Trellis：

```bash
dever skill install --trellis=false
```

只安装或更新全局 Trellis CLI、不初始化项目：

```bash
dever skill install --trellis-project=false
```

只想更新命令、不改当前项目 `go.mod` 时使用：

```bash
dever update --skip-framework
```

常见项目命令：

| 命令 | 用途 |
| --- | --- |
| `dever run` | 开发启动，自动生成注册文件并热重载源码和配置。 |
| `dever daemon start --name app -- dever run` | 后台启动 `dever run`。 |
| `dever daemon stop --name app` | 停止后台命令。 |
| `dever daemon restart --name app` | 重启后台命令；不带命令时复用上次命令。 |
| `dever daemon logs --name app -f` | 查看后台日志。 |
| `dever package front` | 安装或更新 `front` package。 |
| `dever package bot` | 安装或更新 `bot` package。 |
| `dever package` | 更新当前项目已启用的所有 package。 |
| `dever package --ref=main front` | 维护者验证未发布 package 时追 `main`；普通项目默认不用。 |
| `dever front build bot` | 构建本地可编辑 `bot` 前端插件，发布 package 前使用。 |
| `dever build` | 构建项目二进制，默认会先构建本地前端插件。 |
| `dever publish root@1.2.3.4:/opt/app --service=app --install-service --restart` | 发布到远端服务器，安装或更新 systemd 服务并重启。 |
| `dever publish root@1.2.3.4:/opt/app --include=server --service=app --restart` | 已完成首次部署后，只覆盖线上 server 二进制并重启，远端配置保持不变。 |
| `dever publish root@1.2.3.4:/opt/app --include=server,config,data/table,data/migrations --service=app --restart` | 显式把指定目录加入发布包；`data/...` 会合并到远端 `shared/data`。 |
| `dever cert issue root@1.2.3.4 --domain=admin.example.com --email=admin@example.com` | 在远端安装 acme.sh，并用 Nginx 模式签发和安装 HTTPS 证书。 |
| `dever cert info root@1.2.3.4 --domain=admin.example.com` | 查看远端证书信息和下次续签时间。 |
| `dever cert renew root@1.2.3.4 --domain=admin.example.com --force` | 远端强制续签证书。 |

本地维护框架源码时，才使用 `dever install` 把当前项目里的 `dever/cmd/dever` 绑定成启动脚本：

```bash
dever install --skip-skills
```

普通用户更新最新版命令用 `dever update`，不要把 `dever install` 当作在线更新命令。

HTTPS 证书命令基于远端 `acme.sh`：`issue` 默认使用 Let's Encrypt 和 Nginx 验证模式，证书安装到 `/etc/dever/certs/<domain>`，续签时会执行默认 reload 命令 `systemctl reload nginx`。如果不是 Nginx，可用 `--mode=webroot --webroot=/path/to/site` 或 `--mode=standalone`；reload 命令用 `--reload="systemctl reload caddy"` 覆盖，或用 `--reload=` 关闭。

`dever publish` 会在本机生成 `tar.gz` 发布包，再用 `scp` 上传到远端 `releases/<version>`。同一次发布会复用临时 SSH ControlMaster 连接，尽量避免准备目录、上传和激活发布时重复输入密码。

## 目录

```txt
SKILL.md                    # 薄入口：角色路由 + 全局硬规则
references/                 # 按角色读取的规则
references/front-page/      # page JSON 细协议
references/quickstart.md    # 空项目初始化流程
files/                      # AGENTS、Go、page、组件模板
scripts/                    # 静态 audit 和骨架脚本
```

## 从零开始

推荐顺序：

```bash
curl -fsSL https://raw.githubusercontent.com/shemic/skills-dever/main/scripts/install.sh | bash
dever skill doctor
bash ~/.agents/skills/shemic-dever/scripts/boot.sh my dever-app 8082
dever package front
dever package bot
```

`dever package` 默认更新稳定版本；维护 package 时需要验证未发布提交，使用 `dever package --ref=main front` 或把 `main` 替换为指定 tag/commit。

完整说明见 `references/quickstart.md`。已有项目不要用 `boot.sh` 覆盖骨架。

## 规则归属

- 核心入口：`SKILL.md`、`files/AGENTS.dever.md`
- 能力决策与代码归属：`references/decide.md`、`references/development.md`
- 产品需求拆解：`references/product.md`
- 应用开发：`references/app.md`
- Model：`references/model.md`
- Provider/Service/API：`references/service-api.md`
- Page JSON：`references/front-page.md` 和 `references/front-page/*`，字段录入边界见 `references/front-page/field.md`
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

`audit.sh` 对可确定的问题报错，对需要业务语义判断的结构和命名风险给出警告；它不替代人工审查。
