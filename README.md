# shemic-dever

`shemic-dever` 是给 AI 用的 Dever 项目开发 skill。它的目标很明确：让 AI 看完这个 skill 后，能按 Dever 框架的真实规则快速搭一个项目、补业务模块、写后台页面、接前台站点和 front 插件，同时不乱改生成文件、不重复造 API/Service。

## Dever 是什么

Dever 是 shemic 后端项目使用的 Go 应用框架和生成体系。它把项目拆成 `module` 和可复用 `package`，用命令生成路由、Model 注册、Service/Provider 注册和表结构描述，再由 `package/front` 提供站点运行时和后台页面能力。

常用开发模式：

- 后台 CRUD：`Model + package/front + page JSON`，普通列表、编辑、详情不写 API/Service。
- 真实业务：状态流转、跨表保存、强校验、外部回调、异步任务才写 Service/API。
- 多站点：`config/front.json.sites` 定义后台、工作台、门户等站点；页面放 `front/page/{page}`。
- 复杂前端节点：写 package/module 自己的 `front/src/plugin.ts`，由 `dever run` 或 `dever front build` 编译加载。

## Dever 源码在哪

Dever 框架源码主仓库在 GitHub：

- 源码仓库：[shemic/dever](https://github.com/shemic/dever)
- Go 模块路径：`github.com/shemic/dever`
- CLI 源码：`cmd/dever`
- 应用运行入口库：`cmd`，业务入口通常 `import dever "github.com/shemic/dever/cmd"`。
- front 插件编译器：`compiler/front`。

当前 `/data/project/shemic` 项目是一个特殊形态：为了本地联调和维护框架，把 `github.com/shemic/dever` 源码放在 `backend/dever`，并在 `backend/go.mod` 里写了：

```go
replace github.com/shemic/dever => ./dever
```

所以只在当前项目里，这些路径才成立：

- `backend/dever`：本地 checkout 的 Dever 框架源码。
- `backend/dever/cmd/dever`：当前项目正在使用的 `dever` CLI 源码。
- `backend/dever/cmd`：当前项目正在使用的应用运行入口库。
- `backend/dever/compiler/front`：当前项目正在使用的 front 插件编译器。
- `backend/package/front`：当前项目内置的站点运行时、后台页面、上传、导入导出、插件服务等通用 package。
- `backend/package/bot`：当前项目内置的 bot package。
- package 拉取来源：`https://github.com/dever-package/<name>.git`。
- `front`：主 front 运行时源码，构建产物输出到 `backend/package/front/html`。

当前服务器上的 `/usr/local/bin/dever` 也是这个特殊形态的一部分：它会进入 `/data/project/shemic/backend/dever` 后执行：

```bash
go run ./cmd/dever "$@"
```

也就是说，在这个工作区里 `dever run` 用的是 `backend/dever/cmd/dever` 的代码。

## 安装

### 安装这个 skill

从当前仓库同步到本机 agent skill 目录：

```bash
mkdir -p ~/.agents/skills/shemic-dever
rsync -a --exclude .git skills/skills-dever/ ~/.agents/skills/shemic-dever/
```

安装后重新打开 AI 会话，或让当前会话重新加载 skills。之后可以直接对 AI 说：

```text
使用 shemic-dever skill，帮我用 Dever 搭一个项目。
```

### 安装 Dever CLI

普通项目优先从 GitHub 模块安装：

```bash
go run github.com/shemic/dever/cmd/dever@main install
```

只有像当前 `/data/project/shemic` 这种把 Dever 源码放在 `backend/dever` 的本地联调项目，才用本地源码安装：

```bash
cd backend
go run ./dever/cmd/dever install
```

安装后常用命令：

```bash
dever run
dever init --skip-tidy
dever routes
dever model
dever service
```

## 快速搭一个项目

空项目先补骨架，再接 site 基线：

```bash
bash skills/skills-dever/scripts/boot.sh my main my-app 8082
dever package add --skip-init front
dever package add --skip-init bot
dever init --skip-tidy
```

然后确认：

- `go.mod` 第一行固定是 `module my`，不要改成项目名、域名或目录名。
- `main.go` 注册了 `data.RegisterRoutes` 和 `package/front/service/site.Register`。
- `config/setting.jsonc` 开启 `frontSite`，日志写到 `data/log/access.log`、`data/log/error.log`。
- `config/front.json` 或 `config/front.jsonc` 有 `sites.admin`、`sites.work` 等站点。
- `module/front/main.go`、`module/bot/main.go` 是 package shim。
- `data/router.go`、`data/load/*.go`、`data/table/*.json` 由命令生成，不手改。

## 做一个后台站点

后台通常是 `admin` site：

- `config/front.json.sites.admin.api` 通常是 `front`。
- `config/front.json.sites.admin.page` 通常是 `admin`。
- `config/front.json.sites.admin.access.mode` 通常是 `rbac`。
- 页面目录放 `module/<biz>/front/page/admin/...` 或 `package/<name>/front/page/admin/...`。

普通后台资源流程：

1. 写 `module/<biz>/model/<resource>.go`，一表一文件，一个 `NewXxxModel()`。
2. 写 `module/<biz>/front/page/admin/<resource>/list.json`。
3. 写 `module/<biz>/front/page/admin/<resource>/update.json`。
4. 刷新生成文件：`dever init --skip-tidy`，或交给 `dever run` 自动刷新。

后台普通 CRUD 不默认写 API/Service。需要跨表保存、状态流转、导入转换、聚合统计时，再补 Service/Provider/API。

## 做一个前台站点

前台、工作台、门户通常单独建 site，例如 `work`：

- `config/front.json.sites.work.api` 可以是 `work`。
- `config/front.json.sites.work.page` 可以是 `work`。
- `config/front.json.sites.work.access.mode` 可以是 `login` 或按需求公开。
- 页面目录放 `module/work/front/page/work/...`。
- 业务 API 放 `module/work/api`，只写登录、注册、复杂交互、业务动作等真实 HTTP 能力。

前台如果只是表格、表单、详情，也可以继续用 page JSON。需要完整 React 交互时，再写 front 插件。

## 写一个 front 插件

插件放在 package 或 module 自己的 `front` 目录，不改主 `front/src`：

```txt
backend/module/work/front/
  page/work/home.json
  src/plugin.ts
  src/nodes/home/home-shell.tsx
```

`plugin.ts` 只注册节点，不做副作用：

```ts
import { defineFrontPlugin, lazyNode } from "@dever/front-plugin";

export default defineFrontPlugin({
  name: "work",
  nodes: {
    "work-home-shell": lazyNode(() =>
      import("./nodes/home/home-shell").then((mod) => ({
        default: mod.WorkHomeShell,
      })),
    ),
  },
});
```

页面 JSON 引用插件节点：

```json
{
  "page": { "name": "工作台首页", "type": 1 },
  "layout": {
    "type": "container",
    "children": {
      "content": { "type": "container" }
    }
  },
  "nodes": {
    "content": [
      { "type": "work-home-shell" }
    ]
  },
  "data": {},
  "state": {},
  "action": {}
}
```

开发时 `dever run` 会发现 `package/*/front/src/plugin.ts` 和 `module/*/front/src/plugin.ts`，启动内置 front 插件编译服务，按页面实际 node 加载插件。发布构建时再用：

```bash
dever front build
dever front build work
```

用户明确说不要 build/test 时，不运行这些命令。

## 目录说明

- `SKILL.md`：AI 使用本 skill 的入口规则。
- `references/workflow.md`：统一工作流和决策顺序。
- `references/empty-project.md`：空项目、多站点、`front` + `bot` 接入。
- `references/development.md`：复用、职责、命名、清理规则。
- `references/framework.md`：Dever 入口、命令、生成文件、路由、Load 注册。
- `references/model.md`：Model 文件、字段、Options、Relations、索引。
- `references/module.md`：Service、Provider、API、middleware。
- `references/page.md`：`package/front` 后台 page JSON。
- `references/package-plugin.md`：Go package、front 插件、构建和产物规则。
- `scripts/boot.sh`：补齐最小 Dever 项目骨架。
- `scripts/module.sh`：默认只生成 model；可选 `--provider` / `--api`。
- `scripts/audit.sh`：静态检查常见 Dever skill 错误。
- `files/gitignore`：Dever 项目 `.gitignore` 模板。
