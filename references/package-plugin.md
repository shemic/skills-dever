# Package / Front Plugin 规则

用于维护可复用 Go 组件，或给 package/module 增加前端插件。普通业务开发不要改 `backend/package/*`，除非用户明确要求维护 package。

## 1. Go package 组件

真实代码放 package：

```txt
backend/package/<name>/
  <name>fs.go
  middleware/
  model/
  service/
  api/
  front/page/{page}/
```

应用只放 shim：

```go
// backend/module/<name>/main.go
package <name>

// dever:import my/package/<name>
```

规则：

- Model / Service / API / Page 仍按 `model.md`、`module.md`、`page.md`。
- 不手改 `data/router.go`、`data/load/*.go`、`data/table/*.json`。
- package 的 page JSON 放 `backend/package/<name>/front/page/{page}`，path 仍归 package。`{page}` 规则见 `page.md`。
- `go:embed front/page` 放在 package 自己的 `fs.go`。
- package 自带中间件放 `middleware/init.go`，提供 `Register()`；Dever 通过 module shim 自动发现并注册。
- package middleware 内部必须 `sync.Once`，只写组件自己的横切逻辑，不写项目私有路径规则。
- package 内部运行时缓存优先复用 `dever/cache`，并通过组件自己的统一失效入口管理。
- `package/front` 的页面、权限、option 等 runtime 缓存统一接入 `runtimecache.Register`；保存、删除、导入等写操作成功后主动失效。
- front 插件仍按页面实际 node 按需加载，不要因为缓存或预热改成全量加载插件。

## 2. 项目引入 package

项目里需要新增组件时，优先用命令：

```bash
dever package add bot
```

它会从 `https://github.com/dever-package/bot.git` 拉取到 `package/bot`，创建 `module/bot/main.go` shim，并刷新 routes/model/service 注册。换组件时把 `bot` 换成对应名称。

可选项：

```bash
dever package add --project-root=backend bot
dever package add --repo-base=https://github.com/dever-package bot
dever package add --skip-init bot
```

更新已安装组件：

```bash
dever package update bot
```

默认更新规则：

- `package/bot` 必须是 git 仓库。
- 本地有未提交或未处理文件时直接报错。
- 更新动作是 `git pull --ff-only`，不做合并提交。
- `module/bot/main.go` 缺失时会补 shim；存在但不是目标 shim 会报错。
- 更新后默认刷新 routes/model/service 注册。

确认要丢弃本地 package 改动并重拉时，才使用：

```bash
dever package update --force bot
```

手动引入时使用同样结构：

```txt
backend/package/<name>/   # 确保 package 源码已存在，本地 package 直接放这里
backend/module/<name>/main.go
```

`module/<name>/main.go`：

```go
package <name>

// dever:import my/package/<name>
```

然后刷新生成文件：

```bash
dever init --skip-tidy
```

如果 package 来自独立 Go module，不要复制代码；在 `go.mod` 配好 `require/replace`，shim 的 import 写真实 Go import path。Dever 会通过 `go list` 解析真实源码目录。

package 自带前端插件会由 `package/front` 的站点服务发现；不要在每个组件里复制插件静态服务。

## 3. Package 前端插件目录

复杂 React 节点不要塞进主 `front/src`，放 package 自己的 `front`：

```txt
backend/package/<name>/front/
  page/{page}/
  src/
    plugin.ts
    nodes/
    components/
  dist/
    placeholder.txt
```

module 也可用同样结构：

```txt
backend/module/<name>/front/
  page/{page}/
  src/plugin.ts
```

开发态有两种：

1. 主 front 源码开发：`cd front && pnpm dev`，访问 5173。
2. 应用开发者模式：`dever run`，访问 8085；主 front 使用 `package/front/html`，插件源码由 Dever CLI 内置的 `compiler/front` 编译，8085 代理后按需加载。

两种模式都会扫描：

```txt
backend/package/*/front/src/plugin.ts
backend/module/*/front/src/plugin.ts
```

所以开发时改插件 `front/src` 不需要先打包插件。8085 模式不是让浏览器直接执行 TSX，而是由 `dever run` 启动 Dever CLI 的前端插件编译器，再按页面实际 node 通过 `{site}/plugins-src/{name}/runtime.js` 加载编译后的 ESM。开发者不需要也不应该依赖主 `front/src`。

多站点 front 只记一条：站点配置在 `config/front.json.sites`，页面目录是 `front/page/{page}`，业务前台优先放 `module/<name>`，可复用能力放 `package/<name>`。

## 4. 插件入口模板

`plugin.ts` 只注册能力，不做副作用。插件只能依赖公开 SDK，不要依赖主 `front/src` 的 `@/...` 路径：

```ts
import { defineFrontPlugin, lazyNode } from "@dever/front-plugin";

export default defineFrontPlugin({
  name: "bot",
  nodes: {
    "show-agent": lazyNode(() =>
      import("./nodes/show/agent").then((mod) => ({ default: mod.ShowAgent })),
    ),
  },
});
```

不要再写 `runtime.ts`；Dever CLI 前端插件编译器会按 `plugin.ts` 自动生成开发态和发布态注册入口。

`nodes` 和 `depends` 都从 `plugin.ts` 自动提取，用于运行时按需加载插件。不要在 `front.json` 里手写插件 node 清单；页面 JSON 引用了某个插件 node，主 front 才会加载对应插件。

节点组件使用 `@dever/front-plugin` 暴露的 SDK 和组件：

```ts
import type { NodeItemProps } from "@dever/front-plugin";
import { Button, request } from "@dever/front-plugin";
```

不要在插件里复制主 front 的 UI、请求、上传、agent runner、类型，也不要直接 import 主 `front/src`。旧插件里的 `@/...` 会由 compiler 兼容，但新代码必须用 `@dever/front-plugin`。

## 5. React 依赖规则

插件前端不能自己打包一份 React。

- 主 front 源码开发态：主 `front` 的 Vite alias / dedupe 提供同一份 React。
- 8085 源码插件开发态：Dever CLI 前端插件编译器编译插件，后端代理会把 Vite 的 React 依赖映射到主 front 暴露的 `window.React`。
- 发布态：插件构建必须 external `react`，由主 front 暴露 `window.React`。
- 不要在插件 `package.json` 里单独升级 React。

如果出现 hook 报错，先查是否打了两份 React。

## 6. 构建命令

主 front 开发：

```bash
cd front
pnpm dev
```

应用开发者模式：

```bash
dever run
```

`dever run` 检测到 `package/*/front/src/plugin.ts` 或 `module/*/front/src/plugin.ts` 后，会自动安装/复用 Dever CLI 前端插件编译器依赖并启动插件源码编译服务，后端站点仍访问：

```txt
http://host:8085/admin/
http://host:8085/huabu/
```

临时关闭插件源码模式：

```bash
DEVER_FRONT_PLUGIN_DEV=0 dever run
```

发布前构建所有插件前端：

```bash
dever front build
```

只构建某个插件：

```bash
dever front build bot
```

主 `front` 运行时单独构建，输出到 `backend/package/front/html`。它只包含基础框架和基础组件，不把 `backend/package/*/front/src`、`backend/module/*/front/src` 编进主包：

```bash
cd front
pnpm run build:backend
```

完整发布。`target` 可选，能传目录或 `main.go`；不传就构建当前项目：

```bash
dever build [target]
```

`dever build` 默认先执行前端插件构建，再 Go build。只想构建 Go：

```bash
dever build --skip-front
```

用户说不要 build/test 时，不运行这些命令。

## 7. 前端产物服务与二进制

插件构建产物输出到自己的 `front/dist`。后端站点发布态会自动发现 `backend/package/*/front/dist/manifest.json` 与 `backend/module/*/front/dist/manifest.json`；`dever run` 开发态优先发现源码插件。运行时会先根据页面 schema 的 node 类型判断需要哪些插件，再加载对应插件入口。page JSON 放 `front/page`。package 需要进二进制时用 `go:embed` 带进产物：

```go
//go:embed front/page
var PageFS embed.FS

//go:embed front/dist
var FrontFS embed.FS
```

复杂 React 节点放 package/module 自己的 `front/src/plugin.ts`，通过 `lazyNode` 按需加载；页面 JSON 没引用对应 node 时，不应加载对应业务 chunk。
