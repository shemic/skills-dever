# 从零开始

本文件用于空 Dever 项目初始化。已有项目不要用空项目脚本覆盖骨架。

## 顺序

1. 安装 Dever CLI，并同步 AI skill：

```bash
curl -fsSL https://raw.githubusercontent.com/shemic/skills-dever/main/scripts/install.sh | bash
```

脚本会在 Linux/macOS 自动安装 Go 1.25.3 到 `~/.dever/go`，检查 git，安装 `dever` 命令，然后执行 `dever skill install`。该命令要求 Node.js 18+ 和 npm，用于安装或更新 Trellis，并初始化当前项目；不需要 Trellis 时使用 `--skip-trellis`。Windows 暂不自动安装 Go，按脚本提示手动安装 Go 后重跑。不要把通用 AI skill 安装工具作为主安装路径。

2. 检查项目根提示词：

```bash
dever skill doctor
```

缺少 `AGENTS.md` 管理块或 `.trellis/` 时，重新执行安装脚本或 `dever skill install`。`CLAUDE.md` 只引用 `@AGENTS.md`。不需要 Trellis 的环境显式使用 `--trellis=false`。

3. 空目录生成最小骨架：

```bash
bash ~/.agents/skills/shemic-dever/scripts/boot.sh my dever-app 8082
```

Dever 应用 Go module 固定是 `my`。不要按项目名、域名或目录名改 module path。

生成后检查 `config/setting.jsonc` 的数据库配置：`database.default.prefix` 必须非空，推荐使用项目标识的小写下划线形式，例如 `shemic`。这个 prefix 是项目级表名前缀；组件前缀仍然写在每个 Model 的 `LoadModel` 表名里。

4. 安装基础 package：

```bash
dever package front
dever package bot
```

`dever package <name>` 默认安装或更新稳定版本，写 `module/<name>/main.go` package shim 并刷新注册文件。普通项目不保留 `package/<name>` 源码。维护 package 时需要验证 main、tag 或提交，才使用 `dever package --ref=main <name>` 或 `dever package --ref=<tag-or-commit> <name>`。

5. 新增业务资源按最低层级：

```txt
model -> page JSON -> Provider hook -> Service -> API -> front plugin
```

普通列表、新增、编辑、删除、详情只用 Model + page JSON，不写 CRUD API/Service。

## 最小骨架

空项目模板包含：

```txt
go.mod
main.go
config/setting.jsonc
data/readme.txt
module/front/main.go
module/bot/main.go
module/main/model/
```

`module/front/main.go` 和 `module/bot/main.go` 只放 package shim：

```go
// dever:import github.com/dever-package/front
```

不要在 shim 里写业务代码。

## 生成业务骨架

Model 骨架：

```bash
bash ~/.agents/skills/shemic-dever/scripts/module.sh main product
```

标准页面骨架：

```bash
bash ~/.agents/skills/shemic-dever/scripts/page.sh module/main admin product list 产品 --parent=product-center
bash ~/.agents/skills/shemic-dever/scripts/page.sh module/main admin product update 产品
```

这些脚本故意不生成 Service/API。只有读完 `service-api.md` 并确认存在真实业务流程后才手写。

## 常见错误

- Windows 暂不支持自动安装 Go，需按脚本提示手动安装后重跑。
- 没装 git 就运行安装脚本；脚本会停止并提示先安装 git。
- 没有 Node.js 18+ 或 npm，又未使用 `--skip-trellis`；脚本会停止并提示安装前置依赖。
- 跳过安装脚本，手动执行零散命令导致 Dever CLI、skill、AGENTS 不一致。
- 把 AI skill 安装工具当成主安装方式；主流程用 `scripts/install.sh`。
- 把 Go module 写成项目名，导致 package shim import 失效。
- 用 `boot.sh` 覆盖已有项目。
- 手动复制 `package/front` 源码到普通项目。
- 先写 API/Service，再补 model/page JSON。
- 手改 `data/router.go`、`data/load/*.go` 或 `data/table/*.json`。
