# Front Page Action

普通保存和删除使用 `package/front` 标准 action。标准 runtime 已处理页面权限、表单校验、Model 字段过滤、关系持久化、操作日志和缓存失效，不为单表 CRUD 新增 Service/API。

## Action 执行入口

宿主当前 action type：

```txt
state data request page modal save delete export import increment array
```

节点 action 可以引用命名 action，也可以内联一个 action 对象；需要顺序执行时使用 action 名称/对象数组。不要发明新的 type。

- `state/data`：修改页面 store。
- `page/modal`：切换页面或弹窗状态。
- `save/delete`：调用当前站点标准 `route/action`。
- `request`：调用真实自定义 HTTP API。
- `export/import/increment/array`：使用已实现的专项流程。

普通 CRUD 不手写 `/front/route/action`，也不用 `request` 绕过标准保存删除。

## 最小保存

create/update 页使用命名 `submit`：

```json
"action": {
  "submit": {
    "type": "save",
    "params": "form"
  }
}
```

- `params: "form"` 读取 `data.form`。
- 当前 page path 推导保存 Model。
- 跨资源或非标准 path 才写 `path` 或 `model`。
- 普通保存不写 `data`、`before`、`after`。

## `params` 与 `data`

`params` 决定 action 原始 payload。它可以是 store 路径，也可以是使用当前 action 模板值的对象。

`action.submit.data` 是保存前的 payload 映射模板。只在需要字段重命名、聚合或严格过滤时使用；没有转换需求就直接提交 `form`。

执行顺序是：

```txt
params -> before hook 链 -> data 模板 -> Model sanitize/save -> Model Relations/hook -> after hook 链
```

因此 `before` 接收原始 payload，返回结果再进入 `data` 模板。不要假定 `before` 接收的是已经映射后的对象。

## Partial save

列表状态、排序和内联编辑使用 `_partial: true`：

```json
{
  "type": "save",
  "path": "source/origin/update",
  "params": {
    "_partial": true,
    "id": "$row.id",
    "status": "$value"
  }
}
```

未配置 `action.submit.data` 时，标准 runtime 直接处理 partial payload。

配置了 `data` 模板时，runtime 会在模板解析后只保留原 partial payload 中实际存在的 key。因此模板必须覆盖所有可能被列表维护触达的字段，例如：

```txt
id
真实表单字段
status
sort
其它内联编辑字段
```

漏掉字段会导致保存 payload 被过滤为空，最终报“没有可保存的字段”。`before` 也必须识别 `_partial`，只校验或处理本次存在字段。

## 保存字段白名单

form 节点和 submit payload 只包含当前页面允许用户修改的业务字段。默认不要提交：

```txt
created_at updated_at deleted_at
created_by updated_by author_id editor_id operator_id
服务端生成的 code/key/slug/sn/no
```

真实负责人、指派人等选择字段使用明确业务名，例如 `owner_staff_id`、`assignee_id`。字段边界见 [field.md](field.md)。

## Provider hook

hook 只能写 service 对象或 service 对象数组：

```json
"before": {
  "service": "source.SourceHook.BeforeSaveOrigin"
}
```

```json
"after": [
  {"service": "crm.setting.CrmHook.AfterSaveDepartment"}
]
```

`source.SourceHook.BeforeSaveOrigin` 对应 `service/**` 中注册后的 Provider 名称，例如 Go 接收者方法 `ProviderBeforeSaveOrigin`。Page runtime 不能调用未注册的普通 Service 方法。

- `before` 按顺序执行；Provider 返回非 `nil` 时替换当前 payload。save 最终必须得到对象。
- `after` 在保存/删除成功后按顺序执行，返回值不替换标准 action 结果。
- save 的 `after` 输入包含 `payload/data/result/id`。
- hook 只做 Page 边界的解析、校验、规范化和结果适配；复杂业务调用同域普通 Service。

Model Relations 已由标准 action 保存和删除，不重复写关系同步 hook。Model 生命周期 hook 也已在 Page `after` 之前执行；新业务流程不要继续堆进 Model hook。

禁止旧 hook 外形：

```json
{"type": "service", "use": "..."}
```

## Delete

普通删除使用 `type: "delete"`，Model 和主键默认从 action path 与 `id` 推导：

```json
{
  "type": "delete",
  "path": "source/origin/update",
  "params": "actionTarget.deleteOrigin"
}
```

只有主键不是 `id` 时才写 `pk`。需要删除前业务校验时用 `before` Provider；需要跨表原子删除时让 Provider 调用聚焦 Service。不要新增一个只调用 Model Delete 的 API。

未显式声明的标准 `submit/delete`，服务端 resolver 能按标准 path 提供默认配置；Page 仍应保证宿主触发端存在明确、可验证的 action 配置，不依赖隐藏行为拼页面。

## Request

`request` 只用于真实自定义 HTTP 能力：

```json
{
  "type": "request",
  "api": "/front/admin/upload_storage/check",
  "method": "post",
  "params": {"id": "$row.id"}
}
```

`api` 必须是已经存在且符合站点隔离的薄 API。自定义写请求成功后客户端会清理页面/远程 option mutation cache；服务端仍必须自行完成权限、业务校验和事务。

## 权限与上下文

- save 按 action path/page 权限校验；delete 还会按 action key 校验。
- 不通过 public、通配权限或自定义 URL 绕过 action 错误。
- 嵌入页、弹窗和子表保留 `_inherit`、`_parentPath`、`_parent_*` 上下文。
- action `path` 指向真实页面 route，不指向物理 JSON 文件。

## 自检

- 普通 CRUD 是否仍走 `save/delete`。
- `params`、`data`、before 输入的先后顺序是否理解正确。
- partial save 可触达字段是否都能通过 data 模板。
- hook 是否指向注册 Provider，并且没有承载长业务流程。
- request 是否确实需要自定义 HTTP，而不是重复标准 action。
