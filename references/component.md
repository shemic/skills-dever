# Component、Package、Module

Dever 里 `module` 和 `package` 都是组件。`module` 是项目本地业务组件或 package shim；`package` 是可复用 Go module。

## 组件来源

- 应用业务放 `module/<name>`。
- 可复用组件发布为 `github.com/dever-package/<name>`。
- 普通项目安装组件使用 `dever package <name>`。
- 框架/package 开发仓库可以保留本地 `package/<name>` 并通过 go.mod replace 接入。

`module/<name>/main.go` 是 package shim 时：

```go
package bot

// dever:import github.com/dever-package/bot
```

不要为了定制行为复制 package 源码到 module。优先使用配置、page JSON、Provider hook、Service/API 或组件扩展点。

## dever.json

组件元数据随组件发布。

允许表达：

- `name/version/description`
- `depends/optionalDepends`
- `skills`
- `front.public`
- `front.sites.<site>.api/page/config/setting/access/entry/public/auth`

`front.sites.<site>.config` 只放展示配置：`name/subtitle/description/url/logo/favicon`。

`front.sites.<site>.api` 是站点 API 前缀声明：

- 站点主组件同时写 `page/config/setting/access/entry`。
- 扩展已有站点的组件只写 `api/auth/public`。
- 自定义 API 目录和声明要对应：`api/admin/*.go` 对应 `api: "<component>/admin"`。
- 不写 `apiAliases`、`apiRoots` 或其它站点自定义字段。

## 组件 skill

复杂组件必须带组件 skill，并在 `dever.json` 声明：

```json
{
  "skills": ["skills/SKILL.md"]
}
```

修改组件前先读取组件 skill。当前组件已有：

```txt
backend/package/front/skills/SKILL.md
backend/package/bot/skills/SKILL.md
backend/package/crm/skills/SKILL.md
backend/package/source/skills/SKILL.md
backend/package/user/skills/SKILL.md
```

组件 skill 只写组件私有边界，不重复全局 Dever 协议。

## package/front

`package/front` 是核心 runtime，只能放通用能力：

- page JSON 解析
- action
- option
- permission
- siteconfig
- upload/import/export
- runtime/plugin loading

不要把 bot/crm/user/source 的私有业务逻辑塞进 `package/front`。

## front 插件发布

组件 front 插件按：

```txt
front/dist/manifest.json > front/src/plugin.ts
```

发布 package 如果带 `front/src/plugin.ts`，必须携带有效 `front/dist/manifest.json`。`placeholder.txt` 不算 dist。

`dever run` 只为本地可编辑且没有 dist manifest 的插件启动 dev server。
