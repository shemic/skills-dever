# Front Page 协议

本文件只写 page JSON 当前协议。新项目不做旧字段兼容。

## 路径和模型推导

页面路径来自组件页面目录：

```txt
package/front/front/page/admin/account/list.json -> front/account/list
package/bot/front/page/admin/agent/run/view.json -> bot/agent/run/view
package/crm/front/page/work/main.json            -> crm/main 或站点本地路径
```

标准后缀会被移除后推导 model：

```txt
list, update, create, view, detail, info
```

例如 `source/channel/update` 优先推导 `source.NewChannelModel`，多层 package 可推导 `bot.team.NewTeamModel` 这类命名。

推导失败时先检查：

- model 文件是否在 `model/` 目录。
- 是否只有一个零参数 `NewXxxModel`。
- 文件名是否匹配 model 名。
- 所属 module/package 和 page path 是否一致。
- 是否已刷新 `data/load/model.go`。

不要靠旧字段绕过推导。

## 当前来源字段

不能自动推导时，只使用这些字段：

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

`model` 和 `service` 放在具体来源位置，不要发明前缀或全局字段。

## data service 语义

`data.table.service` 和 `data.form.service` 有两种情况：

- 没有 model：service 是该 data 容器的数据来源。
- 已经能推导或声明 model：先查 model，再把 rows/record 交给 service 补字段或规范化。

因此同时存在 model 和 service 时，service 不会让 model 失效。

## 能推导的不写

普通页面不要写：

- `page.type`：标准后缀可推导。
- `page.title`：可由 `page.name` 或 model 推导。
- `data.table.page/pageSize/total`：运行时填充。
- `data.form.id/status/sort` 默认容器值。
- model Options/Relations 能提供的 option。

只有覆盖默认行为或非标准页面才显式写。

## 禁止字段

以下字段或写法禁止出现在 page JSON：

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

## page 元信息

- `page.name` 必填，使用中文。
- 标准可点击列表页必须写 `page.parent`，避免权限同步落到顶层。
- `page.icon` 只在 `type: 1` 且进入菜单时写。
- 弹窗/抽屉/嵌入页保持 `page.parent` 指向所属列表或分组。
- 公开页面不能靠不写 auth 绕权限，必须在组件 `dever.json` 里显式 public。
