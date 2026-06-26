# Front Page 入口

普通后台、配置页、列表、编辑、详情、工作台壳优先使用 `package/front` page JSON。只有 page JSON 表达不了画布、编辑器、实时工作台等强交互时，才升级到 front plugin。

## 必读分流

| 问题 | 继续读 |
| --- | --- |
| 当前 page JSON 协议、禁止旧字段、model/service 来源 | `front-page/protocol.md` |
| create/update 表单字段、系统字段、审计字段、code/key/分类边界 | `front-page/field.md` |
| submit/save/delete、partial save、before/after hook | `front-page/action.md` |
| option、meta、Relations、Options、远程选项 | `front-page/option.md` |
| 数据模板配置、填写页、GetInfo 调用契约 | `front-page/data-template.md` |
| site、auth、public、shell、plugin 自动发现、config/front | `front-page/site.md` |
| 服务端模板、SEO、公开内容站 | `front-page/template.md` |

## 基本选择

- 普通 CRUD：Model + page JSON。
- 标签、列名、表单 label：model comment。
- 枚举：model Options。
- 外键/关联选择：model Relations。
- 表单字段：只放当前页面真实录入或选择的字段。
- 保存前规范化：Provider hook 或 `action.submit.before` 调用真实 Service。
- 跨表事务、状态流转、外部调用：Service。
- 自定义 HTTP 能力：API + Service。

## 编辑器正文展示

- `form-editor` 保存的是 Dever 富文本 JSON，不是可直接拼接的 HTML。
- seed、`data.form` 默认值、数据模板 `default_value`、AI 预置内容如果目标字段是 `form-editor`，必须直接生成 Dever 富文本 JSON 字符串；不要生成 `<p>...</p>` 这类 HTML 默认值。
- 只有纯文本来源时，先组装为 `doc > paragraph > text` 的富文本 JSON；不要依赖编辑器运行时把 HTML 或纯文本自动归一化。
- React 页面展示编辑器正文用 `show-rich` 或 `RichTextView`，不要自己解析 JSON。
- front plugin 或客户端代码需要 HTML 字符串时，用 `richTextToHtml(value)`；只要内部片段时才传 `wrapper:false`。
- Go template 服务端模板展示编辑器正文时，用 `{{ richText .Data.article.content }}`；只要内部片段时才用 `{{ richTextInner .Data.article.content }}`。
- 不要在项目里复制富文本解析、媒体解析、备注解析或手写 `dangerouslySetInnerHTML` 解析逻辑。
- 图片、视频、音频备注统一存储在媒体节点 `attrs.caption`，前端必须渲染为 `figure > figcaption`；备注样式必须和编辑器/`RichTextView` 保持一致。
- 新增富文本节点、媒体节点或展示样式时，必须同步更新 `RichTextView`、`richTextToHtml` 和 Go template `richText`，保证后台预览、React 展示和 template HTML 一致。

## 最小结构

每个 page JSON 必须有六个顶层对象：

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

标准 `list/update/create/view/detail/info` 页面按 route path 自动推导 model。能推导的不写，不能推导才写对应位置的 `model` 或 `service`。

写 create/update 页前先判断字段来源。`code/key/slug`、作者、编辑、创建人、更新人、操作人、创建时间、更新时间默认不进入表单；分类、类型、分组优先用 Options/Relations/category 选择，不做自由输入。

## 直接禁止

- `_model`、`_use`
- `modelName`、`modelPath`
- `type: "service"`
- `submit.use`、`option.use`、`childUse`
- `service@...`、`transform`
- `<<NewXxxModel>>`、`{{Service}}`
- 手写 `/front/route/option` 或 `/front/route/action`

发现这些写法，改成当前协议或让 `audit.sh` 报错。

## 示例来源

优先看当前代码：

1. `backend/package/front/front/page`
2. `backend/package/bot/front/page`
3. `backend/package/crm/front/page`
4. `backend/package/source/front/page`
5. `backend/package/user/front/page`
6. 当前项目 `module/*/front/page`

不要从旧 demo 复制被当前 runtime 禁止的字段。
