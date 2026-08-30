# Front Page 任务式指南

本指南用于从一个业务资源落地当前 Page JSON。它只组合已验证的 runtime 能力，不列举所有节点字段；节点细节以宿主 schema 和对应节点源码为准。

## 1. 先确认任务边界

先把需求拆成资源、页面和业务动作：

- 资源字段、索引、枚举、关联：Model。
- list/create/update/detail、搜索、分页、弹窗：Page JSON。
- 保存前后校验、远程 option、读取后补字段：Provider 边界方法。
- 跨表事务、状态流转、外部调用：普通 Service。
- Page runtime 不支持的强交互：front plugin。

如果只是单表增删改查，目标应是 `Model + Page JSON`。不要先建 Service/API 再让页面调用。

## 2. 定位 site、页面目录和 route

先读组件 `dever.json.front.sites`：

- `page` 决定物理目录 `front/page/<page>/...`。
- 页面 route 默认由提供页面的组件名和页面相对路径决定，`<page>` 目录名不会自动进入 route。
- `api` 是站点 API 前缀，不决定普通业务页面 route。
- 站点显式配置 `route` 时，它只覆盖外部 Page route 前缀；runtime 会映射回组件内部前缀。普通后台不要无故增加别名。

例如：

```txt
package/source/front/page/admin/origin/list.json
-> source/origin/list
```

列表页和编辑页应属于同一资源路径：

```txt
source/origin/list
source/origin/update
```

## 3. 先完成 Model 元信息

Page 之前先检查 Model：

- 字段 `comment` 能否直接提供 label/列名。
- 固定枚举是否已经写在 `Options`。
- 外键或关联选择是否已经写在 `Relations`。
- 默认排序是否已经写在 `Order`。
- 构造函数是否满足当前 `NewXxxModel` 注册规则。

不要在多个页面重复一份枚举和关联配置。页面只覆盖这个页面确实不同的展示语义。

## 4. 建立稳定 Page 骨架

源文件保留六个顶层对象：

```json
{
  "page": {
    "name": "来源管理",
    "parent": "source-config"
  },
  "layout": {
    "type": "container"
  },
  "nodes": {},
  "data": {},
  "state": {},
  "action": {}
}
```

`layout` 的 ID 只负责布局结构，`nodes.<layout-id>` 承载该位置的节点。节点 `type` 必须已在宿主 front 或当前组件插件中注册。

## 5. 实现标准列表页

标准列表页使用 `.../list` 和 `data.table`。最小数据配置可以是：

```json
"data": {
  "search": {
    "keyword": "",
    "status": ""
  },
  "table": {
    "searchFields": ["name"],
    "filterFields": ["status"],
    "order": "sort asc,id asc"
  }
}
```

`data.table` 不需要写 `model`、`list`、`total`、`page` 或 `pageSize`。runtime 对 `.../list` 自动推导 Model、查询列表并回填分页数据。只有以下情况才显式配置：

- 非标准路径或跨资源列表：`data.table.model`。
- Model 查询完成后需要补字段：`data.table.service`。
- 列表不是 Model 数据，而是真实聚合流程：使用非标准 data key 的 `service` 容器，并由对应节点读取其结果；不要伪装成普通 CRUD。

表格通常读取 `table.list`：

```json
{
  "type": "show-table",
  "value": "table.list",
  "meta": {
    "remote": true,
    "externalPagination": true,
    "pagePath": "data.table.page",
    "pageSizePath": "data.table.pageSize",
    "totalPath": "data.table.total",
    "rowKey": "id",
    "columns": [
      {"value": "name", "type": "show-base"},
      {"value": "created_at", "type": "show-date"}
    ]
  }
}
```

列、搜索控件和 action 只写需求实际需要的内容。不要把历史页面的 className、按钮和字段整段复制到新资源。

## 6. 实现 create/update 页面

标准创建和编辑共用 `.../update` 或分别使用 `.../create`、`.../update`，数据容器固定为 `data.form`：

```json
"data": {
  "form": {}
},
"action": {
  "submit": {
    "type": "save",
    "params": "form"
  }
}
```

表单节点把真实可编辑字段绑定到 `form.<field>`：

```json
{
  "type": "form-input",
  "value": "form.name",
  "mode": "form",
  "validate": [
    {"type": "required", "message": "名称不能为空。"}
  ]
}
```

runtime 会从节点收集可编辑字段，按 query 中的 `id` 加载编辑记录，并按 Model 字段白名单保存。`data.form` 只放确有必要的新增默认值，不机械复制整张表。

系统时间、创建人、更新人和服务端生成的编码默认不做表单字段。完整边界读 [field.md](field.md)。

## 7. 实现详情页

`.../view|detail|info` 同样通过 `data.form` 推导 Model，展示节点读取 `form.<field>`：

```json
"nodes": {
  "detail-shell": [
    {"type": "show-base", "value": "form.name"},
    {"type": "show-date", "value": "form.created_at"}
  ]
},
"data": {"form": {}}
```

详情页没有写操作时保持 `action: {}`。不要为了读一条记录增加 `GetInfo` API 或 Service wrapper。

## 8. 使用弹窗、抽屉和嵌入页

列表打开编辑弹窗时，页面仍然是独立 Page：

- 子页写明确的 `page.name` 和 `page.parent`。
- 父页通过 `feedback-modal`/`feedback-drawer` 的 `pageRoute` 引用子页。
- 编辑时通过 `pageRouteQuery` 传 `id`；新增时不传 `id`。
- 子页保存继续使用自己的 `action.submit`。
- 保留父页面继承上下文，不通过放宽权限解决嵌入页问题。

状态切换、排序和表格内联编辑使用 `type: "save"` 的 partial payload：

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

如果 update 页配置了 `action.submit.data`，它必须包含所有可能被 partial save 触达的字段，否则过滤后会没有可保存字段。详见 [action.md](action.md)。

## 9. 只在有业务规则时增加 hook

标准保存删除已经处理权限、验证、字段过滤、关系持久化、日志和缓存失效。只有真实规则才增加 `before/after`：

```json
"before": {
  "service": "source.SourceHook.BeforeSaveOrigin"
}
```

该字符串不是任意 Go 方法名。它必须对应 `service/**` 中已经由 Dever 注册的 `ProviderBeforeSaveOrigin` 接收者方法；复杂业务由 Provider 调用普通 Service 方法。

- `before`：边界校验、规范化、派生字段；save 时最终必须得到对象。
- `after`：标准保存成功后的必要副作用。
- Model Relations 已由标准 action 持久化，不为已有能力重复写同步 hook。
- 跨表原子写、状态机和外部调用属于 Service，不塞进 Provider 适配方法。

## 10. 选择 option 来源

按以下顺序选择：

1. 不写 `option`，由当前 Model 的 Options/Relations 推导。
2. `"option": "option.status"`，读取当前页面 `data.option.status`。
3. `"option": {"model": "crm.NewStaffModel"}`，显式跨资源 Model。
4. `"option": {"service": "crm.setting.OptionService.LoadStaffOptions"}`，真实远程 option。
5. 少量页面专用固定值才写静态数组。

`option.model` 和 `option.service` 不能同时存在。远程结果使用 `{id, value}` 项，扩展展示字段通过 `extraFields` 等当前配置声明。

`form-cascader`、`type-editor`、`form-array` 和 `form-combo-mapping` 有各自的复杂来源字段。只有使用对应节点且读过节点源码后才配置 `meta.model/childModel/loadOption/optionSourceOption/...`，不要把它们套到普通 `form-select`。详见 [option.md](option.md)。

## 11. 配置权限和菜单

- 可点击列表页写中文 `page.name` 和正确的 `page.parent`。
- 弹窗、抽屉和嵌入页的 `page.parent` 指向所属页面或分组。
- create/update 共用一页但要分开授权时，使用当前 `page.auth[].query` 规则区分空 `id` 和必填 `id`。
- 公开页面必须写入组件 `dever.json.front.public` 或 `front.sites.<site>.public`。
- 站点契约属于组件 `dever.json`；项目 `config/front.json/jsonc` 只覆盖展示配置。

完整规则读 [site.md](site.md)。

## 12. 判断是否升级能力

遇到需求时按下面判断，不跳层：

| 需求 | 最低能力 |
| --- | --- |
| 改 label、枚举、关联 | Model 元信息 |
| 普通表格、表单、详情、搜索、弹窗 | Page JSON |
| 读取后补字段、远程 option、保存边界适配 | Provider |
| 跨表事务、状态流转、外部系统 | Service |
| 真实 HTTP/流式/文件/回调 | API + Service |
| 画布、图编辑器、复杂实时工作台、自定义节点 | front plugin |

Page 节点不够用时，先确认宿主和当前组件是否已有可复用节点。只有 runtime 确实无法表达交互，才按 [front-plugin.md](../front-plugin.md) 新增插件节点。

## 13. 交付前检查

- Page 源文件保留六个顶层对象。
- 标准路径只使用 `data.table`/`data.form` 推导，没有重复 model。
- 正向配置没有旧协议字段或手写 runtime URL。
- 普通 CRUD 没有新增 Service/API/空 Provider。
- form 节点、默认值和 submit payload 没有暴露系统字段。
- Options/Relations 没有在多个页面重复。
- hook 指向已注册 Provider，并且 Provider 只做边界适配。
- 节点 type 和 meta 字段能在当前宿主或组件插件源码中找到。
- `page.name`、`page.parent`、public 和权限 query 与实际入口一致。

可运行定向静态检查：

```bash
bash skills/skills-dever/scripts/audit.sh <changed-page-or-component>
```

不要为页面文档验证运行宿主 front 全量构建；只有实际修改 runtime/plugin 且用户允许时才执行对应构建。
