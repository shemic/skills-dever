# Front Page Option

Option 优先来自当前 Model 元信息。只有 Relations/Options 无法表达跨资源或动态选项时，才在 Page 声明显式来源。

## 来源优先级

1. 不写 `option`：枚举从 Model Options、关联从 Model Relations 推导。
2. `"option": "option.<field>"`：读取 `data.option.<field>` 本地数组。
3. `"option": {"model": "pkg.NewXxxModel"}`：跨资源或无法自动推导。
4. `"option": {"service": "pkg.OptionService.LoadXxx"}`：真实远程选项流程。
5. 少量页面专用固定选项才写静态数组。

不要在多个 Page JSON 重复一份 Model Options。

## Option 对象

当前通用字段：

```txt
key model service filters searchFields extraFields valueField labelField
parentField leafField order pageSize page tree rootValue
```

示例：

```json
"option": {
  "model": "crm.NewStaffModel",
  "filters": {"status": 1},
  "searchFields": ["name", "mobile"],
  "extraFields": ["department_id"],
  "order": "sort asc,id asc"
}
```

`model` 和 `service` 互斥，同时声明时服务端直接报错。远程 option 统一返回数组，每项至少符合：

```json
{"id": 1, "value": "张三"}
```

需要额外展示或回填的字段通过 `extraFields` 返回，不改变 `id/value` 的基础契约。

## Relations 和 Options

节点 value 能映射到当前 Model 字段时，runtime 会优先解析：

- Options：固定枚举展示和选择。
- Relations：关联 Model、value/label 字段、顺序和可用 option key。

推导失败时先检查当前页面 Model、节点 `value` 和 Relation field/name/option key，不要直接升级到 Provider。

## 远程 Option

对象 `option.model` 或 `option.service` 会自动使用当前站点的 `route/option`。Page 不写内部 URL。

service 字符串必须指向 `service/**` 中已注册的 Provider 名称。Provider 负责动态参数适配和必要业务边界；普通 Model 查询优先使用 `option.model`。

宿主仍支持以 URL 字符串作为 option source，但只用于真实自定义/外部 endpoint。内部 Model/Provider option 不手写 `/front/route/option`，也不把 SQL、任意 model/service 名从客户端参数传给后端。

## 动态参数

节点 `meta.optionParams` 只传动态上下文。当前内部 route option 会保留：

```txt
path key keyword selected parentId level
_inherit _parentPath _parent_*
```

静态查询配置放在 option/meta：

```txt
filters searchFields extraFields valueField labelField
parentField leafField order pageSize tree rootValue
```

不要把静态 Model 查询配置塞进 `optionParams`。Page 中的 filters 可以使用当前模板上下文，但最终来源仍由服务端 Page JSON 决定。

## 复杂节点专用来源

下列字段仍是当前实现，不是旧协议；它们只属于指定节点。

### `form-cascader`

```txt
meta.model / meta.service
meta.childModel / meta.childService
```

父级和子级来源可以分别声明，runtime 自动使用当前站点 route option。当前源码还支持级联专用的 `parentField/childParentField`、extra/leaf/order 等 meta；只按该节点实现配置。

### `type-editor`

```txt
meta.loadOption   对象来源，存在时自动选用 route option
meta.loadApi      可选的真实自定义 endpoint 覆盖
meta.loadKey      稳定 option key
```

普通场景优先 `loadOption` 对象，不硬编码内部 `loadApi`。`loadApi` 不能推广为所有表单节点的加载协议。

### `form-combo-mapping`

```txt
meta.optionSourceOption / meta.optionSource / meta.optionSourceKey
meta.paramSourceOption  / meta.paramSource  / meta.paramSourceKey
```

`*Option` 是内部 route option 的对象来源，`*Source` 是真实 URL 覆盖，`*Key` 用于服务端从当前 Page 找到对应配置。只有该节点的组合参数流程使用这些字段。

### `form-array.fillFromOption`

`meta.fillFromOption` 是对象，当前实现读取：

```txt
option 或 source
optionKey
targetField
valueField
defaultRow
params
```

`option` 是 route option 对象来源，`source` 可以是已有 store 路径或真实 URL。缺少来源或 `targetField` 时该能力不生效。不要把 `fillFromOption` 当作普通 form 的 option 配置。

这些复杂节点没有可比 Page 例子时，直接读 `front/src/page/nodes/form` 和 `front/src/page/option.ts`；不要凭字段名猜结构。

## `form-select` 空值

`form-select` 默认把 `0`、`"0"`、`""`、`null` 和 `undefined` 视为空值。常规外键、人员和分类选择不额外配置。

只有 `0` 是合法 option 时才覆盖：

```json
"meta": {
  "emptyValues": [""]
}
```

placeholder 优先使用节点显式值；没有时可按节点名称生成。不要为了枚举字段机械写 `emptyValues`。

## 分类与人员

- 固定分类/类型：Model Options。
- 可维护分类表：分类 Model + Relations，表单使用 `form-select/form-cascader`。
- 左分类右列表：`show-category-list` 使用自己的 option 和 search 绑定。
- 作者、创建人、更新人、操作人默认来自上下文，只展示不选择。
- 负责人、指派人、部门是业务字段，使用清晰名称和 Relations。

分类管理的 status/sort 通常在列表内 partial save，不要让编辑弹窗的默认值覆盖已有内联值。

## 自检

- 是否可以删除 Page option，交给 Options/Relations。
- model/service 是否互斥，Provider 是否已经注册。
- 远程结果是否保持 `id/value`。
- optionParams 是否只传动态上下文。
- 复杂来源字段是否只用于对应节点，并已核对当前节点源码。
- 是否错误手写内部 route option URL。
