# Front Page JSON 规则

普通后台和简单站点页面优先使用 `package/front` page JSON。只有页面确实需要画布、图编辑器、工作台、领域实时交互这类自定义交互界面时，才写 React 插件节点。

**核心原则**：能自动推导的不写。page JSON 只写"页面结构和业务字段"，标签、选项、排序、默认值、权限尽量来自 model 元信息和路径推导。

## 参考顺序

按这个顺序查示例：

1. 当前 `package/front/page` 和 `package/front/service/page`。
2. 当前 `package/bot/front/page`。
3. 如果已安装，查当前 `package/user/front/page`。
4. 当前项目已有 module/package 页面。
5. 只有当前项目没有可比示例时，才看外部 demo。

当前 `package/front` 已支持的能力，不要继续按旧项目页面写法实现。

## 文件位置和路径

页面 route 由所属目录和文件路径决定：

```txt
package/front/page/admin/account/list.json       -> front/account/list
package/bot/front/page/admin/agent/list.json     -> bot/agent/list
module/work/front/page/work/home.json            -> work/home
```

`front/page/{page}` 里的 `{page}` 来自 active 组件 `dever.json.front.sites.*.page`，只用于物理目录隔离，不会自动进入 route。站点系统页使用 `front.sites.*.api`：

- `api: "front"` 读取 `front/login` 和 `front/main`。
- `api: "work"` 读取 `work/login` 和 `work/main`。

其他站点复用 admin 壳时，要在该站点自己的目录创建 `main.json` 和 `login.json`，不要硬编码 `/front/auth/login`。

站点定义随组件发布：

- `package/front/dever.json.front.sites.admin` 定义后台壳。
- 业务前台组件在自己的 `dever.json.front.sites.<siteKey>` 定义 `api/page/access/entry/public`。
- `admin` 可以被多个组件追加 `auth/public`；非 `admin` 站点只能由一个组件定义壳字段，避免同名站点被静默覆盖。
- `access.mode` 支持 `rbac`、`login`、`public`。公开展示或演示站点使用 `public`，不需要登录；只需登录但不走权限树的工作台使用 `login`。
- `setting.appearance` 和 `setting.runtime.skin/routerMode` 已有 front 默认值，普通业务站点不要重复写；`package/front` 的 `admin` 壳可以保留显式 setting 作为默认后台配置。
- 本地组件前端插件由 active 组件的 `front/src/plugin.ts`、发布态 `front/dist/manifest.json` 或 embed 产物自动发现，不要为常规本地插件手写 `setting.runtime.plugins`。

## 必需结构

每个 page JSON 都必须保留这些顶层对象，即使内容为空：

```json
{
  "page": {},
  "layout": {},
  "nodes": {},
  "data": {},
  "state": {},
  "action": {}
}
```

缺少 `data`、`state` 或 `action` 常会导致 schema/runtime 空值错误。

## 服务端模板页面

公开内容站、演示站、CMS 类 SEO 页面可以使用 `package/front` 的服务端模板渲染能力。它不替代现有 JSON/React 页面，只在页面声明 `page.render: "template"` 时生效。

模板页面仍必须保留六对象规则：

```json
{
  "page": {
    "name": "文章详情",
    "render": "template"
  },
  "layout": {},
  "nodes": {},
  "data": {
    "article": {
      "_model": "mt.NewArticleModel",
      "one": true,
      "required": true,
      "defaultFilters": {
        "slug": "$route.slug",
        "status": "published"
      }
    },
    "seo": {
      "title": "$data.article.title",
      "description": "$data.article.summary",
      "canonical": "/article/${data.article.slug}"
    }
  },
  "state": {},
  "action": {},
  "template": {
    "route": "/article/:slug",
    "layout": "layout.html",
    "view": "article.html"
  }
}
```

规则：

- `page.render: "template"` 表示该 page 由 Go `html/template` 服务端输出完整 HTML。
- 顶层 `template` 只放渲染元信息：`route`、`layout`、`view`。不要把模板配置塞进 `nodes`；`nodes` 保持 React/runtime 节点语义。
- SEO 数据放在 `data.seo`，渲染后模板上下文提供 `.SEO.Title`、`.SEO.Description`、`.SEO.Image`、`.SEO.Canonical`。
- `data` 支持模板站最小数据能力：`_model`、`one: true`、`required: true`、`defaultFilters`、`pageSize`、`order`、`type: "service"` + `service`。
- `defaultFilters`、`data.seo` 等模板值支持 `$route.xxx`、`$query.xxx`、`$site.xxx`、`$data.xxx`。
- 单条数据设置 `required: true` 时，查询不到记录返回 404。
- 模板访问路径是 `/{site.api}{template.route}`。例如 site `api: "mt"` + `route: "/article/:slug"`，访问 `/mt/article/hello`。
- 模板路由不要占用站点保留根路径：`main`、`route`、`upload`、`resource`、`import`、`export`、`runtime.js`、`assets`。

模板和资源随组件发布：

```txt
module/mt/front/page/mt_content/article.json
module/mt/front/template/mt_content/layout.html
module/mt/front/template/mt_content/article.html
module/mt/front/template/mt_content/partials/header.html
module/mt/front/assets/mt_content/css/site.css
module/mt/front/assets/mt_content/images/logo.png
```

模板文件默认从当前 site 的 `page` 目录隔离读取。上例 site `page: "mt_content"`，所以 `template.view: "article.html"` 会读取 `front/template/mt_content/article.html`。

静态资源访问路径是 `/{site.api}/assets/{file}`，模板上下文提供 `.Site.AssetBase`：

```html
<link rel="stylesheet" href="{{ .Site.AssetBase }}/css/site.css">
<img src="{{ .Site.AssetBase }}/images/logo.png" alt="">
```

项目级资源覆盖放在：

```txt
config/front/assets/<siteKey>/
```

读取优先级：项目覆盖资源优先，其次是组件内置 `front/assets/<site.page>/...`。

## `page` 对象

`page` 只写业务必需的少量字段，其余自动推导：

- `name`：必填。中文名，菜单、面包屑、弹窗标题都用它。
- `parent`：可点击列表页必填，父级分组或父级页面 route（例如 `user-config` 或 `user/identity/list`）。删除 `parent` 会让权限同步把页面作为顶层菜单处理。
- `type`：按需。`1` 列表/独立页（可出现在菜单），`2` 弹窗/抽屉/嵌入子页（不出现在菜单）。不写时按 path 推导：`/list` 后缀→1，`/update`/`/create`/`/edit`→2。
- `icon`：仅 `type: 1` 且会作为菜单项时才写。
- `sort`：同级菜单排序，按需。
- `auth`：见下方"权限"章节。
- `title`/`description`：按需。`show-title` value=`page` 且不写 `data.page.title` 时，框架按 path 自动推导 model 中文名作为标题。

## 权限

`page.auth` 不写时，框架按 route path 自动构造一个默认权限项（key=path, name=path）。普通列表页可以不写。

需要区分 create/update 两个权限点时（例如 update 页被 `feedback-modal` 引用），显式声明：

```json
"auth": [
  { "key": "user/identity/create", "name": "身份新增", "query": { "id": "empty" } },
  { "key": "user/identity/update", "name": "身份编辑", "query": { "id": "required" } }
]
```

- `query.id == "empty"`：新增（id 为空时匹配）。
- `query.id == "required"`：编辑（id 非空时匹配）。
- 两个权限点对应同一 update 页，权限同步会注册两个权限项，可分别授权。
- `name` 必须用中文，不要让权限表退化成 route path 名称。
- 公开页面必须在组件 `dever.json.front.sites.<site>.public` 或 `dever.json.front.public` 显式声明，不要靠"不写 auth"来绕过权限。

## Model 推导

标准页面后缀会从路径自动推导 model：`list`、`update`、`create`、`view`、`detail`、`info`。

标准页面不要写：

- `data.table.list: "<<...NewXxxModel>>"`
- `data.form._model`
- `data.form._use`
- `action.submit.use`
- `<<NewXxxModel>>` in page JSON

如果推导失败，修 model 文件名、`NewXxxModel`、所属路径或 page path。不要为了省事硬编码 model。

只有 `set`、`config`、固定单记录页、跨资源嵌入页、真实自定义流程这类非标准页面，才显式声明 model。

## Model 元信息是来源

可复用元信息放在 model，page JSON 不要重复写：

- `dorm:"comment:..."` → 字段标签、列名、表单 label。
- `Options` → 枚举选项（`form-radio`/`form-checkbox`/`form-select`/`show-tag` 自动用）。
- `Relations` → 关联选项（`form-select` 外键字段自动用）。
- 索引和 `Order` → 列表默认排序。
- `default` tag → 新增表单字段默认值。

只有页面展示语义确实不同于 model 时，page JSON 才覆盖展示文案。

## Layout 和 Nodes

`layout` 声明结构，`nodes` 把 UI 节点绑定到 layout ID。不要发明节点类型，先查 `package/front`。

常见节点：

```txt
show-title, show-base, show-date, show-tag, show-table, show-button, show-page, show-select, show-category-list
form-input, form-textarea, form-number, form-switch, form-radio, form-checkbox, form-select, form-date, form-upload
feedback-modal, feedback-drawer, feedback-confirm
nav-tab
app-site-brand, app-login-form, app-sidebar, app-topbar, app-outlet, app-assistant
```

控件选择：

- 固定 2-4 项单选枚举：`form-radio`。
- 固定少量多选枚举：`form-checkbox`。
- 多选项、远程选项、关联选项、可搜索选项：`form-select`。
- 布尔值或列表状态切换：`form-switch`。
- 列表内联排序/顺序编辑：`form-number` 或已有列表编辑器。

`option` 来源（按优先级，能不写就不写）：

1. **不写 `option`**：`form-select` 外键字段（`xxx_id`）自动从 model `Relations` 推导；`form-radio`/`form-checkbox`/`show-tag` 枚举字段自动从 model `Options` 推导。这是最优先的默认。
2. `option: "option.<field>"`：从 `data.option.<field>` 取，常用于 `show-category-list` 本地加载的选项。
3. `option: { "model": "<module>.NewXxxModel", "order": "..." }`：显式指定 model，用于 Relations 推导不出来的场景。
4. `option: { "type": "service", "service": "<module>.<Svc>.<Method>" }`：远程选项，model 推导不出来时才写。
5. `option: [...]`：硬编码少量选项，仅用于页面级展示语义，不要替代 model Options。

不要在 `form-select` 里硬编码业务选项数组来绕过 model Options。

## 列表页

标准列表页结构：

```txt
page-header  -> show-title + 顶部操作按钮
page-main
  toolbar-row -> 搜索控件 + 搜索/重置按钮
  table-row   -> show-table + show-page
  feedback-shell -> feedback-modal / feedback-confirm
```

`data.table` 字段全部按需，框架有默认值：

- `page`：默认 1。
- `pageSize`：默认 10。
- `total`：默认 0，运行时自动填充。
- `list`：不需要写；运行时按 model 自动加载。可以写 `"list": []` 作为空容器，但不要写 `"<<...NewXxxModel>>"`。
- `searchFields`：按需。模糊搜索字段，对应 `data.search.keyword` 走 LIKE。不写则不支持关键词搜索。
- `filterFields`：按需。精确过滤字段，对应 `data.search.<field>` 走等值。不写则不支持筛选。
- `order`：按需。默认排序，不写时用 model `Order`。

表包含 `CreatedAt` 且需要按时间排查时，搜索栏使用 `form-date` 范围筛选，`value`/`endValue` 对应 `search.created_at_start` 和 `search.created_at_end`，并在 `filterFields` 中声明 `date-range`。

搜索栏复用当前 `package/front` 或 `package/bot` 的 toolbar 写法：

- `toolbar-row` 使用 `flex-wrap items-center gap-2.5` 或 `gap-3`。
- 搜索控件不要写固定 `controlClassName` 宽度，除非确实需要窄控件。
- 搜索按钮 `variant: "default"`、`size: "sm"`、`searchSubmit: true`、`searchLayoutId: "toolbar-row"`、`loadingText: "搜索中..."`。
- 有筛选条件时提供"重置"按钮，`meta.to` 指向当前列表页路径。

`status`/`sort` 这类列表维护字段保留在表格内联维护，不要为它们新增 update 表单。规则见下方"内联编辑"章节。

`dever.json.front.sites.<site>.auth` 只声明模块级菜单分组，例如"内容管理 / 内容 / 配置"。具体可点击列表页由对应 `list.json` 的 `page.parent` 挂到分组。不要在 `auth.children` 里重复声明同一个具体页面，否则会和权限同步生成的菜单重复。

## 左分类右列表

左分类右列表页面必须把分类 model/data 和主表列表分开绑定。分类选中 ID 可以进入 search/query 状态，但分类列表不能复用其他页面缓存的分类状态。

远程左分类右列表页面，把 `show-category-list.value` 绑定到对应搜索字段（`parent.data.search.<field>` 嵌入父列表页，`search.<field>` 或 `data.search.<field>` 同页）。`meta.remote: true` + `meta.defaultFirst: true` 让分类远程加载并默认选中第一项。

通用 front runtime 会重置 `data.table.page` 并通过 page JSON 重新加载对应数据容器；不能为了刷新列表而 navigate 到 `?cate_id=...`。普通分类/列表刷新不要新增单页 service。只有 URL 必须同步当前分类时才设置 `meta.syncQuery: true`，并且仍以本地数据容器刷新作为数据来源。

`show-category-list` 上的状态切换和拖拽排序由 `meta.statusChangeAction` / `meta.sortChangeAction` 触发。这两个 action 必须是 `type: "save"` 且带 `_partial: true` 的部分更新，规则见下方"内联编辑"章节。

## 编辑/新增页

标准编辑/新增页：

- 使用推导 model 和默认 submit，不硬编码 `submit.use`。
- `status` 或 `sort` 如果是列表维护字段，不放进编辑表单（新增时需要初始化除外）。
- 只放用户真正需要编辑的字段。
- 用作 `pageRoute`、modal/drawer 内容、嵌入子页、`savePath` 或任意 action 目标时，必须给它明确表达用途的 `page.name` 和 `page.parent`。

`data.form` 只写需要非 model 默认值的字段，其余自动推导：

- `id`：默认 `""` 表示新增。编辑时框架按 route query `id` 自动加载记录。
- `status`/`sort`：不写时用 model `default` tag（通常 `status: 1`、`sort: 100`）。
- 枚举字段：不写时用 model `default` tag；model 没写 default 时才在 page JSON 给。
- 关联外键字段：不写时为空，`form-select` 显示占位符；如果业务要求新增时默认选中某项，才写默认 ID。

只有以下情况才需要显式写 `data.form` 字段：

- 字段默认值和 model `default` tag 不同。
- 字段不在编辑表单里，但需要给非空默认值（例如 `purchase_point_id: 1`）。
- 新增时需要从父页状态注入默认值（配合 `feedback-modal` 的 `pageDataPatches`）。

上传型字段（图片、视频、音频、附件、封面图、头像、资源路径）必须使用 `form-upload`：

- 图片使用 `kind: "image"`，普通附件使用 `kind: "file"`。
- 复用已有上传规则配置 `ruleId`、`bizKey`、`bizName`。
- 富文本内嵌媒体使用支持 `uploadRules` 的编辑器。
- 不要用 `form-input` 让用户手填资源路径。

嵌套表、子记录、嵌入弹窗必须声明自己的 page/action 上下文。不要为了让子弹窗能用而放宽权限。

## `action.submit` 与部分更新

`action.submit` 是标准保存入口。

**最小配置**（普通 CRUD 默认走这个）：

```json
"submit": {
  "type": "save",
  "params": "form"
}
```

`params: "form"` 提交整个 `data.form`，框架按 model 字段自动 sanitize。**普通 CRUD 不写 `data` 模板、不写 `before`/`after` hook。**

**何时写 `data` 模板**：

- 不需要派生字段时，**不写 `data`**，让 `params: "form"` 全量透传。这是最安全的默认。
- 只有需要重命名字段、聚合字段（例如 `accept_type_id: "$form.accept_type_ids.0"`）、过滤敏感字段时，才写 `data`。

**写 `data` 模板时的硬规则**：

`data` 模板必须包含 model 中所有可被 partial save 触及的字段，至少包括：

- `id`：`"$form.id"`
- 所有编辑表单字段
- 所有列表维护字段：`status`、`sort`（即使不在编辑表单里，也要写 `"status": "$form.status"`、`"sort": "$form.sort"`）

否则列表 `statusChangeAction`、`sortChangeAction`、表格内联编辑等部分更新会因 `data` 模板不含对应字段而丢失数据，触发 `没有可保存的字段` 错误。

`before` / `after` hook：

- `before`：规范化、校验、派生字段。返回值替换 `data` 模板输入。普通 CRUD 不写。
- `after`：关系同步、计数、缓存失效。返回值不影响保存结果。普通 CRUD 不写。

`validate.model` 只用于真实唯一业务标识，例如 `key`、`code`、`account`、手机号、OpenID、关系绑定自然键。展示名字段不要写 `validate.model`；展示名只做必填、长度、格式等表单校验。

## 内联编辑与列表维护字段

`status`、`sort` 和类似列表维护字段通过部分更新（`_partial: true`）保存。前端自动构造 payload，只含 `_partial: true` + 主键 + 变更字段。

部分更新的来源有三类：

1. **`show-table` 内联编辑**：列声明 `editor: "form-number"` / `editor: "form-switch"` 等，配合 `meta.savePath` 指向 update 页 route。
2. **`show-table` 列上的 `show-select` / `form-switch`**：行内状态切换，配合 `meta.savePath`。
3. **`show-category-list` 的 `statusChangeAction` / `sortChangeAction`**：左分类列表的状态切换和拖拽排序。

部分更新规则：

- `meta.savePath` 必须指向一个真实的 `update.json` route，且该 update 页的 `action.submit` 必须能接受 `_partial: true` 的部分字段。
- update 页的 `action.submit.data` 模板必须包含所有可能被部分更新触及的字段（见上一节）。
- update 页的 `before` hook 必须识别 `_partial`，跳过完整校验，只规范化实际存在的字段。不要在 partial 模式下清空 payload。
- 部分更新不需要 `after` hook 执行重业务逻辑；如果需要，必须确保只针对真实变更字段触发。

不要为 `status`/`sort` 切换新增专用 Service/API/Provider。复用 update 页的 `before` hook 即可。

## 弹窗和确认框

`feedback-modal` 关键字段（`title`/`description` 必须中文）：

- `stateKey`：对应 `state.dialog.<key>`，控制开关。
- `pageRoute`：必须指向真实存在的 `update.json` route，前面带 `/`。
- `pageRouteQuery`：编辑弹窗用，把行 ID 传给 update 页，例如 `"id": "data.actionTarget.editIdentityId"`。
- `pageDataPatches`：新增弹窗用，把父页状态注入 form，例如 `"form.identity_id": "data.search.identity_id"`。
- `footer.confirm` + `confirmText`：保存按钮。
- `size`：`sm` / `md` / `lg` / `xl`，按表单字段数选择。

一个 update 页可以被多个 modal 共用（新增 + 编辑），通过 `pageRouteQuery` 区分。

`feedback-confirm` 关键字段（`name`/`info` 必须中文）：

- `stateKey`：对应 `state.confirm.<key>`。
- `action.confirm.type: "delete"`。
- `action.confirm.path`：指向 update 页 route（删除走 update 页的 delete action）。
- `action.confirm.params`：`"actionTarget.<key>"`（行数据）或固定对象。
- `before` hook：删除前校验（例如"身份下仍有等级时阻止删除"），普通删除不写。

不要硬编码 `/front/route/action`；使用当前站点 runtime API 前缀。普通页面 action 不新增后端 API。

## Action 规则

优先使用已有 `package/front` action：列表加载/搜索/分页、编辑/新增/删除、状态切换、排序编辑、option/relation 加载、已支持的导入/导出。

不要硬编码 `/front/route/action`；使用当前站点 runtime API 前缀。普通页面 action 不新增后端 API。

页面保存时需要规范化、校验、关系同步或跨表写入时，按 `service-api.md` 增加 Provider 或 Service。

## 权限和 Option 错误

遇到 `暂无权限`，先查：

- 当前站点 access mode 和登录状态
- 页面 `page.parent` 以及 menu/auth 注册
- 从路径推导的 action key
- 嵌入弹窗的父子关系和 action 上下文
- public path 只给真正公开的页面

遇到 `option 无法推导模型`，先查：

- `form.xxx_id` 这类字段路径是否映射到当前表单 model
- model 是否为该字段定义了 Options 或 Relations
- 嵌入行上下文是否有自己的 model
- action/dialog 是否有正确 page/action 上下文

遇到 `没有可保存的字段`，先查：

- update 页是否写了不完整的 `action.submit.data` 模板
- `data` 模板是否漏掉了被 partial save 触及的字段（`status`、`sort` 等）
- `before` hook 是否在 `_partial` 模式下错误地清空了 payload

不要通过授予通配权限或编写宽泛的直连表 action 来修这些错误。

## Front 插件边界

只有 page JSON 表达不了 UI 时，才写 `front/src/plugin.ts`。插件源码属于对应 package/module：

```txt
package/bot/front/src/plugin.ts
module/work/front/src/plugin.ts
```

除非维护通用 front runtime 本身，否则不要为了 package/module 功能修改主 `front/src`。
