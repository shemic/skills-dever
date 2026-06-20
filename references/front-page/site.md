# Front Page Site

站点运行契约属于组件 `dever.json.front.sites`，项目 `config/front.json` 只覆盖展示配置。

## dever.json.front.sites

允许字段：

```txt
api
page
config
setting
access
entry
public
auth
```

`config` 只允许：

```txt
name
subtitle
description
url
logo
favicon
```

不要在 `front.sites.<site>` 写其它自定义字段。

## api

`api` 用来声明该组件给站点提供的 API 前缀：

- 站点主组件写完整契约：`api/page/config/setting/access/entry`。
- 其它组件只想给已有站点追加接口时，只写 `api/auth/public`，不要重复写 `page/config/setting/access/entry`。
- `api` 单独出现不抢占站点所有权，可以有多个组件给同一个站点追加 API 前缀。
- API 路由由目录自然生成：`api/admin/team.go` -> `/组件名/admin/team/...`。

常用写法：

```json
{
  "front": {
    "sites": {
      "admin": { "api": "bot/admin" },
      "body": {
        "api": "bot/body",
        "page": "body",
        "access": { "mode": "login", "authProvider": "user" }
      }
    }
  }
}
```

不要新增 `apiAliases`、`apiRoots`、`internal` 等字段。需要站点隔离时拆 `api/<scope>` 目录并声明对应 `api`。

## config/front.json

项目覆盖文件只允许：

```json
{
  "sites": {
    "admin": {
      "name": "管理后台",
      "logo": "config/assets/admin/images/logo.svg"
    }
  }
}
```

不能覆盖 `api/page/access/entry/public/auth/setting`。

## access

- `rbac`：后台权限树，默认后台。
- `login`：需要登录但不走后台 RBAC，适合工作台。
- `public`：匿名站点，但服务端仍需输入校验、字段过滤和业务边界。

公开 route 写在：

```txt
dever.json.front.public
dever.json.front.sites.<site>.public
```

不要靠不写 auth 绕权限。

## shell

- `app`：后台壳，侧边栏、顶栏、命令面板。
- `blank`：只渲染页面基础上下文。

`rbac/admin` 默认适合 `app`；`public/login` 站点默认适合 `blank`。只有确实复用后台壳时才显式写 `shell: "app"`。

## 页面目录和 route

`front/page/{page}/...` 里的 `{page}` 是物理目录，来自 site 的 `page` 字段。它不自动进入 route。

站点系统页由 `site.api` 决定：

```txt
api: "front" -> front/login, front/main
api: "crm/work" -> crm/work/login, crm/work/main
```

## front 插件发现

插件按下面顺序自动发现：

```txt
front/dist/manifest.json > front/src/plugin.ts
```

`front/dist/placeholder.txt` 不算有效 dist。

普通插件不要手写 `setting.runtime.plugins`。只有外部 URL 插件或特殊 runtime 注入才显式配置。

`dever run` 只在缺少 dist manifest 且存在 `front/src/plugin.ts` 时启动插件 dev server。`dever build` 会先构建本地可编辑插件；外部 Go module package 如果有 `front/src/plugin.ts` 必须随发布携带 `front/dist/manifest.json`。
