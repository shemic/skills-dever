# Dever 框架

本文件用于维护 `backend/dever`、CLI、生成器、package 命令、run/build/front build、skill install、`package/front` runtime。

## 命令事实

- 全新机器先用 `curl -fsSL https://raw.githubusercontent.com/shemic/skills-dever/main/scripts/install.sh | bash` 获取 `dever` 命令，同步 skill，并通过 Dever 安装/初始化 Trellis。
- Go 是 Dever 开发前置依赖；安装脚本在 Linux/macOS 自动安装 Go 1.25.3 到 `~/.dever/go`，Windows 只提示手动安装。
- `dever skill install` 每次从 `github.com/shemic/skills-dever` 拉取临时副本。
- `dever skill install` 默认要求 Node.js 18+ 和 npm，安装或更新 `@mindfoldhq/trellis@latest`；没有 `.trellis/` 时执行 Codex 项目初始化，已有项目执行 `trellis update --skip-all`。用 `--trellis=false` 完全跳过，或用 `--trellis-project=false` 只管理全局 CLI。
- Trellis 项目初始化后必须保持 `session_auto_commit: false`；无任务状态下，小型明确工作直接处理，复杂/模糊/跨模块/高风险工作才询问创建 Trellis 任务。项目 `AGENTS.md` 明确禁止 build/test 时，Trellis 验证阶段不得绕过。
- 主全局 skill 安装到 `~/.agents/skills/shemic-dever`。
- Codex、Claude、OpenCode、Trae、Qoder、CodeBuddy 等目录使用 symlink 引用主 skill。
- 项目只写根 `AGENTS.md`，`CLAUDE.md` 用 `@AGENTS.md` 引用。
- `dever install` 用于本地框架源码或内嵌 `dever/` 项目安装绑定启动脚本，不是空项目第一步。默认覆盖当前 `PATH` 命中的 `dever` 所在目录；该目录不可写时回退到用户 bin，必要时用 `--bin-dir` 显式指定。
- `dever install` 默认还会同步 AI skill：更新主全局 skill、常见工具目录的 symlink，以及项目根 `AGENTS.md`/`CLAUDE.md` managed block。本地框架维护通常使用 `dever install --skip-skills`，只更新 launcher。
- `dever update` 用于先在当前 Dever 后端项目执行 `go get github.com/shemic/dever@<ref>` 更新框架依赖，再从 GitHub 安装同一 ref 的 `github.com/shemic/dever/cmd/dever` 命令；默认追 `main`，安装到当前 `PATH` 命中的 `dever` 所在目录，不同步 AI skill。AI skill 单独用 `dever skill install` 安装或同步。需要稳定版本、tag 或提交时显式用 `--ref=latest`、`--ref=v0.1.1` 或 `--ref=<commit>`；只更新命令时用 `--skip-framework`。
- `dever package` 更新当前项目已启用的所有 `github.com/dever-package/*` package；`dever package <name>` 安装或更新单个 package，写 shim，并刷新注册文件。
- `dever package` 默认使用稳定通道 `@latest`。维护者需要验证 main、tag 或提交时使用 `dever package --ref=main <name>`、`dever package --ref=v0.1.1 <name>` 或 `dever package --ref=<commit> <name>`；不要把普通项目默认更新改成追 main。package 命令的 flag 必须写在组件名称前。
- `dever package add/update/sync/doctor/list` 已废弃。
- `dever run` 启动前执行 `init --skip-tidy`，model/service/api/component 变更后刷新注册。
- `dever run` 热重载只监听源码和配置目录：`config`、`dever`、`middleware`、`module`、`package`；不要监听 `data`，`data/skills`、`data/knowledge`、`data/upload`、`data/table` 等都是运行数据或生成数据。
- `dever build` 默认先执行 front plugin build，再构建 Go 二进制。
- `dever build` 不隐式构建宿主 `front/src`；宿主发布资产由维护者单独执行 `pnpm --dir front build:backend`。
- `dever build` 和默认会在本地构建的 `dever publish` 都不会隐式执行 `init`。API/model/service/component 注册相关变更后，先通过 `dever run` 或 `dever init --skip-tidy` 刷新生成状态，再执行 build/publish；不要依赖构建阶段补生成文件。
- `dever publish user@host:/opt/app` 在本地构建并打包默认白名单 `server,config`，通过本次发布专用的 SSH ControlMaster 连接用 `scp` 上传到远端 `releases/<version>`，创建 `shared/data`，把 release 内的 `data` 软链到 `shared/data`，再切换 `current`。
- `dever publish --include=server user@host:/opt/app` 只发布 `server` 并复用远端已有 `current/config`；首次上线或需要同步配置变更时使用默认 include。
- `dever publish --include=server,config,data/log,data/table user@host:/opt/app` 会把指定路径加入发布包；`data/...` 会在远端合并到 `shared/data` 后再创建 release 内的 `data` 软链。
- `dever publish --include=server,config,data --exclude=data/log user@host:/opt/app` 先按 include 白名单选择内容，再从选中的目录中过滤 exclude 子路径。
- `dever publish --skip-build --binary=server user@host:/opt/app` 复用本地已有二进制。
- `dever publish --service=<name> --install-service --restart user@host:/opt/app` 才会写入 systemd 并重启服务；服务名必须显式指定，避免一台服务器多个应用互相覆盖。`--install-service` 只控制 systemd unit，不控制是否发布配置。
- `dever publish` 支持 flag 写在远端目标前或后，但远端目标只能有一个。
- `dever cert issue user@host --domain=<domain> --email=<email>` 通过 SSH 在远端安装或复用 `acme.sh`，默认使用 Let's Encrypt、`--nginx` 验证、`--install-cert` 安装到 `/etc/dever/certs/<domain>`，并保存 reload 命令；也支持 `--mode=webroot --webroot=<dir>` 和 `--mode=standalone`，非 Nginx 可用 `--reload=<cmd>` 覆盖或 `--reload=` 关闭。
- `dever cert info user@host --domain=<domain>` 查看远端 `acme.sh --info -d <domain>` 输出；`dever cert renew user@host --domain=<domain> --force` 强制续签。
- 证书命令不要直接读取 `~/.acme.sh` 内部证书文件；部署 Nginx 时使用 `dever cert issue` 安装出的 `fullchain.pem` 和 `privkey.pem`。
- `dever daemon start -- <command...>` 可在当前项目后台运行任意命令；默认名称为 `default`，用 `--name` 区分多个后台命令。`stop/restart/status/logs -f` 通过 `tmp/dever/daemon/<name>.*` 管理 pid、元数据和日志。`restart` 不带命令时复用上次命令。

## 生成文件

不要手改：

```txt
data/router.go
data/load/model.go
data/load/service.go
data/load/component.go
data/table/*.json
```

生成器事实：

- model：扫描 active module/package 的 `model/`，只注册零参 `New*Model`。
- service：扫描 `service/`，只注册 `Provider*` 接收者方法。
- api：扫描 active module/package 的 `api/**/*.go`，`api/` 下的子目录会进入 URL 前缀。
  - `package/bot/api/admin/team.go` -> `/bot/admin/team/...`
  - `package/bot/api/body/project.go` -> `/bot/body/project/...`
  - `package/crm/api/work.go` -> `/crm/work/...`
- component：扫描 active module/package 的 `dever.json` 和 embed FS。

## Go module

Dever 应用项目固定：

```go
module my
```

普通项目不写：

```go
replace github.com/shemic/dever => ./dever
replace github.com/dever-package/front => ./package/front
```

这些 replace 只属于本地框架/package 开发仓库。

## front plugin build

`dever front build`：

- 只构建本地可编辑 package/module 插件。
- 外部 Go module package 有 dist 就跳过。
- 外部 Go module package 有 `front/src/plugin.ts` 但没有 `front/dist/manifest.json` 会报错，要求 package 发布前构建 dist。
- 前端插件构建产物不应打包 React/ReactDOM/jsx-runtime 的运行时代码，也不应残留浏览器不可用的 `process.env.NODE_ENV`；dev 和 build 都通过宿主全局 shim 读取 React 运行时。
- 前端插件构建产物如果生成独立 `.css` asset，`manifest.json` 的入口 JS 必须带 `css` 数组，宿主 runtime 只按入口 `css` 注入样式。
- 生产 split 插件的宿主兼容引用在业务模块内加载，不为每个 `@/...` 生成 virtual bridge chunk；single/IIFE 插件继续使用宿主预载兼容模块。
- 插件可在 `front/package.json` 的 `dever.bundleBudget` 声明自己的产物预算；框架统一检查 JS/CSS 数量、动态入口、小文件、静态闭包和循环，不写死业务插件阈值。
- 构建先输出到插件 `front/.dist-next-<pid>`；Vite、bundle audit 和 manifest 后处理全部成功后才替换正式 `front/dist`。

`dever run`：

- 本地可编辑插件继续走项目级 Vite source server 和 virtual compat；不增加 watch build，不读取生产 dist 模拟开发环境。
- 外部 package 继续消费已经发布的 dist。
- source server 端口默认 `http.port + 10000`；源码模块请求数不套用生产 bundle 预算。

宿主 `front/src`：

- 维护者执行 `pnpm --dir front build:backend` 独立构建，先写 `.html-next-<pid>` 并通过同一 bundle audit，再替换 `package/front/front/html`。
- 宿主和插件共享审计实现与业务域分包原则，但各自使用独立预算和发布入口。
- 不在 `dever build` 中串联宿主构建，避免每个应用重复构建 package/front。

## 框架维护原则

- 先查现有 cache/runtimecache/middleware/generator，不新增平行机制。
- 改 CLI 时同步更新 skill、模板和 audit。
- 改 package/front runtime 时同步检查组件 page JSON、bot 画布、CRM 工作台、权限和 public site。
- 不为旧协议保留双路径兼容，除非用户明确要求迁移期。
