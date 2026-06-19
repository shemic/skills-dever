# Front Page 入口

普通后台、配置页、列表、编辑、详情、工作台壳优先使用 `package/front` page JSON。只有 page JSON 表达不了画布、编辑器、实时工作台等强交互时，才升级到 front plugin。

## 必读分流

| 问题 | 继续读 |
| --- | --- |
| 当前 page JSON 协议、禁止旧字段、model/service 来源 | `front-page/protocol.md` |
| submit/save/delete、partial save、before/after hook | `front-page/action.md` |
| option、meta、Relations、Options、远程选项 | `front-page/option.md` |
| site、auth、public、shell、plugin 自动发现、config/front | `front-page/site.md` |
| 服务端模板、SEO、公开内容站 | `front-page/template.md` |

## 基本选择

- 普通 CRUD：Model + page JSON。
- 标签、列名、表单 label：model comment。
- 枚举：model Options。
- 外键/关联选择：model Relations。
- 保存前规范化：Provider hook 或 `action.submit.before` 调用真实 Service。
- 跨表事务、状态流转、外部调用：Service。
- 自定义 HTTP 能力：API + Service。

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
