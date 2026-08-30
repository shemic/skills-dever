# Front Page 协议

本文件定义当前 Page JSON 的通用结构、推导和来源位置。节点专用 `meta` 不属于通用协议，使用前必须核对对应节点源码。

## 顶层结构

源文件保留六个顶层对象：

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

- `page`：名称、route 元信息、父级、权限和初始化动作。
- `layout`：页面布局树；type 必须属于当前宿主 schema。
- `nodes`：按 layout ID 分组的节点数组。
- `data`：服务端解析的数据容器和客户端页面数据。
- `state`：纯交互状态。
- `action`：命名 action 配置。

客户端 `PageSchema` 要求 `page/layout`，并为其余四项提供空对象默认值；源文件仍显式保留六项，避免服务端 envelope 输出 `null`，同时保持页面边界可审查。

## 页面路径

`front/page/<page>` 中的 `<page>` 来自站点 `page` 配置，只做物理目录隔离。默认 route 由提供页面的组件和相对路径决定：

```txt
package/front/front/page/admin/account/list.json -> front/account/list
package/bot/front/page/admin/agent/run/view.json -> bot/agent/run/view
package/crm/front/page/work/main.json            -> crm/main
```

站点 key 和 `site.api` 不会自动加进普通业务页面 route。`front.sites.<site>.route` 可以显式覆盖站点对外 Page route 前缀，runtime 会把它映射回页面所有者的内部前缀；它不是 API 前缀。站点细则见 [site.md](site.md)。

## Model 推导

推导不是对任意 data key 生效，而是固定组合：

| Page path | 数据容器 | 行为 |
| --- | --- | --- |
| `.../list` | `data.table` | 推导 Model 并查询列表 |
| `.../create` | `data.form` | 推导 Model 并合并新增默认值 |
| `.../update` | `data.form` | 推导 Model，按 query `id` 读取记录 |
| `.../view|detail|info` | `data.form` | 推导 Model，按 query `id` 读取记录 |

保存/删除 action 从 `action.path` 或当前 page path 推导 Model。路径末尾的 `list/update/detail/info/create/view` 会在推导资源名时移除；多层路径会尝试当前组件资源名和已注册的嵌套 Model 名称。

推导失败先检查：

- Model 是否位于 active component 的 `model/**`。
- 构造函数是否为导出的无接收者、零参数 `NewXxxModel`。
- 嵌套 `model/<domain>` 是否使用完整注册名。
- 返回值是否是 `*orm.Model[T]` 或嵌入该值的兼容 wrapper。
- page path 是否真的表达该资源。
- 生成的 `data/load/model.go` 是否已刷新；不要手改它。

## 当前来源位置

无法推导或属于非标准流程时，只在实际消费者位置声明来源：

```txt
data.<key>.model
data.<key>.service
action.<key>.model
option.model
option.service
meta.model
meta.service
meta.childModel
meta.childService
```

其中 `meta.*` 只对明确支持这些字段的节点生效，不能当作 page 全局字段。

## data service 语义

普通 map 型 `data.<key>` 声明 `service` 时，runtime 会把该 Provider 作为该容器的数据来源。

`data.table` 和 `data.form` 需要单独判断：

- 标准路径已经推导或显式声明 Model 时，先查 Model，再调用 `service` 处理 `rows` 或 `record`。
- 这种 service 用于补字段、展示规范化或读取边界适配，不应包一层普通 CRUD。
- 真正的聚合/跨资源结果使用语义明确的 data key，例如 `summary`、`material_table`，由 service 提供并让节点读取对应结果。

Page JSON 中的 service 字符串必须指向已经注册的 Provider 名称，不是任意普通 Service 方法。

## 能推导的不写

普通标准页不要重复写：

- `data.table.model` / `data.form.model`。
- runtime 回填的 `table.list/total/page/pageSize`。
- Model Options/Relations 已能提供的 option。
- 可以由 Model comment 推导的通用 label。
- 标准保存删除可以推导的 model 和内部 runtime URL。

显式配置只用于跨资源、非标准路径或覆盖明确默认行为。

## page 元信息和权限

- `page.name` 使用清晰中文名。缺失时权限同步只能回退到路径，权限树会出现难读 route。
- 可点击列表页写正确的 `page.parent`，避免被同步到顶层。
- 弹窗、抽屉和嵌入页的 `page.parent` 指向所属列表或分组。
- `page.icon` 只给真实菜单入口使用。
- create/update 共页但需分权时，通过 `page.auth[].query.id` 的 `empty/required` 区分。
- 公开页面必须在组件 `dever.json.front.public` 或站点 `public` 中显式声明。

后台菜单使用权限记录的 `path` 跳转；带 query 的 path 会以去掉 query 的 route 定位页面，并把 query 纳入权限条件。空 path 只适合作为分组。

## 当前 Action 和 Option 外形

宿主 action type 只使用 schema 已注册值：

```txt
state data request page modal save delete export import increment array
```

Option 对象当前通用字段为：

```txt
key model service filters searchFields extraFields valueField labelField
parentField leafField order pageSize page tree rootValue
```

Action 细则见 [action.md](action.md)，Option 细则见 [option.md](option.md)。不要根据类似命名猜字段。

## 禁止旧协议

以下写法不得进入 Page 正向配置：

```txt
_model
_use
modelName
modelPath
type: "service"
submit.use
option.use
childUse
service@...
transform
<<NewXxxModel>>
{{Service}}
/front/route/option
/front/route/action
```

发现旧写法时改成所属容器的当前 `model/service`，或者删除可推导配置；不增加兼容分支。

## 自检

- route、data key 和 Model 是否属于同一资源。
- `data.table`/`data.form` 是否只在标准组合中依赖推导。
- service 是否指向注册 Provider，且不是 CRUD wrapper。
- layout ID 是否都能在 nodes 中正确引用，node type 是否已注册。
- 正向配置是否只使用当前 schema 和节点实现中存在的字段。
- public、parent、auth query 是否与真实入口一致。
