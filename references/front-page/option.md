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

## 常见错误

- option 无法推导：先查 model Relations/Options 和当前节点 value 字段。
- 弹窗 option 错：先查是否保留父级 path/input。
- 分类 option 错：先查 `show-category-list` 的 key/value/option 和目标 model。
- 不要为了修 option 硬编码旧字段或固定 URL。
