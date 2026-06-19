# 组件、Package、Module 和 Skill

在 Dever 里，从架构角度看 `module` 和 `package` 都是组件。`package` 是可复用、可分发组件；`module` 是项目本地业务组件，或者是引入 package 的 shim。

## 归属

- 应用业务代码放在 `module/<name>`。
- 可复用组件发布为 `github.com/dever-package/<name>` Go module；只有框架/package 开发仓库才在本地保留 `package/<name>` 源码。
- 如果 `module/<name>/main.go` 只有 `// dever:import github.com/dever-package/<name>`，真实源码来自 Go module package；本地开发可通过 go.mod replace 映射到 `package/<name>`。
- 不要为了定制行为把 package 代码复制到 module；优先用配置、page JSON、Provider hook、已暴露的 Service/API 或组件扩展点。

## 组件 Skill

复杂组件必须自带组件 skill：

```txt
package/bot/skills/SKILL.md
package/user/skills/SKILL.md
package/<name>/skills/SKILL.md
```

修改组件前，先检查组件内是否存在 `skills/**/SKILL.md` 并阅读。没有组件 skill 时，按 `shemic-dever` 和当前项目本地示例执行；如果改动涉及自定义 Service/API、多 model、权限、front 插件、外部集成或特殊生命周期，先补组件 skill，再改组件。

简单 CRUD 组件可以不带组件 skill。只要组件包含自定义 Service/API、多 model、权限、front 插件、外部集成或特殊生命周期，就应该有组件 skill。

组件内置 skill 在组件 `dever.json` 里声明，路径相对组件根目录：

```json
{
  "skills": [
    "skills/SKILL.md"
  ]
}
```

新增或移动组件 skill 后运行 `dever skill doctor`。它只校验 active 组件，所以未启用的 package 不会阻塞当前项目。

组件 skill 约束：

- frontmatter `description` 用触发条件描述，优先以 `Use when` 开头，不写流程摘要。
- 默认使用项目主要语言；当前项目面向中文协作时，组件 skill 正文使用中文。
- `硬规则` 必须写清：禁止 CRUD wrapper、禁止生成文件/编译产物、公开 API 边界、权限边界、升级影响。
- `事实来源` 必须列出 model、service、api、front/page、front/src、dever.json 的真实路径；不要只写概念。
- 公开路径、菜单、站点壳、依赖和 skill 声明必须回到组件 `dever.json`，不要散落到项目级配置。

`package/front` 是特殊核心组件。它可以没有独立组件 skill，但维护前必须同时读取 `front-page.md`、`package-plugin.md`、`security.md` 和 `framework.md`；只能加入通用 runtime 能力，不能承载某个业务组件的私有逻辑。

## dever.json

组件元数据应该随组件发布，不要求每个项目都重写 `front.json`。

`dever.json` 可以描述：

- name/title/version
- dependencies
- `front.sites` 站点壳、页面目录、API 前缀、访问模式、入口、菜单权限、默认展示配置
- `front.public` 全局公开 API path
- static assets
- 必要的 install/update hook
- bundled skills

`dever.json` 必须保持声明式，不放业务逻辑。

front 站点运行契约归属于组件；项目级 `config/front.json` 只允许覆盖 `sites.<site>` 展示配置，不允许覆盖 `api/page/access/entry/public/auth/setting`。示例：

```json
{
  "front": {
    "public": ["/user/auth/login"],
    "sites": {
      "work": {
        "api": "work",
        "page": "work",
        "config": {
          "name": "工作台",
          "logo": "work/assets/work/images/logo.svg",
          "favicon": "work/assets/work/images/favicon.svg"
        },
        "access": {
          "mode": "login",
          "authProvider": "user"
        },
        "entry": "work/home",
        "public": ["login"]
      }
    }
  }
}
```

站点 key 是全局命名空间：

- `admin` 是共享站点，允许多个组件只追加 `auth/public`；站点壳字段由 `front` 组件定义。
- 非 `admin` 站点默认只能有一个 owner 组件定义 `api/page/access/config/setting/entry`。
- 多个组件定义同一个非 `admin` 站点壳时必须报错，不允许按加载顺序覆盖。
- 如果组件只是扩展别人拥有的站点，只写 `auth` 或 `public`，不要写壳字段。
- `access.mode` 支持 `rbac`、`login`、`public`：`rbac` 登录并校验权限，`login` 只要求登录，`public` 整站匿名开放但仍走 page/action 的服务端安全边界。
- `setting.appearance` 和 `setting.runtime.skin/routerMode` 有 front 默认值，普通业务站点不要重复写；`package/front` 的 `admin` 壳可以保留显式 setting 作为默认后台配置。
- 组件前端插件按 `front/dist/manifest.json > front/src/plugin.ts` 自动发现；`front/dist/placeholder.txt` 不算有效 dist。不要在 `dever.json.front.sites` 为常规插件手写 `runtime.plugins`。外部插件只有在协议明确提供可匹配的 `nodes` 描述时才考虑配置，否则也不要写 `runtime.plugins`。

## 依赖

安装组件时：

- 缺少依赖且安全时，先自动安装依赖。
- 依赖冲突必须清晰报错。
- 其他组件仍依赖时，不要删除共享依赖。

卸载组件时：

- 检查反向依赖。
- 只移除组件自己拥有的 menu/auth/page/static 条目。
- 用户数据删除必须作为显式破坏性操作，不跟随普通卸载自动执行。

## Front 资源和插件

组件 front 源码属于：

```txt
package/<name>/front/src/plugin.ts
module/<name>/front/src/plugin.ts
```

Page JSON 属于：

```txt
package/front/front/page/<page>/...
package/<name>/front/page/<page>/...
module/<name>/front/page/<page>/...
```

不要为了组件功能修改全局 `front/src`。不要修改 `front/dist` 里的编译产物。

## 组件 Skill 骨架

使用 `scripts/component-skill.sh` 或 `files/component/skills/SKILL.md.tmpl` 创建组件 skill。组件 skill 应包含：

- 组件用途。
- 事实来源文件。
- 核心 model。
- 已有页面。
- 允许写 Service/API 的场景。
- 禁止的捷径。
- 公开 API、权限和密钥边界。
- front 插件规则。
- 常见错误。
- 升级说明。
