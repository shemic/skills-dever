# Front Page Site

站点运行契约属于组件 `dever.json.front.sites`，项目 `config/front.json` 或 `config/front.jsonc` 只覆盖展示配置。两者同时存在时优先读取 `config/front.json`。

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

`url` 永远写字符串数组，例如：

```json
{
  "config": {
    "url": ["https://admin.example.com"]
  }
}
```

不要写成字符串。`url` 只表示域名根路径绑定，不支持带 path、query 或 fragment。

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

## config/front.json / config/front.jsonc

项目覆盖文件只允许：

```json
{
  "sites": {
    "admin": {
      "name": "管理后台",
      "url": ["https://admin.example.com"],
      "logo": "config/assets/admin/images/logo.svg"
    }
  }
}
```

不能覆盖 `api/page/access/entry/public/auth/setting`。

`sites.<site>.url` 用来把域名根路径绑定到站点。命中 Host 后，`https://admin.example.com/` 直接进入 `admin` 站点，资源按 `/assets/...`、`/runtime.js`、`/plugins/...` 输出；同一域名下不再允许旧的 `/{site}` 路径，例如 `https://admin.example.com/admin/` 应返回 404。未命中 Host 或 IP 访问仍使用原来的 `/{site}` 路径，例如 `http://1.2.3.4:8086/admin/`。

Host 绑定命中后，后续 `/front/main/*`、`/front/route/*` 等 runtime API 也必须优先按 Host 绑定站点解析，避免多个站点共用默认 `/front` API 前缀时被 `admin` 抢先命中。不要把 Host 域名 rewrite 到 `/{site}`，也不要依赖 `/{site}/main/*` 或 `/{site}/route/*` 作为 Host 绑定后的 runtime API。

线上通过 nginx 或其它网关绑定域名时，反代到 Dever 后端根路径并保留 `Host`/`X-Forwarded-Host`；不要把域名 rewrite 到 `/{site}`，否则资源路径会和 runtime basePath 混在一起。

如果站点是模板渲染站点，Host 根路径也必须进入该站点的模板 route。例如 `mt_content` 原本通过 `/mt_content` 输出模板首页，配置 `url: ["https://www.example.com"]` 后，`https://www.example.com/` 应输出同一套模板页，而不是后台 runtime 壳。

nginx 反代示例：

```nginx
location / {
    proxy_pass http://127.0.0.1:8086/;

    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-Host $host;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection $connection_upgrade;
    proxy_http_version 1.1;
}
```

不要写 `proxy_set_header Host <后端 IP>`，否则 Dever 只能看到 IP，无法按 `sites.<site>.url` 匹配域名。域名启用 HTTPS 时，`url` 里也写 `https://...`，需要同时支持 HTTP 再额外加入 `http://...`。

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

页面 route 前缀由定义该站点页面的组件名决定，不由站点 key 或 `site.api` 决定。`site.api` 只用于接口前缀。

```txt
package/front 定义 admin 页面 -> front/login, front/main
module/mt 定义 mt_content 页面 -> mt/home, mt/article
```

模板页面的 `template.route` 以站点路径为前缀。未绑定 Host 时使用原始 `/{site}` 路径；绑定 Host 时站点路径视为 `/`，模板资源也按 `/assets/...` 输出。

## front 插件发现

插件按下面顺序自动发现：

```txt
front/dist/manifest.json > front/src/plugin.ts
```

`front/dist/placeholder.txt` 不算有效 dist。

普通插件不要手写 `setting.runtime.plugins`。只有外部 URL 插件或特殊 runtime 注入才显式配置。

`dever run` 只在缺少 dist manifest 且存在 `front/src/plugin.ts` 时启动插件 dev server。`dever build` 会先构建本地可编辑插件；外部 Go module package 如果有 `front/src/plugin.ts` 必须随发布携带 `front/dist/manifest.json`。
