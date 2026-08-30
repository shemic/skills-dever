# Front Page 字段边界

Model 字段集合不等于表单字段集合。Page runtime 会从 form 节点收集 `data.form._fields`，这些节点和 submit payload 共同定义用户可编辑边界。

## 基本原则

- 表单只放用户在当前页面真实录入或选择的字段。
- 列表、详情和日志可以展示系统/审计字段，但默认不可编辑。
- `data.form` 只放确实需要的新增默认值，不复制整张表。
- `action.submit.data` 只映射当前页面允许保存的字段。
- 登录态、站点、父页、route、Provider、Service 或 Model 生命周期提供的值不做管理员手填项。

## 字段分类

| 类型 | 例子 | Page 处理 |
| --- | --- | --- |
| 用户录入 | `name`、`title`、`summary` | form 节点 |
| 列表维护 | `status`、`sort` | 优先列表 partial save；新增默认值按需 |
| 主键/时间 | `id`、`created_at`、`updated_at`、`deleted_at` | id 用于上下文，时间只展示 |
| 审计上下文 | `created_by`、`updated_by`、`author_id`、`editor_id`、`operator_id` | 服务端写，只展示 |
| 派生标识 | `code`、`key`、`slug`、`sn`、`no` | 默认服务端生成或派生 |
| 分类归属 | `cate_id`、`category_id`、`type`、`kind`、`group_id` | Options/Relations/category |
| 业务指派 | `owner_staff_id`、`assignee_id`、`department_id` | 真实业务选择，可用 Relations |

## 标识字段

默认不让管理员录入通用 `code/key/slug/sn/no`：

- 编号/流水号由 Service 生成。
- slug 可由标题派生，并在服务端校验唯一性。
- 系统 key 由能力声明、权限同步、seed 或配置流程维护。

允许录入的例外是“标识本身就是业务配置”，例如参数 key、权限 key、字典 key。例外必须：

- 使用清晰业务名，例如 `param_key`、`permission_key`。
- 有唯一索引或真实唯一校验。
- 在 placeholder/info 中说明格式和用途。

## 审计人与负责人

不要混淆两类字段：

- 创建人、更新人、作者、操作人：来自登录上下文或审计记录，默认只展示。
- 负责人、指派人、所属员工/部门：用户真实选择的业务字段，可以编辑。

业务选择字段使用意图明确的命名和 Relations，不把 `created_by/updated_by` 借来当负责人字段。

## 分类字段

- 固定枚举用 Model Options。
- 外键分类用分类 Model + Relations。
- 表单用 `form-select` 或 `form-cascader`，不手填分类名。
- 左侧筛选/维护用 `show-category-list`。
- 分类资源自己的名称、排序、状态在分类页面维护，主资源只保存分类 ID。

## 控件选择

- 2-4 个固定单选枚举：`form-radio`。
- 布尔或开关状态：`form-switch`；多语义标签可用 `form-radio`。
- 少量固定多选：`form-checkbox`。
- 外键、人员、分类、远程搜索和大量选项：`form-select`/`form-cascader`。
- 图片、视频、音频、附件：`form-upload`，不让用户手填资源路径。
- 长文本：`form-textarea`；结构化富文本：`form-editor`。

选项仍优先来自 Model Options/Relations，不为换一个控件在 Page 重写选项数组。

## 富文本

`form-editor` 保存的是 Dever 富文本 JSON，不是 HTML：

- seed、`data.form` 默认值和 AI 预置内容必须直接给富文本 JSON 字符串。
- 纯文本需要先组装成 `doc > paragraph > text`，不依赖编辑器把 HTML/纯文本自动转换。
- React 展示用已有 `show-rich` 或 `RichTextView`。
- 插件需要 HTML 时使用公开 `richTextToHtml(value)`；不要复制解析器。
- 服务端模板用 `{{ richText ... }}` 或只取内部片段的 `{{ richTextInner ... }}`。
- 媒体备注保存在节点 `attrs.caption`，统一渲染为 `figure > figcaption`。

新增富文本节点或展示行为属于 runtime 变更，必须同时核对编辑器、React renderer 和 Go template renderer；普通业务 Page 不自行实现解析。

## 保存边界

submit payload 可以包含：

```txt
id
用户录入字段
真实业务选择字段
partial save 触达的 status/sort 等字段
```

默认不要包含：

```txt
created_at updated_at deleted_at
created_by updated_by author_id editor_id operator_id
服务端生成的 code/key/slug/sn/no
```

这些字段确需写入时，由同域 Service 或 Page Provider 在服务端维护业务规则。复杂业务不要继续堆到 Model hook。

## 审查顺序

检查 create/update 页时同时对照：

1. Model 字段、Options、Relations 和默认值。
2. form 节点 `value`。
3. `data.form` 默认值。
4. `action.submit.params/data`。
5. Provider/Service 写入的上下文字段。

任何字段在多个位置重复配置，都要确认是否能回到 Model 或服务端单一来源。
