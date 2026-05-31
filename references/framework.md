# Dever 框架速查

## 项目入口

标准入口：

```go
package main

import (
    "log"

    "my/data"
    _ "my/data/load"

    dever "github.com/shemic/dever/cmd"
)

func main() {
    if err := dever.Run(data.RegisterRoutes); err != nil {
        log.Fatal(err)
    }
}
```

如果启用 `package/front` 静态站点，入口可在 `dever.Run` 里同时注册：

```go
dever.Run(func(s server.Server) {
    data.RegisterRoutes(s)
    frontsite.Register(s)
})
```

## 命令

- `dever install`：安装本地 `dever` 启动脚本。
- `dever run`：热重载；启动前会执行 `init --skip-tidy`，model/service/api 变更后会再次刷新生成文件。
- `dever init --skip-tidy`：生成 routes/model/service 注册文件。
- `dever routes`：只生成 `data/router.go`。
- `dever model`：只生成 `data/load/model.go`。
- `dever service`：只生成 `data/load/service.go`。
- `dever migrate default`：按 `data/table` 应用表结构。
- `cd front && pnpm run build:backend`：构建主 `front` 运行时，输出到 `backend/package/front/html`；不包含 module/package 插件源码。
- `dever front build`：构建所有 `backend/package/*/front` 与 `backend/module/*/front` 插件前端。
- `dever front build bot`：只构建 `bot` 前端插件，输出到对应 `front/dist`。
- `dever package add bot`：从 `github.com/dever-package/bot` 拉取 package，创建 `module/bot/main.go` shim，并刷新生成文件。
- `dever package update bot`：更新已安装 package；默认要求 git 工作区干净并执行 `git pull --ff-only`。
- `dever build [target]`：发布构建；默认构建当前项目，`target` 可传目录或 `main.go`；默认先构建前端插件，再构建 Go 二进制。用户禁止 build 时不要运行。
- `dever build --skip-front`：只构建 Go 二进制，跳过 package/module 前端插件。

本地 replace 项目用 `go run ./dever/cmd/dever <cmd>`；普通项目用安装后的 `dever`。

## 生成文件

永远不要手改：

- `data/router.go`
- `data/load/model.go`
- `data/load/service.go`
- `data/table/*.json`

改源文件后让命令刷新。

## module 与 package

Dever 扫描 `module/*`。如果 `module/<name>/main.go` 有：

```go
// dever:import my/package/bot
```

这个 module 是 package 引入 shim，真实源码来自 package。应用开发时不要复制 package 代码，也不要改 package 源码；只通过引入、配置、page JSON、Provider hook 等公开能力复用。只有明确维护 package 本身时，新增页面、model、service、api 才放到真实 package。

可复用 Go package 与 package 自带前端插件的结构和命令看 `references/package-plugin.md`。
package 前端插件静态服务走 `package/front/service/plugin`，不要在每个组件里复制 `service/frontplugin`。

## 路由生成

扫描 `api` 目录里的结构体方法：

```go
func (User) GetList(c *server.Context) error
func (User) PostCreate(c *server.Context) error
```

生成：

- `GET /<module>/user/list`
- `POST /<module>/user/create`

`module/main` 特殊：不带模块前缀。

API 只取参、调用 Service、返回：

```go
id := util.ToUint64(c.Input("id", "required", "ID"))
return c.JSON(result)
```

## Load 注册

Model 扫描 `model` 目录里的导出函数，注册名：

```txt
<module>[.<model子目录>].<FuncName>
```

Provider 扫描 `service` 目录里 `Provider` 开头的方法，注册名：

```txt
<module>[.<service子目录>].<Receiver>.ProviderXxx
```

Provider 签名：

```go
func (Hook) ProviderBeforeSaveUser(c *server.Context, params []any) any
```

调用时用生成注册名，不猜。

## 配置

主配置是 `config/setting.json` 或 `config/setting.jsonc`。常用块：

- `http`
- `log`
- `observe`
- `database`
- `redis`
- `auth`
- `frontSite`

不要在业务代码里重复造配置系统。
