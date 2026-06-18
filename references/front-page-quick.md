# Front Page 快速规则

普通后台 CRUD、列表、编辑、详情和简单站点页面先读本文件。只有本文件无法覆盖时，再读 `front-page.md`。

## 先判断能力层

- 普通增删改查：`Model + package/front + page JSON`。
- 标签、枚举、关联选项：优先写 model comments、Options、Relations。
- 保存前校验或规范化：Provider hook。
- 跨表事务、状态流转、外部调用：Service。
- 登录、回调、复杂前端交互：API + Service。
- 画布、图编辑器、CRM 工作台这类自定义界面：package/module front 插件。

不要为普通 CRUD 新增 Service、API 或空 Provider。

## Page JSON 必需结构

每个 page JSON 都必须保留六个顶层对象：

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

缺 `data`、`state` 或 `action` 容易引发 schema/runtime 空值错误。

## 能推导的不写

标准页面后缀会从 path 自动推导 model：`list`、`update`、`create`、`view`、`detail`、`info`。

标准页面不要写：

- `_model`、`_use`
- `<<NewXxxModel>>`
- `{{Service}}`
- `type: "service"`
- `submit.use`
- `option.use`
- `childUse`
- `modelName`
- `/front/route/option`
- `/front/route/action`

推导失败时，优先修 model 文件名、`NewXxxModel`、所属目录或 page path，不要靠禁止字段绕过。

## 当前来源协议

不能推导时，只使用这些字段：

- `data.<key>.model`
- `data.<key>.service`
- `action.<key>.model`
- `option.model`
- `option.service`
- `meta.model`
- `meta.service`
- `meta.childModel`
- `meta.childService`

`data.table.service` 和 `data.form.service` 在已有 model 时表示 model 查询后的 rows/record 补字段或规范化，不是替代数据源。

## Option 写法

优先级：

1. 不写 `option`：外键字段从 Relations 推导，枚举字段从 Options 推导。
2. `option: "option.<field>"`：使用 `data.option.<field>`。
3. `option: { "model": "pkg.NewXxxModel" }`：跨资源或无法自动推导时用。
4. `option: { "service": "pkg.Service.Method" }`：真实远程选项流程才用。
5. 少量固定展示选项才允许写数组。

远程 option 不写 `/front/route/option`。`form-cascader`、`type-editor`、`form-array fillFromOption`、`form-combo-mapping` 会从对象来源自动使用当前站点的 `route/option`。

`optionParams` 只传动态值，例如 `parentId`、`selected`、`keyword`、`level`、`_inherit`、`_parentPath` 或 `_parent_*`。`parentField`、`valueField`、`labelField`、`extraFields`、`pageSize`、`order`、`filters` 这类静态配置放到 `option` 或 `meta`，不要塞进 `optionParams`。

## Action 写法

普通保存只写：

```json
"submit": {
  "type": "save",
  "params": "form"
}
```

普通 CRUD 不写 `data`、`before`、`after`。只有重命名字段、派生字段、关系同步、真实校验时才写 hook。

写 `action.submit.data` 时，必须覆盖所有可能被 partial save 触及的字段，至少包含 `id`、编辑字段、`status`、`sort`。否则列表状态切换、排序或内联编辑会触发 `没有可保存的字段`。

update 页的 `before` hook 必须识别 `_partial`，只处理实际存在的字段，不做完整表单校验。

## 常用自查

- `list.json` 要有明确 `page.parent`，避免权限同步把页面挂到顶层。
- `update/create.json` 要有最小 `action.submit`。
- 列表 `status/sort` 维护优先走标准 inline action，不单独写 Service/API。
- 上传字段用 `form-upload`，不要让用户手填资源路径。
- 公开页面必须写在组件 `dever.json.front.public` 或 `front.sites.<site>.public`，不要靠不写 auth 绕权限。

## 何时升级到完整参考

- 左分类右列表、嵌入弹窗、确认框、内联编辑规则不确定：读 `front-page.md`。
- 服务端模板、SEO、公开内容站：读 `template-page.md`。
- package/module front 插件或 React node：读 `package-plugin.md`。
- 权限、公开 route、上传安全：读 `security.md`。
