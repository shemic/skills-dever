# Dever 框架

本文件用于维护 `backend/dever`、CLI、生成器、package 命令、run/build/front build、skill install、`package/front` runtime。

## 命令事实

- `dever skill install` 每次从 `github.com/shemic/skills-dever` 拉取临时副本。
- 主全局 skill 安装到 `~/.agents/skills/shemic-dever`。
- Codex、Claude、OpenCode、Trae、Qoder、CodeBuddy 等目录使用 symlink 引用主 skill。
- 项目只写根 `AGENTS.md`，`CLAUDE.md` 用 `@AGENTS.md` 引用。
- `dever package <name>` 安装或更新 `github.com/dever-package/<name>@latest`，写 shim，并刷新注册文件。
- `dever package add/update/sync/doctor/list` 已废弃。
- `dever run` 启动前执行 `init --skip-tidy`，model/service/api/component 变更后刷新注册。
- `dever build` 默认先执行 front plugin build，再构建 Go 二进制。

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

`dever run`：

- 有 dist manifest 时直接用 dist。
- 没有 dist manifest 且有 src entry 时启动插件 dev server。
- dev server 端口默认 `http.port + 10000`。

## 框架维护原则

- 先查现有 cache/runtimecache/middleware/generator，不新增平行机制。
- 改 CLI 时同步更新 skill、模板和 audit。
- 改 package/front runtime 时同步检查组件 page JSON、bot 画布、CRM 工作台、权限和 public site。
- 不为旧协议保留双路径兼容，除非用户明确要求迁移期。
