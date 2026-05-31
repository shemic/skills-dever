# Package / Front Plugin 规则

用于维护可复用 Go 组件，或给 package/module 增加前端插件。普通业务开发不要改 `backend/package/*`，除非用户明确要求维护 package。

## 1. Go package 组件

真实代码放 package：

```txt
backend/package/<name>/
  <name>fs.go
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

package 需要前端插件静态资源时，在应用 `main.go` 使用 `package/front/service/plugin` 注册，并放在 `frontsite.Register(s)` 之前。

## 3. Package 前端插件目录

复杂 React 节点不要塞进主 `front/src`，放 package 自己的 `front`：

```txt
backend/package/<name>/front/
  page/{page}/
  src/
    plugin.ts
    runtime.ts
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

开发态 `cd front && pnpm dev` 会直接扫描：

```txt
backend/package/*/front/src/plugin.ts
backend/module/*/front/src/plugin.ts
```

所以开发时改 `front/src` 不需要先打包插件。

多站点 front 只记一条：站点配置在 `config/front.json.sites`，页面目录是 `front/page/{page}`，业务前台优先放 `module/<name>`，可复用能力放 `package/<name>`。

## 4. 插件入口模板

`plugin.ts` 只注册能力，不做副作用：

```ts
import { defineFrontPlugin, lazyNode } from '@/lib/plugin/types'

export default defineFrontPlugin({
  name: 'bot',
  nodes: {
    'show-agent': lazyNode(() =>
      import('./nodes/show/agent').then((mod) => ({ default: mod.ShowAgent }))
    ),
  },
})
```

`runtime.ts` 只给发布态注册已有插件能力：

```ts
import plugin from './plugin'

window.DeverFront?.registerPlugin(plugin)
```

节点组件使用主 front 的 SDK 和组件：

```ts
import type { NodeItemProps } from '@/page/nodes'
import { Button } from '@/components/ui/button'
```

不要在插件里复制主 front 的 UI、请求、上传、agent runner、类型。

## 5. React 依赖规则

插件前端不能自己打包一份 React。

- 开发态：主 `front` 的 Vite alias / dedupe 提供同一份 React。
- 发布态：插件构建必须 external `react`，由主 front 暴露 `window.React`。
- 不要在插件 `package.json` 里单独升级 React。

如果出现 hook 报错，先查是否打了两份 React。

## 6. 构建命令

开发：

```bash
cd front
pnpm dev
```

发布前构建所有插件前端：

```bash
dever front build
```

只构建某个插件：

```bash
dever front build bot
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

插件构建产物输出到自己的 `front/dist`。page JSON 放 `front/page`。package 用 `go:embed` 带进二进制：

```go
//go:embed front/page
var PageFS embed.FS

//go:embed front/dist
var FrontFS embed.FS
```

复杂 React 节点放 package/module 自己的 `front/src/plugin.ts`，通过 `lazyNode` 按需加载；页面 JSON 没引用对应 node 时，不应加载对应业务 chunk。

注册示例：

```go
frontplugin.Register(s, frontplugin.Options{
  Name: "bot",
  FS: botroot.FrontFS,
})
```

注册顺序要在 `frontsite.Register(s)` 之前，避免被后台 SPA 路由吞掉。不要给每个 package 复制一份 `service/frontplugin`。
