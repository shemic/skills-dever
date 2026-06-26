# Front Page Option

option 必须由服务端 page JSON、model 元信息和当前站点上下文决定。客户端不能直接传 model/service/SQL 来决定来源。

## 优先级

1. 不写 `option`：外键字段从 Relations 推导，枚举字段从 Options 推导。
2. `option: "option.<field>"`：使用 `data.option.<field>` 本地选项。
3. `option: { "model": "pkg.NewXxxModel" }`：跨资源或无法自动推导。
4. `option: { "service": "pkg.Service.Method" }`：真实远程选项流程。
5. 少量固定展示选项才写数组。

不要在 page JSON 里重复写 model Options 已能表达的枚举。

## model 和 service

`option.model` 和 `option.service` 互斥。运行时同时声明会报错。

远程 option 仍由当前站点的 `route/option` 执行，不要手写 URL。

## meta 来源

下列节点可从 `meta.model` / `meta.service` / `meta.childModel` / `meta.childService` 自动使用当前站点 option runtime：

- `form-cascader`
- `type-editor`
- `form-array` 的 `fillFromOption`
- `form-combo-mapping`
- 其它支持远程 option 的 front 节点

不要写 `meta.api: "/front/route/option"`。

## optionParams

`optionParams` 只传动态值：

```txt
parentId
selected
keyword
level
_inherit
_parentPath
_parent_*
```

静态配置放在 `option` 或 `meta`：

```txt
parentField
valueField
labelField
leafField
extraFields
searchFields
filters
order
pageSize
```

## form-select 空值

`form-select` 默认把 `0`、`"0"`、`""` 当空值，空值展示 placeholder。`null` 和 `undefined` 也始终按空值处理。

常规外键、人员、分类选择不用额外配置：

```json
{
  "type": "form-select",
  "name": "作者",
  "placeholder": "请选择作者"
}
```

没有 `placeholder` 时，前端按 `name` 生成 `请选择作者`；没有 `name` 时兜底 `请选择`。

如果 `0` 或 `"0"` 是合法选项，必须覆盖 `meta.emptyValues`：

```json
{
  "type": "form-select",
  "name": "状态",
  "meta": {
    "emptyValues": [""]
  }
}
```

如果后端用其它值表示未选择，可以显式配置：

```json
{
  "type": "form-select",
  "placeholder": "请选择作者",
  "meta": {
    "emptyValues": [0, "0", "", -1, "-1"]
  }
}
```

不要为了状态/枚举字段机械配置 `emptyValues`。只有后端占位空值和默认规则不一致时才配置。

## 常见错误

- option 无法推导：先查 model Relations/Options 和当前节点 value 字段。
- 弹窗 option 错：先查是否保留父级 path/input。
- 分类 option 错：先查 `show-category-list` 的 key/value/option 和目标 model。
- 不要为了修 option 硬编码旧字段或固定 URL。

## 分类和人员字段

分类、类型、分组不要做自由输入：

- 固定枚举用 Model `Options`。
- 外键分类用分类 model + `Relations`，表单用 `form-select` 或 `form-cascader`。
- 左侧分类筛选和分类管理用 `show-category-list`。
- 主资源保存分类 ID，不在主资源表单手填分类名。

左分类右列表的分类管理默认规则：

- 除非开发者明确要求删除，左侧分类项默认只提供标题、拖拽排序、状态切换、编辑按钮，不提供删除按钮。
- 排序和状态只在左侧分类列表内联展示和修改，不放进新增/编辑弹窗；弹窗保存名称等基础字段时不能提交默认 `sort/status` 覆盖内联值。
- 分类 model 默认带 `status`、`sort` 和对应索引/Options；业务读取分类 option 时只返回启用项，分类管理页必须能读取全量分类，避免停用后无法重新启用。
- 固定枚举型分类可以不套这套 CRUD 分类管理，但要明确它不是可维护分类表。

作者、编辑、创建人、更新人、操作人默认不是 option 字段。它们来自登录上下文或审计记录，只在列表/详情展示。

真实业务选择字段可以用 option，例如负责人、指派人、所属部门：

```txt
owner_staff_id
assignee_id
department_id
```

这些字段要用清晰业务名，并优先通过 Relations 推导选项。

控件选择按 `front-page/field.md`：2-4 个固定单选枚举优先 `form-radio`，不要为了 radio 在 page JSON 里复制 model Options。
