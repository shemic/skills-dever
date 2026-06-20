# Front Page 字段边界

有 model 不等于 model 的所有字段都进入表单。Page JSON 的 form 节点会被 runtime 收集到 `data.form._fields`，实际形成用户可编辑字段边界。

## 基本原则

- 表单只放用户在当前页面真实录入或选择的字段。
- 列表、详情、日志可以展示审计和系统字段，但默认不让用户编辑。
- `data.form` 只放当前表单需要的默认值，不把整张表字段机械搬进去。
- `action.submit.data` 只映射允许从表单保存的字段。
- 来自登录态、站点、父页面、路由、服务端生成或 model hook 的字段，不做成管理员手填项。

## 字段分类

| 字段类型 | 例子 | 页面处理 |
| --- | --- | --- |
| 用户录入 | `name`、`title`、`summary`、`sort`、`status` | 可放 form 节点 |
| 系统主键/时间 | `id`、`created_at`、`updated_at`、`deleted_at` | `id` 可隐藏在 `data.form`，时间只展示 |
| 审计上下文 | `created_by`、`updated_by`、`author_id`、`editor_id`、`operator_id` | 默认由登录上下文/服务端写，只展示 |
| 派生标识 | `code`、`key`、`slug`、`sn`、`no` | 默认服务端生成或由其它字段派生 |
| 分类归属 | `cate_id`、`category_id`、`type`、`kind`、`group_id` | 用 Options/Relations/category，不用自由输入 |
| 业务指派 | `owner_staff_id`、`assignee_id`、`department_id` | 真实业务选择字段，可用 Relations/form-select |

## code/key/slug

默认不要给管理员录入 `code`、`key`、`slug`。优先：

- `code/sn/no`：Provider/Service 生成。
- `slug`：由标题派生，必要时 Provider 校验唯一。
- `key`：由系统能力、权限同步或配置种子维护。

允许录入的例外：

- 权限标识、计划任务参数名、字典配置 key、插件能力 key 等，标识本身就是业务配置。
- 例外页面必须有唯一校验或唯一索引，并在 placeholder/info 中说明格式或用途。
- 例外字段优先使用业务名，如 `param_key`、`permission_key`，不要泛化成每个资源都有 `key`。

## 作者和编辑

- `author`、`editor`、`creator`、`operator`、`created_by`、`updated_by` 默认不是表单字段。
- 创建人、更新人、操作人由登录上下文或服务端 hook 写入。
- 列表/详情需要展示时，使用 `show-base/show-select/show-tag` 或关联展示。
- 如果业务需要“负责人、指派人、所属员工”，使用明确字段名：`owner_staff_id`、`assignee_id`、`staff_id`，并通过 Relations 或 `option.model` 选择。

## 分类字段

- 固定枚举分类用 Model `Options`。
- 外键分类用分类 model + `Relations`，表单用 `form-select` 或 `form-cascader`。
- 左侧分类筛选或分类管理用 `show-category-list`。
- 主资源只保存分类 ID，不手填分类名。
- 分类名称、排序、状态属于分类资源自己的 update 页面。

## 控件选择

固定少量单选枚举优先用 `form-radio`，不要默认写 `form-select`。

- 2-4 个固定选项：优先 `form-radio`。
- 是否/开关状态：优先 `form-switch`；需要展示多个语义标签时用 `form-radio`。
- 少量固定多选：用 `form-checkbox`。
- 外键、人员、分类、远程搜索、选项较多或未来会增长：用 `form-select` 或 `form-cascader`。
- 选项来源仍优先 Model `Options` / `Relations`，不要为了 radio 在 page JSON 里复制 options。

## 保存边界

写 `action.submit.data` 时只包含允许保存字段：

```txt
id
用户录入字段
真实业务选择字段
partial save 可能触达的 status/sort
```

不要包含：

```txt
created_at
updated_at
created_by
updated_by
author_id
editor_id
operator_id
服务端生成的 code/key/slug/sn/no
```

这些字段如需写入，放到 Provider hook、Service 或 model hook，并保留权限和唯一性校验。

## 审查提示

看到 create/update 页时，同时检查：

- form 节点 `value`。
- `data.form` 默认值。
- `action.submit.data`。
- model 字段、Options、Relations。
- 是否把系统字段、审计字段、派生字段或分类名做成手填。
