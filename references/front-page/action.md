# Front Page Action

普通保存交给 front 标准 action。不要为 CRUD 写 Service/API。

## 最小 submit

普通 create/update 页面只写：

```json
"submit": {
  "type": "save",
  "params": "form"
}
```

不写 `data`、`before`、`after`，除非确实需要字段映射、派生字段、校验、关系同步或真实业务流程。

## 保存模型

`action.submit.model` 只在跨资源保存或非标准路径无法推导时使用。

标准页优先依赖 route path 推导，不写 model。

## data 模板和 partial save

`action.submit.data` 会按模板生成保存 payload。列表内联编辑、状态切换、排序通常会带 `_partial`，运行时会只保留本次 payload 中存在的字段。

因此写 `action.submit.data` 时，必须覆盖所有 partial save 可能触达字段，至少包含：

```txt
id
当前编辑字段
status
sort
```

否则过滤后可能没有真实列，触发 `没有可保存的字段`。

## before/after hook

hook 只写 service 对象：

```json
"before": {
  "service": "source.SourceHook.BeforeSaveChannel"
}
```

禁止：

```json
{"type": "service", "use": "..."}
```

`before` 必须返回对象。update 页的 `before` 需要识别 `_partial`，partial save 时只处理实际存在字段，不做完整表单校验。

`after` 用于关系同步、计数、缓存失效、副作用。长业务流程放 Service，不放 page JSON。

## delete

delete action 默认从 page/action 推导 model 和主键。普通删除不要写 API。

需要删除前校验或删除后清理时，使用 `before/after.service`，或者把真实事务放到聚焦 Service。

## 权限

action 会按当前 site、page path、action key 和 payload 检查权限。不要通过放开 public 或通配权限修 action 错误。

嵌入页、弹窗、子表必须保留父页面上下文：`_inherit`、`_parentPath`、`_parent_*`。
