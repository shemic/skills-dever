# 空项目多站点系统接入流程

适用场景：空目录、最小 Dever 项目、或刚初始化的项目需要搭任意基于 `front` site 的系统，包括管理后台、工作台、业务前台、运营系统、门户等。这里说的是空项目 site 基线，不是某个行业系统；只有用户明确给出业务资源时，才命名具体业务模块。

## 1. 参考源

主要对照 `dever-project/demo`：

- 仓库：https://github.com/dever-project/demo
- 入口参考：`main.go`
- 配置参考：`config/setting.jsonc`、`config/front.json`
- package shim 参考：`module/front/main.go`、`module/bot/main.go`
- 页面参考：`module/*/front/page/{page}/...`

参考 demo 的结构和配置意图，不要复制 demo 的业务模块。demo 的重点是：项目入口注册 `front` 站点服务，`config/front.json` 用 `sites` 定义不同系统，业务页面放在 `front/page/{page}` 目录下。当前页面目录按本 skill 的规则放到 `front/page/{page}`，不要退回旧的 `module/<name>/page` 写法。

## 2. 空项目最小骨架

Dever 应用项目的 Go module 固定使用 `my`。不要按项目名、公司域名或目录名改成其他 module path；`module/front`、`module/bot` 等组件 shim 依赖 `my/package/...`，改名会导致 package 组件不可用。

`go.mod` 第一行保持：

```go
module my
```

空项目先补项目骨架，再按 site 补系统和业务：

```txt
go.mod
main.go
config/setting.jsonc
config/front.jsonc
data/readme.txt
package/readme.txt
module/main/api/ping.go      # 可选健康检查
module/front/main.go         # package/front shim
module/bot/main.go           # package/bot shim
```

`data/router.go`、`data/load/*.go`、`data/table/*.json` 都由 Dever 生成，不手写、不手改。

## 3. 空项目默认 package

用户说“新建项目”、“空项目”、“搭系统”、“搭站点”、“搭后台”、“admin”、“work”、“使用 front 组件”时，site 系统基线同时引入 `front` 和 `bot`，不要只装 `front`：

```bash
dever package add --skip-init front
dever package add --skip-init bot
dever init --skip-tidy
```

如果只装单个 package，可以不加 `--skip-init`；一次补多个 package 时，先 `--skip-init`，最后只运行一次 `dever init --skip-tidy`。

安装后确认：

- `package/front`、`package/bot` 已存在。
- `module/front/main.go` 是 `// dever:import my/package/front` shim。
- `module/bot/main.go` 是 `// dever:import my/package/bot` shim。
- package 源和 shim 里的 `my/package/front`、`my/package/bot` 是固定路径，不要替换成项目名或当前目录名。

## 4. 配置顺序

先配置 `config/setting.jsonc`：

- `log.output="file"`，不要用 `stdout`。
- `log.successFile="data/log/access.log"`。
- `log.errorFile="data/log/error.log"`。
- 常规访问日志和错误日志写到 `data/log`，不要刷到 `dever run` 屏幕。
- `http.port`、`http.appName` 使用项目值。
- `frontSite.enabled=true`。
- `frontSite.path` 使用项目主入口，例如 `/admin`、`/work` 或用户指定路径。
- `frontSite.dir` 指向 `package/front/html`。
- 数据库按用户指定环境配置；如果用户指定 PostgreSQL，直接设置 `driver=postgres`、目标 `dbname`、项目 `prefix`，不要先落 SQLite 再切。

最小日志配置：

```jsonc
{
  "log": {
    "level": "info",
    "development": false,
    "enabled": true,
    "output": "file",
    "successFile": "data/log/access.log",
    "errorFile": "data/log/error.log"
  }
}
```

再配置 `config/front.jsonc`：

- 每个系统对应一个 `sites.<siteKey>`，例如 `admin`、`work`、`portal`、`shop`。
- `sites.<siteKey>.api` 使用该系统的 API 分组；后台通常为 `front`，业务前台可按 demo 的 `work` 站点方式配置。
- `sites.<siteKey>.page` 决定物理页面目录，页面放到 `front/page/{page}/...`；`siteKey` 和 `page` 可以同名，也可以不同名。
- `sites.<siteKey>.access` 使用该系统需要的登录、RBAC 或公开访问模式。
- `public` 保留上传、站点信息、bot 回调/请求等 package 需要的公开路径。
- 菜单只放当前 site 的真实功能分组；bot 自带页面按 package 能力接入，不要复制页面实现。

一个后台 `admin` 加一个前台 `work` 的最小形态：

```jsonc
{
  "public": [
    "/upload/*",
    "/site/info",
    "/bot/energon/request",
    "/bot/energon/demo"
  ],
  "sites": {
    "admin": {
      "name": "管理后台",
      "api": "front",
      "page": "admin",
      "access": {
        "mode": "rbac",
        "authProvider": "front"
      },
      "public": ["auth/login"],
      "auth": []
    },
    "work": {
      "name": "工作台",
      "api": "work",
      "page": "work",
      "access": {
        "mode": "login",
        "authProvider": "work"
      },
      "public": ["auth/login", "auth/register"],
      "auth": []
    }
  }
}
```

含义：

- `admin` 是后台站点，普通 CRUD 走 `Model + page JSON`，页面放 `front/page/admin`。
- `work` 是前台站点，页面放 `front/page/work`，登录注册和复杂业务动作可放 `module/work/api`。
- `siteKey` 决定访问路径和 runtime，例如 `/admin/runtime.js`、`/work/runtime.js`。
- `page` 只决定物理页面目录，不进入最终 route。

## 5. 入口注册

空项目安装 `front` 后，入口要注册站点服务：

```go
import (
	"log"

	"my/data"
	_ "my/data/load"
	frontsite "my/package/front/service/site"

	dever "github.com/shemic/dever/cmd"
	"github.com/shemic/dever/server"
)

func main() {
	if err := dever.Run(func(s server.Server) {
		data.RegisterRoutes(s)
		frontsite.Register(s)
	}); err != nil {
		log.Fatal(err)
	}
}
```

`bot` 通过 package/module shim、生成注册和页面/接口能力接入；没有 package 文档要求时，不在 `main.go` 里额外硬编码 bot 注册。

## 6. 后续业务资源

空项目 site 立住后，新增普通资源走标准路径：

1. `module/<biz>/model/<resource>.go`
2. `module/<biz>/front/page/{page}/<resource>/list.json`
3. `module/<biz>/front/page/{page}/<resource>/update.json`
4. `dever init --skip-tidy`

普通列表、录入、编辑、详情不要默认写 API/Service。只有状态流转、跨表保存、强校验、外部协议、异步任务、聚合查询等真实业务规则，才补 Service/API。

后台页面例子：

```txt
module/product/model/goods.go
module/product/front/page/admin/goods/list.json
module/product/front/page/admin/goods/update.json
```

前台页面例子：

```txt
module/work/front/page/work/main.json
module/work/front/page/work/home.json
module/work/front/src/plugin.ts              # 可选，复杂 React 节点才需要
module/work/front/src/nodes/home/home.tsx    # 可选
```

## 7. 交付检查

交付前至少静态确认：

```bash
rg -n "my/package/(front|bot)|module/front|module/bot|frontSite|sites" .
bash skills/skills-dever/scripts/audit.sh <改动文件或目录>
```

如果用户明确禁止 build/test，不运行 `dever build`、`dever front build`、`npm run build`、测试命令。若为了验证临时启动服务，结束前要关闭进程，除非用户明确要求保留。
