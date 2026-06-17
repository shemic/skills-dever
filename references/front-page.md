# Front Page JSON 规则

普通后台和简单站点页面优先使用 `package/front` page JSON。只有页面确实需要画布、图编辑器、工作台、领域实时交互这类自定义交互界面时，才写 React 插件节点。

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

`front/page/{page}` 里的 `{page}` 来自 `config/front.json.sites.*.page`，只用于物理目录隔离，不会自动进入 route。站点系统页使用 `sites.*.api`：

- `api: "front"` 读取 `front/login` 和 `front/main`。
- `api: "work"` 读取 `work/login` 和 `work/main`。

其他站点复用 admin 壳时，要在该站点自己的目录创建 `main.json` 和 `login.json`，不要硬编码 `/front/auth/login`。

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

## Model 推导

标准页面后缀会从路径自动推导 model：

- `list`
- `update`
- `create`
- `view`
- `detail`
- `info`

标准页面不要写：

- `data.table.list: "<<...NewXxxModel>>"`
- `data.form._model`
- `data.form._use`
- `action.submit.use`
- `<<NewXxxModel>>` in page JSON

如果推导失败，修 model 文件名、`NewXxxModel`、所属路径或 page path。不要为了省事硬编码 model。

只有 `set`、`config`、固定单记录页、跨资源嵌入页、真实自定义流程这类非标准页面，才显式声明 model。

## Model 元信息是来源

可复用元信息放在 model：

- `dorm:"comment:..."` 用于标签。
- `Options` 用于枚举。
- `Relations` 用于关联选择。
- 索引和 `Order` 用于列表默认排序。

不要把字段标签和选项复制到每个页面。只有页面展示语义确实不同于 model 时，page JSON 才覆盖展示文案。

## Layout 和 Nodes

`layout` 声明结构，`nodes` 把 UI 节点绑定到 layout ID。不要发明节点类型，先查 `package/front`。

常见节点：

```txt
show-title, show-base, show-date, show-tag, show-table, show-button, show-page
form-input, form-textarea, form-number, form-switch, form-radio, form-checkbox, form-select, form-date
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

## 列表页

标准列表页：

- 使用 `show-table` 加远程数据。
- 搜索状态放在 `data.search` 或 `data.table.searchFields`。
- 不定义 `data.table.list`；运行时会加载。
- `status/sort` 这类列表维护字段保留在表格内联维护。
- 不要只为了切换状态或排序新增 update 表单。

左分类右列表页面必须把分类 model/data 和主表列表分开绑定。分类选中 ID 可以进入 search/query 状态，但分类列表不能复用其他页面缓存的分类状态。

远程左分类右列表页面，把 `show-category-list.value` 绑定到对应搜索字段：

```json
{
  "type": "show-category-list",
  "value": "parent.data.search.cate_id",
  "meta": {
    "remote": true,
    "defaultFirst": true
  }
}
```

分类页嵌入父列表页时使用 `parent.data.search.<field>`；分类列表和表格在同页时使用 `search.<field>` 或 `data.search.<field>`。通用 front runtime 会重置 `data.table.page`，并通过 page JSON 重新加载对应数据容器；不能为了刷新列表而 navigate 到 `?cate_id=...`。普通分类/列表刷新不要新增单页 service。只有 URL 必须同步当前分类时才设置 `meta.syncQuery: true`，并且仍以本地数据容器刷新作为数据来源。

## 编辑/新增页

标准编辑/新增页：

- 使用推导 model 和默认 submit。
- 不硬编码 `submit.use`。
- `status` 或 `sort` 如果是列表维护字段，不放进编辑表单。
- 只放用户真正需要编辑的字段。
- 如果页面用作 `pageRoute`、modal/drawer 内容、嵌入子页、`savePath` 或任意 action 目标，必须给它明确表达用途的 `page.name` 和有效 `page.parent`。
- 如果 create/update 需要独立权限，显式声明带中文名和 query 规则的 `page.auth`。不要让权限同步退化成 `bot/agent/xxx/update` 这类 route path 名称。

嵌套表、子记录、嵌入弹窗必须声明自己的 page/action 上下文。不要为了让子弹窗能用而放宽权限。

## Action 规则

优先使用已有 `package/front` action：

- 列表加载/搜索/分页
- 编辑/新增/删除
- 状态切换
- 排序编辑
- option/relation 加载
- 已支持的导入/导出

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

- `form.service_id` 这类字段路径是否映射到当前表单 model
- model 是否存在 Options/Relations
- 嵌入行上下文是否有自己的 model
- action/dialog 是否有正确 page/action 上下文

不要通过授予通配权限或编写宽泛的直连表 action 来修这些错误。

## Front 插件边界

只有 page JSON 表达不了 UI 时，才写 `front/src/plugin.ts`。插件源码属于对应 package/module：

```txt
package/bot/front/src/plugin.ts
module/work/front/src/plugin.ts
```

除非维护通用 front runtime 本身，否则不要为了 package/module 功能修改主 `front/src`。
